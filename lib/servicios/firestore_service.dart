import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/category.dart';
import '../modelos/product.dart';
import '../modelos/stock_item.dart';
import '../modelos/sale.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //FUNCIÓN HELPER PARA VALIDAR ENTEROS

  static int _validateInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  //FUNCIÓN HELPER PARA VALIDAR DOUBLES
  static double _validateDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ============= CATEGORÍAS =============

  // Leer todas las categorías
  static Future<List<Category>> leerCategorias() async {
    List<Category> categorias = [];
    QuerySnapshot querySnapshot = await _firestore
        .collection('categories')
        .orderBy('name')
        .get();

    for (var doc in querySnapshot.docs) {
      categorias.add(Category.fromFirestore(doc));
    }
    return categorias;
  }

  // Obtener categorías principales (sin padre)
  static Future<List<Category>> leerCategoriasPrincipales() async {
    List<Category> categorias = [];
    QuerySnapshot querySnapshot = await _firestore
        .collection('categories')
        .where('parentCategory', isNull: true)
        .orderBy('name')
        .get();

    for (var doc in querySnapshot.docs) {
      categorias.add(Category.fromFirestore(doc));
    }
    return categorias;
  }

  // Obtener subcategorías de una categoría padre
  static Future<List<Category>> leerSubcategorias(
      String parentCategoryId) async {
    List<Category> subcategorias = [];
    DocumentReference parentRef = _firestore.collection('categories').doc(
        parentCategoryId);

    QuerySnapshot querySnapshot = await _firestore
        .collection('categories')
        .where('parentCategory', isEqualTo: parentRef)
        .orderBy('name')
        .get();

    for (var doc in querySnapshot.docs) {
      subcategorias.add(Category.fromFirestore(doc));
    }
    return subcategorias;
  }

  // Guardar categoría
  static Future<void> guardarCategoria(String name, String? description,
      String? parentCategoryId) async {
    Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    if (parentCategoryId != null) {
      data['parentCategory'] =
          _firestore.collection('categories').doc(parentCategoryId);
    }

    await _firestore.collection('categories').add(data);
  }

  // Editar categoría
  static Future<void> editarCategoria(String categoryId, String name,
      String? description, String? parentCategoryId) async {
    Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'updatedAt': Timestamp.now(),
    };

    if (parentCategoryId != null) {
      data['parentCategory'] =
          _firestore.collection('categories').doc(parentCategoryId);
    } else {
      data['parentCategory'] = null;
    }

    await _firestore.collection('categories').doc(categoryId).update(data);
  }

  // Eliminar categoría
  static Future<void> eliminarCategoria(String categoryId) async {
    // Verificar si hay productos usando esta categoría
    QuerySnapshot productosConCategoria = await _firestore
        .collection('products')
        .where('category',
        isEqualTo: _firestore.collection('categories').doc(categoryId))
        .get();

    if (productosConCategoria.docs.isNotEmpty) {
      throw Exception(
          'No se puede eliminar la categoría porque tiene ${productosConCategoria
              .docs.length} productos asociados');
    }

    // Verificar si hay subcategorías
    QuerySnapshot subcategorias = await _firestore
        .collection('categories')
        .where('parentCategory',
        isEqualTo: _firestore.collection('categories').doc(categoryId))
        .get();

    if (subcategorias.docs.isNotEmpty) {
      throw Exception(
          'No se puede eliminar la categoría porque tiene ${subcategorias.docs
              .length} subcategorías');
    }

    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // ============= PRODUCTOS =============

  // Leer todos los productos
  static Future<List<Product>> leerProductos() async {
    List<Product> productos = [];
    QuerySnapshot querySnapshot = await _firestore
        .collection('products')
        .orderBy('name')
        .get();

    for (var doc in querySnapshot.docs) {
      productos.add(Product.fromFirestore(doc));
    }
    return productos;
  }

  // Guardar producto
  static Future<void> guardarProducto(String name, double price,
      String categoryId, String? description) async {
    // Calcular IGV automáticamente
    Map<String, double> igvCalculos = Product.calcularIGV(price);

    await _firestore.collection('products').add({
      'name': name,
      'price': price,
      'priceWithoutIgv': igvCalculos['priceWithoutIgv'],
      'igvAmount': igvCalculos['igvAmount'],
      'category': _firestore.collection('categories').doc(categoryId),
      'description': description,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  // Editar producto
  static Future<void> editarProducto(String productId, String name,
      double price, String categoryId, String? description) async {
    Map<String, double> igvCalculos = Product.calcularIGV(price);

    await _firestore.collection('products').doc(productId).update({
      'name': name,
      'price': price,
      'priceWithoutIgv': igvCalculos['priceWithoutIgv'],
      'igvAmount': igvCalculos['igvAmount'],
      'category': _firestore.collection('categories').doc(categoryId),
      'description': description,
      'updatedAt': Timestamp.now(),
    });
  }

  // Eliminar producto
  static Future<void> eliminarProducto(String productId) async {
    // Verificar si hay stock del producto
    QuerySnapshot stockConProducto = await _firestore
        .collection('stock_items')
        .where(
        'product', isEqualTo: _firestore.collection('products').doc(productId))
        .get();

    if (stockConProducto.docs.isNotEmpty) {
      // Verificar si hay stock > 0
      bool tieneStock = false;
      for (var doc in stockConProducto.docs) {
        if ((doc.data() as Map<String, dynamic>)['quantity'] > 0) {
          tieneStock = true;
          break;
        }
      }

      if (tieneStock) {
        throw Exception(
            'No se puede eliminar el producto porque tiene stock disponible');
      }
    }

    // Eliminar todos los registros de stock (aunque sean 0)
    for (var doc in stockConProducto.docs) {
      await doc.reference.delete();
    }

    // Eliminar el producto
    await _firestore.collection('products').doc(productId).delete();
  }

  // ============= INVENTARIO =============

  // Leer stock por ubicación
  static Future<List<StockItem>> leerStock({String? location}) async {
    List<StockItem> stock = [];
    Query query = _firestore.collection('stock_items');

    if (location != null) {
      query = query.where('location', isEqualTo: location);
    }

    QuerySnapshot querySnapshot = await query.get();

    for (var doc in querySnapshot.docs) {
      stock.add(StockItem.fromFirestore(doc));
    }
    return stock;
  }

  // Agregar stock
  static Future<void> agregarStock(String productId, String location,
      String size, String color, int quantity) async {
    // Verificar si ya existe un registro con las mismas características
    QuerySnapshot existingStock = await _firestore
        .collection('stock_items')
        .where(
        'product', isEqualTo: _firestore.collection('products').doc(productId))
        .where('location', isEqualTo: location)
        .where('size', isEqualTo: size)
        .where('color', isEqualTo: color)
        .get();

    if (existingStock.docs.isNotEmpty) {
      // Si existe, actualizar la cantidad
      DocumentSnapshot existingDoc = existingStock.docs.first;
      int currentQuantity = (existingDoc.data() as Map<String,
          dynamic>)['quantity'];

      await existingDoc.reference.update({
        'quantity': currentQuantity + quantity,
        'updatedAt': Timestamp.now(),
      });
    } else {
      // Si no existe, crear nuevo registro
      await _firestore.collection('stock_items').add({
        'product': _firestore.collection('products').doc(productId),
        'location': location,
        'size': size,
        'color': color,
        'quantity': quantity,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  // Eliminar stock
  static Future<void> eliminarStock(String stockId) async {
    await _firestore.collection('stock_items').doc(stockId).delete();
  }

  // Editar stock
  static Future<void> editarStock(String stockId, int newQuantity) async {
    await _firestore.collection('stock_items').doc(stockId).update({
      'quantity': newQuantity,
      'updatedAt': Timestamp.now(),
    });
  }

  //TRANSFERIR STOCK ENTRE UBICACIONES - IMPLEMENTACIÓN REAL
  static Future<void> transferirStock(String stockId, String fromLocation,
      String toLocation, int quantity) async {
    await _firestore.runTransaction((transaction) async {
      // 1. Obtener el stock de origen
      DocumentSnapshot stockDoc = await transaction.get(
          _firestore.collection('stock_items').doc(stockId)
      );

      if (!stockDoc.exists) {
        throw Exception('El registro de stock no existe');
      }

      Map<String, dynamic> stockData = stockDoc.data() as Map<String, dynamic>;
      int currentQuantity = stockData['quantity'];

      // 2. Validar que hay suficiente stock
      if (currentQuantity < quantity) {
        throw Exception(
            'Stock insuficiente. Disponible: $currentQuantity, solicitado: $quantity');
      }

      // 3. Validar ubicaciones
      if (stockData['location'] != fromLocation) {
        throw Exception('La ubicación de origen no coincide');
      }

      // 4. Reducir stock en ubicación origen
      int newOriginQuantity = currentQuantity - quantity;
      transaction.update(stockDoc.reference, {
        'quantity': newOriginQuantity,
        'updatedAt': Timestamp.now(),
      });

      // 5. Buscar si existe stock en destino con las mismas características
      Query destQuery = _firestore
          .collection('stock_items')
          .where('product', isEqualTo: stockData['product'])
          .where('location', isEqualTo: toLocation)
          .where('size', isEqualTo: stockData['size'])
          .where('color', isEqualTo: stockData['color']);

      QuerySnapshot destSnapshot = await destQuery.get();

      if (destSnapshot.docs.isNotEmpty) {
        // 6a. Si existe en destino, sumar cantidad
        DocumentSnapshot destDoc = destSnapshot.docs.first;
        Map<String, dynamic> destData = destDoc.data() as Map<String, dynamic>;
        int destQuantity = destData['quantity'];

        transaction.update(destDoc.reference, {
          'quantity': destQuantity + quantity,
          'updatedAt': Timestamp.now(),
        });
      } else {
        // 6b. Si no existe en destino, crear nuevo registro
        DocumentReference newStockRef = _firestore
            .collection('stock_items')
            .doc();
        transaction.set(newStockRef, {
          'product': stockData['product'],
          'location': toLocation,
          'size': stockData['size'],
          'color': stockData['color'],
          'quantity': quantity,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }

      // 7. Registrar movimiento de inventario para auditoría
      DocumentReference movementRef = _firestore.collection(
          'inventory_movements').doc();
      transaction.set(movementRef, {
        'product': stockData['product'],
        'size': stockData['size'],
        'color': stockData['color'],
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'quantity': quantity,
        'type': 'TRANSFER',
        'referenceId': stockId,
        'notes': 'Transferencia entre ubicaciones',
        'createdAt': Timestamp.now(),
      });
    });
  }

  //NUEVA: Obtener stock específico por ID
  static Future<StockItem?> obtenerStockPorId(String stockId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('stock_items').doc(
          stockId).get();
      if (doc.exists) {
        return StockItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener stock: $e');
    }
  }

  //NUEVA: Validar stock antes de venta
  static Future<bool> validarStockParaVenta(String productId, String location,
      String size, String color, int quantity) async {
    try {
      QuerySnapshot stockQuery = await _firestore
          .collection('stock_items')
          .where('product',
          isEqualTo: _firestore.collection('products').doc(productId))
          .where('location', isEqualTo: location)
          .where('size', isEqualTo: size)
          .where('color', isEqualTo: color)
          .get();

      if (stockQuery.docs.isEmpty) {
        return false; // No hay stock de este producto/variante
      }

      Map<String, dynamic> stockData = stockQuery.docs.first.data() as Map<
          String,
          dynamic>;
      int availableQuantity = stockData['quantity'];

      return availableQuantity >= quantity;
    } catch (e) {
      return false;
    }
  }

  // ============= VENTAS =============

  // Leer ventas
  static Future<List<Sale>> leerVentas() async {
    List<Sale> ventas = [];
    QuerySnapshot querySnapshot = await _firestore
        .collection('sales')
        .orderBy('saleDate', descending: true)
        .get();

    for (var doc in querySnapshot.docs) {
      ventas.add(Sale.fromFirestore(doc));
    }
    return ventas;
  }

  //REGISTRAR VENTA CON VALIDACIÓN Y ACTUALIZACIÓN AUTOMÁTICA DE STOCK
  static Future<void> registrarVenta(String userId,
      List<Map<String, dynamic>> items, double total, double totalSinIgv,
      double totalIgv) async {
    await _firestore.runTransaction((transaction) async {
      // 1. Validar que hay suficiente stock para todos los items ANTES de procesar
      for (var item in items) {
        QuerySnapshot stockQuery = await _firestore
            .collection('stock_items')
            .where('product',
            isEqualTo: _firestore.collection('products').doc(item['productId']))
            .where('location', isEqualTo: 'STORE')
            .where('size', isEqualTo: item['size'])
            .where('color', isEqualTo: item['color'])
            .get();

        if (stockQuery.docs.isEmpty) {
          throw Exception(
              'No hay stock disponible para ${item['productName']} (${item['size']}, ${item['color']})');
        }

        Map<String, dynamic> stockData = stockQuery.docs.first.data() as Map<
            String,
            dynamic>;
        int availableQuantity = stockData['quantity'];
        int requestedQuantity = item['quantity'] as int;

        if (availableQuantity < requestedQuantity) {
          throw Exception(
              'Stock insuficiente para ${item['productName']} (${item['size']}, ${item['color']}). Disponible: $availableQuantity, solicitado: $requestedQuantity');
        }
      }

      // 2. Crear la venta
      DocumentReference saleRef = _firestore.collection('sales').doc();
      transaction.set(saleRef, {
        'user': _firestore.collection('users').doc(userId),
        'saleDate': Timestamp.now(),
        'totalAmount': total,
        'totalWithoutIgv': totalSinIgv,
        'totalIgv': totalIgv,
        'status': 'COMPLETED',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // 3. Procesar cada item de la venta
      for (var item in items) {
        // 3a. Agregar entrada de venta
        DocumentReference saleEntryRef = _firestore
            .collection('sale_entries')
            .doc();
        transaction.set(saleEntryRef, {
          'sale': saleRef,
          'product': _firestore.collection('products').doc(item['productId']),
          'size': item['size'],
          'color': item['color'],
          'quantity': item['quantity'] as int,
          'pricePerUnit': item['pricePerUnit'],
          'pricePerUnitWithoutIgv': item['pricePerUnitWithoutIgv'],
          'igvPerUnit': item['igvPerUnit'],
          'subtotal': item['subtotal'],
          'subtotalWithoutIgv': item['subtotalWithoutIgv'],
          'subtotalIgv': item['subtotalIgv'],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // 3b. Actualizar stock (reducir en tienda)
        QuerySnapshot stockQuery = await _firestore
            .collection('stock_items')
            .where('product',
            isEqualTo: _firestore.collection('products').doc(item['productId']))
            .where('location', isEqualTo: 'STORE')
            .where('size', isEqualTo: item['size'])
            .where('color', isEqualTo: item['color'])
            .get();

        DocumentSnapshot stockDoc = stockQuery.docs.first;
        Map<String, dynamic> stockData = stockDoc.data() as Map<String,
            dynamic>;
        int currentQuantity = stockData['quantity'];
        int newQuantity = currentQuantity - (item['quantity'] as int);

        transaction.update(stockDoc.reference, {
          'quantity': newQuantity,
          'updatedAt': Timestamp.now(),
        });

        // 3c. Registrar movimiento de inventario
        DocumentReference movementRef = _firestore.collection(
            'inventory_movements').doc();
        transaction.set(movementRef, {
          'product': _firestore.collection('products').doc(item['productId']),
          'size': item['size'],
          'color': item['color'],
          'fromLocation': 'STORE',
          'toLocation': null,
          'quantity': item['quantity'] as int,
          'type': 'SALE',
          'referenceId': saleRef.id,
          'notes': 'Venta realizada',
          'createdAt': Timestamp.now(),
        });
      }
    });
  }

  // NUEVA: Obtener detalles de una venta - CORREGIDA
  static Future<List<Map<String, dynamic>>> obtenerDetallesVenta(
      String saleId) async {
    List<Map<String, dynamic>> detalles = [];

    try {
      QuerySnapshot saleEntriesSnapshot = await _firestore
          .collection('sale_entries')
          .where('sale', isEqualTo: _firestore.collection('sales').doc(saleId))
          .get();

      for (var doc in saleEntriesSnapshot.docs) {
        Map<String, dynamic> entryData = doc.data() as Map<String, dynamic>;

        // Obtener información del producto
        DocumentSnapshot productDoc = await entryData['product'].get();

        if (productDoc.exists) {
          Map<String, dynamic> productData = productDoc.data() as Map<
              String,
              dynamic>;

          // VALIDAR Y CONVERTIR TODOS LOS VALORES NUMÉRICOS
          detalles.add({
            'id': doc.id,
            'productName': productData['name'] ?? 'Producto sin nombre',
            'size': entryData['size'] ?? 'Sin talla',
            'color': entryData['color'] ?? 'Sin color',
            'quantity': _validateInt(entryData['quantity']),
            'pricePerUnit': _validateDouble(entryData['pricePerUnit']),
            'subtotal': _validateDouble(entryData['subtotal']),
            'subtotalWithoutIgv': _validateDouble(
                entryData['subtotalWithoutIgv']),
            'subtotalIgv': _validateDouble(entryData['subtotalIgv']),
          });
        }
      }
    } catch (e) {
      print('Error al obtener detalles de venta: $e');
      // Retornar lista vacía en caso de error para evitar crash
    }

    return detalles;
  }

  // ============= REPORTES REALES =============

  //OBTENER MÉTRICAS DE VENTAS REALES
  static Future<Map<String, dynamic>> obtenerMetricasVentas() async {
    try {
      DateTime ahora = DateTime.now();
      DateTime inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
      DateTime inicioSemana = ahora.subtract(Duration(days: 7));
      DateTime inicioMes = DateTime(ahora.year, ahora.month, 1);
      DateTime inicioAno = DateTime(ahora.year, 1, 1);

      // Obtener todas las ventas completadas
      QuerySnapshot ventasSnapshot = await _firestore
          .collection('sales')
          .where('status', isEqualTo: 'COMPLETED')
          .orderBy('saleDate', descending: true)
          .get();

      List<Map<String, dynamic>> ventas = [];
      for (var doc in ventasSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime saleDate = (data['saleDate'] as Timestamp).toDate();
        ventas.add({
          'id': doc.id,
          'saleDate': saleDate,
          'totalAmount': _validateDouble(data['totalAmount']),
          'totalWithoutIgv': _validateDouble(data['totalWithoutIgv']),
          'totalIgv': _validateDouble(data['totalIgv']),
        });
      }

      // Calcular métricas por período
      double ventasHoy = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioHoy))
          .fold(0.0, (sum, venta) => sum + venta['totalAmount']);

      double ventasSemana = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioSemana))
          .fold(0.0, (sum, venta) => sum + venta['totalAmount']);

      double ventasMes = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioMes))
          .fold(0.0, (sum, venta) => sum + venta['totalAmount']);

      double ventasAno = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioAno))
          .fold(0.0, (sum, venta) => sum + venta['totalAmount']);

      // Contar transacciones
      int transaccionesHoy = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioHoy))
          .length;

      int transaccionesSemana = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioSemana))
          .length;

      int transaccionesMes = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioMes))
          .length;

      // Ticket promedio
      double ticketPromedioHoy = transaccionesHoy > 0 ? ventasHoy / transaccionesHoy : 0.0;
      double ticketPromedioSemana = transaccionesSemana > 0 ? ventasSemana / transaccionesSemana : 0.0;
      double ticketPromedioMes = transaccionesMes > 0 ? ventasMes / transaccionesMes : 0.0;

      return {
        'ventasHoy': ventasHoy,
        'ventasSemana': ventasSemana,
        'ventasMes': ventasMes,
        'ventasAno': ventasAno,
        'transaccionesHoy': transaccionesHoy,
        'transaccionesSemana': transaccionesSemana,
        'transaccionesMes': transaccionesMes,
        'transaccionesTotal': ventas.length,
        'ticketPromedioHoy': ticketPromedioHoy,
        'ticketPromedioSemana': ticketPromedioSemana,
        'ticketPromedioMes': ticketPromedioMes,
      };
    } catch (e) {
      print('Error al obtener métricas de ventas: $e');
      return {
        'ventasHoy': 0.0,
        'ventasSemana': 0.0,
        'ventasMes': 0.0,
        'ventasAno': 0.0,
        'transaccionesHoy': 0,
        'transaccionesSemana': 0,
        'transaccionesMes': 0,
        'transaccionesTotal': 0,
        'ticketPromedioHoy': 0.0,
        'ticketPromedioSemana': 0.0,
        'ticketPromedioMes': 0.0,
      };
    }
  }

  // OBTENER MÉTRICAS DE INVENTARIO REALES
  static Future<Map<String, dynamic>> obtenerMetricasInventario() async {
    try {
      // Obtener todo el stock
      QuerySnapshot stockSnapshot = await _firestore
          .collection('stock_items')
          .get();

      int stockTotalTienda = 0;
      int stockTotalAlmacen = 0;
      int productosUnicos = 0;
      int productosAgotados = 0;
      int productosStockBajo = 0;
      Map<String, int> productosCombinados = {};

      for (var doc in stockSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String location = data['location'] ?? '';
        int quantity = _validateInt(data['quantity']);
        String productId = data['product'].id;

        // Sumar por ubicación
        if (location == 'STORE') {
          stockTotalTienda += quantity;
        } else if (location == 'WAREHOUSE') {
          stockTotalAlmacen += quantity;
        }

        // Combinar productos únicos (sin importar talla/color)
        if (productosCombinados.containsKey(productId)) {
          productosCombinados[productId] = productosCombinados[productId]! + quantity;
        } else {
          productosCombinados[productId] = quantity;
          productosUnicos++;
        }

        // Contar productos agotados y con stock bajo
        if (quantity == 0) {
          productosAgotados++;
        } else if (quantity <= 5) {
          productosStockBajo++;
        }
      }

      // Obtener valor total del inventario
      double valorInventario = 0.0;
      for (String productId in productosCombinados.keys) {
        try {
          DocumentSnapshot productDoc = await _firestore
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists) {
            Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
            double price = _validateDouble(productData['price']);
            int quantity = productosCombinados[productId]!;
            valorInventario += price * quantity;
          }
        } catch (e) {
          print('Error al obtener precio del producto $productId: $e');
        }
      }

      return {
        'stockTotalTienda': stockTotalTienda,
        'stockTotalAlmacen': stockTotalAlmacen,
        'stockTotal': stockTotalTienda + stockTotalAlmacen,
        'productosUnicos': productosUnicos,
        'productosAgotados': productosAgotados,
        'productosStockBajo': productosStockBajo,
        'valorInventario': valorInventario,
        'registrosStock': stockSnapshot.docs.length,
      };
    } catch (e) {
      print('Error al obtener métricas de inventario: $e');
      return {
        'stockTotalTienda': 0,
        'stockTotalAlmacen': 0,
        'stockTotal': 0,
        'productosUnicos': 0,
        'productosAgotados': 0,
        'productosStockBajo': 0,
        'valorInventario': 0.0,
        'registrosStock': 0,
      };
    }
  }

  // OBTENER PRODUCTOS MÁS VENDIDOS (REALES)
  static Future<List<Map<String, dynamic>>> obtenerProductosMasVendidos({int limite = 10}) async {
    try {
      // Obtener todas las entradas de venta
      QuerySnapshot saleEntriesSnapshot = await _firestore
          .collection('sale_entries')
          .get();

      Map<String, Map<String, dynamic>> ventasPorProducto = {};

      for (var doc in saleEntriesSnapshot.docs) {
        Map<String, dynamic> entryData = doc.data() as Map<String, dynamic>;
        String productId = entryData['product'].id;
        int quantity = _validateInt(entryData['quantity']);
        double subtotal = _validateDouble(entryData['subtotal']);

        if (ventasPorProducto.containsKey(productId)) {
          ventasPorProducto[productId]!['cantidadVendida'] += quantity;
          ventasPorProducto[productId]!['totalVentas'] += subtotal;
          ventasPorProducto[productId]!['numeroTransacciones'] += 1;
        } else {
          ventasPorProducto[productId] = {
            'productId': productId,
            'cantidadVendida': quantity,
            'totalVentas': subtotal,
            'numeroTransacciones': 1,
          };
        }
      }

      // Obtener información de los productos y crear lista
      List<Map<String, dynamic>> productosVendidos = [];

      for (String productId in ventasPorProducto.keys) {
        try {
          DocumentSnapshot productDoc = await _firestore
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists) {
            Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
            Map<String, dynamic> ventaData = ventasPorProducto[productId]!;

            productosVendidos.add({
              'productId': productId,
              'productName': productData['name'] ?? 'Producto sin nombre',
              'precio': _validateDouble(productData['price']),
              'cantidadVendida': ventaData['cantidadVendida'],
              'totalVentas': ventaData['totalVentas'],
              'numeroTransacciones': ventaData['numeroTransacciones'],
              'promedioVentaPorTransaccion': ventaData['totalVentas'] / ventaData['numeroTransacciones'],
            });
          }
        } catch (e) {
          print('Error al obtener datos del producto $productId: $e');
        }
      }

      // Ordenar por cantidad vendida (descendente)
      productosVendidos.sort((a, b) => b['cantidadVendida'].compareTo(a['cantidadVendida']));

      // Limitar resultados
      if (productosVendidos.length > limite) {
        productosVendidos = productosVendidos.sublist(0, limite);
      }

      return productosVendidos;
    } catch (e) {
      print('Error al obtener productos más vendidos: $e');
      return [];
    }
  }

  //OBTENER PRODUCTOS CON STOCK BAJO
  static Future<List<Map<String, dynamic>>> obtenerProductosStockBajo({int limite = 5}) async {
    try {
      QuerySnapshot stockSnapshot = await _firestore
          .collection('stock_items')
          .where('quantity', isLessThanOrEqualTo: limite)
          .orderBy('quantity')
          .get();

      List<Map<String, dynamic>> productosStockBajo = [];

      for (var doc in stockSnapshot.docs) {
        Map<String, dynamic> stockData = doc.data() as Map<String, dynamic>;

        try {
          DocumentSnapshot productDoc = await stockData['product'].get();

          if (productDoc.exists) {
            Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;

            productosStockBajo.add({
              'stockId': doc.id,
              'productId': productDoc.id,
              'productName': productData['name'] ?? 'Producto sin nombre',
              'size': stockData['size'] ?? '',
              'color': stockData['color'] ?? '',
              'location': stockData['location'] ?? '',
              'quantity': _validateInt(stockData['quantity']),
              'precio': _validateDouble(productData['price']),
              'alertLevel': _validateInt(stockData['quantity']) == 0 ? 'AGOTADO' : 'STOCK_BAJO',
            });
          }
        } catch (e) {
          print('Error al obtener datos del producto: $e');
        }
      }

      return productosStockBajo;
    } catch (e) {
      print('Error al obtener productos con stock bajo: $e');
      return [];
    }
  }

  // OBTENER VENTAS POR PERÍODO
  static Future<List<Map<String, dynamic>>> obtenerVentasPorPeriodo(DateTime inicio, DateTime fin) async {
    try {
      QuerySnapshot ventasSnapshot = await _firestore
          .collection('sales')
          .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(fin))
          .where('status', isEqualTo: 'COMPLETED')
          .orderBy('saleDate', descending: true)
          .get();

      List<Map<String, dynamic>> ventas = [];

      for (var doc in ventasSnapshot.docs) {
        Map<String, dynamic> saleData = doc.data() as Map<String, dynamic>;
        DateTime saleDate = (saleData['saleDate'] as Timestamp).toDate();

        // Obtener información del usuario
        String userName = 'Usuario desconocido';
        try {
          DocumentSnapshot userDoc = await saleData['user'].get();
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            userName = userData['displayName'] ?? 'Usuario desconocido';
          }
        } catch (e) {
          print('Error al obtener usuario: $e');
        }

        ventas.add({
          'id': doc.id,
          'saleDate': saleDate,
          'totalAmount': _validateDouble(saleData['totalAmount']),
          'totalWithoutIgv': _validateDouble(saleData['totalWithoutIgv']),
          'totalIgv': _validateDouble(saleData['totalIgv']),
          'status': saleData['status'] ?? 'COMPLETED',
          'userName': userName,
        });
      }

      return ventas;
    } catch (e) {
      print('Error al obtener ventas por período: $e');
      return [];
    }
  }

  // OBTENER RESUMEN FINANCIERO POR PERÍODO
  static Future<Map<String, dynamic>> obtenerResumenFinanciero(DateTime inicio, DateTime fin) async {
    try {
      List<Map<String, dynamic>> ventas = await obtenerVentasPorPeriodo(inicio, fin);

      double totalVentas = ventas.fold(0.0, (sum, venta) => sum + venta['totalAmount']);
      double totalSinIgv = ventas.fold(0.0, (sum, venta) => sum + venta['totalWithoutIgv']);
      double totalIgv = ventas.fold(0.0, (sum, venta) => sum + venta['totalIgv']);

      int numeroTransacciones = ventas.length;
      double ticketPromedio = numeroTransacciones > 0 ? totalVentas / numeroTransacciones : 0.0;

      // Agrupar por día
      Map<String, double> ventasPorDia = {};
      for (var venta in ventas) {
        String fecha = "${venta['saleDate'].day}/${venta['saleDate'].month}";
        if (ventasPorDia.containsKey(fecha)) {
          ventasPorDia[fecha] = ventasPorDia[fecha]! + venta['totalAmount'];
        } else {
          ventasPorDia[fecha] = venta['totalAmount'];
        }
      }

      return {
        'totalVentas': totalVentas,
        'totalSinIgv': totalSinIgv,
        'totalIgv': totalIgv,
        'numeroTransacciones': numeroTransacciones,
        'ticketPromedio': ticketPromedio,
        'ventasPorDia': ventasPorDia,
        'periodoInicio': inicio,
        'periodoFin': fin,
      };
    } catch (e) {
      print('Error al obtener resumen financiero: $e');
      return {
        'totalVentas': 0.0,
        'totalSinIgv': 0.0,
        'totalIgv': 0.0,
        'numeroTransacciones': 0,
        'ticketPromedio': 0.0,
        'ventasPorDia': <String, double>{},
        'periodoInicio': inicio,
        'periodoFin': fin,
      };
    }
  }

  // ============= BÚSQUEDA DE PRODUCTOS =============

  // BÚSQUEDA GENERAL DE PRODUCTOS
  static Future<List<Product>> buscarProductos({
    String? nombre,
    String? categoriaId,
    double? precioMinimo,
    double? precioMaximo,
    bool? soloConStock,
  }) async {
    try {
      Query query = _firestore.collection('products');

      // Filtro por categoría
      if (categoriaId != null && categoriaId.isNotEmpty) {
        query = query.where('category', isEqualTo: _firestore.collection('categories').doc(categoriaId));
      }

      // Filtro por precio mínimo
      if (precioMinimo != null) {
        query = query.where('price', isGreaterThanOrEqualTo: precioMinimo);
      }

      // Filtro por precio máximo
      if (precioMaximo != null) {
        query = query.where('price', isLessThanOrEqualTo: precioMaximo);
      }

      // Ordenar por nombre para búsqueda eficiente
      query = query.orderBy('name');

      QuerySnapshot querySnapshot = await query.get();
      List<Product> productos = [];

      for (var doc in querySnapshot.docs) {
        Product producto = Product.fromFirestore(doc);

        // Filtro por nombre (local, ya que Firestore no soporta LIKE)
        if (nombre != null && nombre.isNotEmpty) {
          if (!producto.name.toLowerCase().contains(nombre.toLowerCase())) {
            continue;
          }
        }

        // Filtro por stock (si se requiere)
        if (soloConStock == true) {
          bool tieneStock = await _verificarSiTieneStock(producto.id);
          if (!tieneStock) {
            continue;
          }
        }

        productos.add(producto);
      }

      return productos;
    } catch (e) {
      print('Error en búsqueda de productos: $e');
      return [];
    }
  }

  // BÚSQUEDA RÁPIDA POR NOMBRE
  static Future<List<Product>> busquedaRapidaPorNombre(String nombre) async {
    if (nombre.isEmpty) {
      return await leerProductos();
    }

    try {
      // Obtener todos los productos y filtrar localmente
      List<Product> todosLosProductos = await leerProductos();

      return todosLosProductos.where((producto) =>
          producto.name.toLowerCase().contains(nombre.toLowerCase())
      ).toList();
    } catch (e) {
      print('Error en búsqueda rápida: $e');
      return [];
    }
  }

  // BÚSQUEDA DE PRODUCTOS CON STOCK DISPONIBLE
  static Future<List<Map<String, dynamic>>> buscarProductosConStock({
    String? nombre,
    String? ubicacion,
    String? categoriaId,
  }) async {
    try {
      // Obtener productos que coincidan con los criterios
      List<Product> productos = await buscarProductos(
        nombre: nombre,
        categoriaId: categoriaId,
        soloConStock: true,
      );

      List<Map<String, dynamic>> productosConStock = [];

      for (Product producto in productos) {
        // Obtener stock del producto
        Query stockQuery = _firestore
            .collection('stock_items')
            .where('product', isEqualTo: _firestore.collection('products').doc(producto.id))
            .where('quantity', isGreaterThan: 0);

        if (ubicacion != null && ubicacion.isNotEmpty) {
          stockQuery = stockQuery.where('location', isEqualTo: ubicacion);
        }

        QuerySnapshot stockSnapshot = await stockQuery.get();

        if (stockSnapshot.docs.isNotEmpty) {
          // Calcular stock total
          int stockTotal = 0;
          List<Map<String, dynamic>> variantes = [];

          for (var stockDoc in stockSnapshot.docs) {
            Map<String, dynamic> stockData = stockDoc.data() as Map<String, dynamic>;
            int quantity = _validateInt(stockData['quantity']);
            stockTotal += quantity;

            variantes.add({
              'stockId': stockDoc.id,
              'size': stockData['size'] ?? '',
              'color': stockData['color'] ?? '',
              'location': stockData['location'] ?? '',
              'quantity': quantity,
            });
          }

          // Obtener información de la categoría
          String categoriaNombre = 'Sin categoría';
          try {
            DocumentSnapshot categoriaDoc = await producto.category.get();
            if (categoriaDoc.exists) {
              Map<String, dynamic> categoriaData = categoriaDoc.data() as Map<String, dynamic>;
              categoriaNombre = categoriaData['name'] ?? 'Sin categoría';
            }
          } catch (e) {
            print('Error al obtener categoría: $e');
          }

          productosConStock.add({
            'id': producto.id,
            'name': producto.name,
            'price': producto.price,
            'priceWithoutIgv': producto.priceWithoutIgv,
            'igvAmount': producto.igvAmount,
            'description': producto.description,
            'categoriaNombre': categoriaNombre,
            'stockTotal': stockTotal,
            'variantes': variantes,
          });
        }
      }

      // Ordenar por nombre
      productosConStock.sort((a, b) => a['name'].compareTo(b['name']));

      return productosConStock;
    } catch (e) {
      print('Error al buscar productos con stock: $e');
      return [];
    }
  }

  // BÚSQUEDA DE STOCK POR PRODUCTO
  static Future<List<Map<String, dynamic>>> buscarStockPorProducto(String productId) async {
    try {
      QuerySnapshot stockSnapshot = await _firestore
          .collection('stock_items')
          .where('product', isEqualTo: _firestore.collection('products').doc(productId))
          .get();

      List<Map<String, dynamic>> stockItems = [];

      for (var doc in stockSnapshot.docs) {
        Map<String, dynamic> stockData = doc.data() as Map<String, dynamic>;

        stockItems.add({
          'id': doc.id,
          'size': stockData['size'] ?? '',
          'color': stockData['color'] ?? '',
          'location': stockData['location'] ?? '',
          'quantity': _validateInt(stockData['quantity']),
        });
      }

      return stockItems;
    } catch (e) {
      print('Error al buscar stock por producto: $e');
      return [];
    }
  }

  //OBTENER FILTROS DISPONIBLES
  static Future<Map<String, dynamic>> obtenerFiltrosDisponibles() async {
    try {
      // Obtener rango de precios
      QuerySnapshot productosSnapshot = await _firestore
          .collection('products')
          .orderBy('price')
          .get();

      double precioMinimo = 0.0;
      double precioMaximo = 0.0;

      if (productosSnapshot.docs.isNotEmpty) {
        precioMinimo = _validateDouble((productosSnapshot.docs.first.data() as Map<String, dynamic>)['price']);
        precioMaximo = _validateDouble((productosSnapshot.docs.last.data() as Map<String, dynamic>)['price']);
      }

      // Obtener categorías disponibles
      List<Category> categorias = await leerCategorias();

      // Obtener ubicaciones disponibles
      QuerySnapshot stockSnapshot = await _firestore
          .collection('stock_items')
          .get();

      Set<String> ubicaciones = {};
      for (var doc in stockSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String location = data['location'] ?? '';
        if (location.isNotEmpty) {
          ubicaciones.add(location);
        }
      }

      return {
        'precioMinimo': precioMinimo,
        'precioMaximo': precioMaximo,
        'categorias': categorias.map((c) => {
          'id': c.id,
          'name': c.name,
          'isMainCategory': c.isMainCategory,
        }).toList(),
        'ubicaciones': ubicaciones.toList(),
      };
    } catch (e) {
      print('Error al obtener filtros disponibles: $e');
      return {
        'precioMinimo': 0.0,
        'precioMaximo': 1000.0,
        'categorias': <Map<String, dynamic>>[],
        'ubicaciones': <String>['STORE', 'WAREHOUSE'],
      };
    }
  }

  //FUNCIÓN HELPER PARA VERIFICAR SI UN PRODUCTO TIENE STOCK
  static Future<bool> _verificarSiTieneStock(String productId) async {
    try {
      QuerySnapshot stockSnapshot = await _firestore
          .collection('stock_items')
          .where('product', isEqualTo: _firestore.collection('products').doc(productId))
          .where('quantity', isGreaterThan: 0)
          .limit(1)
          .get();

      return stockSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  //BÚSQUEDA AVANZADA CON MÚLTIPLES CRITERIOS
  static Future<List<Map<String, dynamic>>> busquedaAvanzada({
    String? texto,
    List<String>? categoriaIds,
    double? precioMin,
    double? precioMax,
    List<String>? ubicaciones,
    bool soloConStock = false,
    String ordenarPor = 'name', // name, price, stock
    bool descendente = false,
  }) async {
    try {
      // Obtener productos base
      List<Product> productos = await leerProductos();
      List<Map<String, dynamic>> resultados = [];

      for (Product producto in productos) {
        // Filtro por texto
        if (texto != null && texto.isNotEmpty) {
          if (!producto.name.toLowerCase().contains(texto.toLowerCase()) &&
              !(producto.description?.toLowerCase().contains(texto.toLowerCase()) ?? false)) {
            continue;
          }
        }

        // Filtro por categoría
        if (categoriaIds != null && categoriaIds.isNotEmpty) {
          bool categoriaCoincide = false;
          for (String categoriaId in categoriaIds) {
            if (producto.category.id == categoriaId) {
              categoriaCoincide = true;
              break;
            }
          }
          if (!categoriaCoincide) continue;
        }

        // Filtro por precio
        if (precioMin != null && producto.price < precioMin) continue;
        if (precioMax != null && producto.price > precioMax) continue;

        // Obtener información de stock
        List<Map<String, dynamic>> stockInfo = await buscarStockPorProducto(producto.id);

        // Filtrar por ubicación si se especifica
        if (ubicaciones != null && ubicaciones.isNotEmpty) {
          stockInfo = stockInfo.where((stock) =>
              ubicaciones.contains(stock['location'])
          ).toList();
        }

        // Calcular stock total
        int stockTotal = stockInfo.fold(0, (sum, stock) => sum + (stock['quantity'] as int));

        // Filtro por stock
        if (soloConStock && stockTotal == 0) continue;

        // Obtener información de categoría
        String categoriaNombre = 'Sin categoría';
        try {
          DocumentSnapshot categoriaDoc = await producto.category.get();
          if (categoriaDoc.exists) {
            Map<String, dynamic> categoriaData = categoriaDoc.data() as Map<String, dynamic>;
            categoriaNombre = categoriaData['name'] ?? 'Sin categoría';
          }
        } catch (e) {
          print('Error al obtener categoría: $e');
        }

        resultados.add({
          'id': producto.id,
          'name': producto.name,
          'price': producto.price,
          'priceWithoutIgv': producto.priceWithoutIgv,
          'igvAmount': producto.igvAmount,
          'description': producto.description,
          'categoriaNombre': categoriaNombre,
          'stockTotal': stockTotal,
          'stockInfo': stockInfo,
        });
      }

      // Ordenar resultados
      resultados.sort((a, b) {
        int comparacion = 0;

        switch (ordenarPor) {
          case 'price':
            comparacion = a['price'].compareTo(b['price']);
            break;
          case 'stock':
            comparacion = a['stockTotal'].compareTo(b['stockTotal']);
            break;
          case 'name':
          default:
            comparacion = a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase());
            break;
        }

        return descendente ? -comparacion : comparacion;
      });

      return resultados;
    } catch (e) {
      print('Error en búsqueda avanzada: $e');
      return [];
    }
  }

  // ============= FUNCIONES DE DEBUG =============

//NUEVA: Función de debug para verificar ventas
  static Future<void> debugVentas() async {
    try {
      print('🔍 DEBUG: Iniciando verificación de ventas...');

      // Obtener TODAS las ventas sin filtros
      QuerySnapshot todasLasVentas = await _firestore
          .collection('sales')
          .get();

      print('📊 Total de documentos en collection "sales": ${todasLasVentas.docs.length}');

      if (todasLasVentas.docs.isEmpty) {
        print('❌ NO HAY VENTAS EN LA BASE DE DATOS');
        print('   Verifica que las ventas se estén guardando correctamente');
        return;
      }

      // Mostrar estructura de cada venta
      for (var doc in todasLasVentas.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('\n📋 Venta ID: ${doc.id}');
        print('   - Status: ${data['status']}');
        print('   - Total: ${data['totalAmount']}');
        print('   - Fecha: ${data['saleDate']}');
        print('   - Campos disponibles: ${data.keys.toList()}');
      }

      // Verificar ventas completadas específicamente
      QuerySnapshot ventasCompletadas = await _firestore
          .collection('sales')
          .where('status', isEqualTo: 'COMPLETED')
          .get();

      print('\n Ventas con status COMPLETED: ${ventasCompletadas.docs.length}');

      // Calcular total manual
      double totalManual = 0.0;
      for (var doc in ventasCompletadas.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = _validateDouble(data['totalAmount']);
        totalManual += amount;
        print('   - Venta ${doc.id.substring(0,8)}: S/ ${amount.toStringAsFixed(2)}');
      }

      print('\n💰 TOTAL CALCULADO MANUALMENTE: S/ ${totalManual.toStringAsFixed(2)}');

    } catch (e) {
      print('❌ Error en debug de ventas: $e');
    }
  }

//FUNCIÓN CORREGIDA: Obtener métricas de ventas con debug
  static Future<Map<String, dynamic>> obtenerMetricasVentasConDebug() async {
    try {
      print('🔍 DEBUG: Calculando métricas de ventas...');

      DateTime ahora = DateTime.now();
      DateTime inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
      DateTime inicioSemana = ahora.subtract(Duration(days: 7));
      DateTime inicioMes = DateTime(ahora.year, ahora.month, 1);
      DateTime inicioAno = DateTime(ahora.year, 1, 1);

      print('📅 Fechas de consulta:');
      print('   - Hoy: $inicioHoy');
      print('   - Semana: $inicioSemana');
      print('   - Mes: $inicioMes');
      print('   - Año: $inicioAno');

      //CONSULTA SIMPLIFICADA SIN FILTRO DE FECHA PRIMERO
      QuerySnapshot todasLasVentas = await _firestore
          .collection('sales')
          .get();

      print('📊 Total ventas encontradas: ${todasLasVentas.docs.length}');

      if (todasLasVentas.docs.isEmpty) {
        print('❌ NO HAY VENTAS - Retornando métricas en 0');
        return _retornarMetricasVacias();
      }

      List<Map<String, dynamic>> ventas = [];
      double totalGeneral = 0.0;

      for (var doc in todasLasVentas.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        //VALIDAR QUE TENGA STATUS COMPLETED
        String status = data['status'] ?? '';
        if (status != 'COMPLETED') {
          print('⚠️ Venta ${doc.id} tiene status: $status (ignorada)');
          continue;
        }

        //VALIDAR FECHA
        if (data['saleDate'] == null) {
          print('⚠️ Venta ${doc.id} no tiene fecha (ignorada)');
          continue;
        }

        DateTime saleDate = (data['saleDate'] as Timestamp).toDate();
        double totalAmount = _validateDouble(data['totalAmount']);

        totalGeneral += totalAmount;

        ventas.add({
          'id': doc.id,
          'saleDate': saleDate,
          'totalAmount': totalAmount,
          'totalWithoutIgv': _validateDouble(data['totalWithoutIgv']),
          'totalIgv': _validateDouble(data['totalIgv']),
        });

        print('✅ Venta procesada: ${doc.id.substring(0,8)} - S/ ${totalAmount.toStringAsFixed(2)} - $saleDate');
      }

      print('💰 Total calculado: S/ ${totalGeneral.toStringAsFixed(2)}');
      print('📋 Ventas válidas procesadas: ${ventas.length}');

      // Calcular métricas por período
      double ventasHoy = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioHoy))
          .fold(0.0, (sum, venta) => sum + venta['totalAmount']);

      double ventasSemana = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioSemana))
          .fold(0.0, (sum, venta) => sum + venta['totalAmount']);

      double ventasMes = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioMes))
          .fold(0.0, (sum, venta) => sum + venta['totalAmount']);

      double ventasAno = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioAno))
          .fold(0.0, (sum, venta) => sum + venta['totalAmount']);

      // Contar transacciones
      int transaccionesHoy = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioHoy))
          .length;

      int transaccionesSemana = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioSemana))
          .length;

      int transaccionesMes = ventas
          .where((venta) => venta['saleDate'].isAfter(inicioMes))
          .length;

      // Ticket promedio
      double ticketPromedioHoy = transaccionesHoy > 0 ? ventasHoy / transaccionesHoy : 0.0;
      double ticketPromedioSemana = transaccionesSemana > 0 ? ventasSemana / transaccionesSemana : 0.0;
      double ticketPromedioMes = transaccionesMes > 0 ? ventasMes / transaccionesMes : 0.0;

      print('\n📈 MÉTRICAS CALCULADAS:');
      print('   - Ventas Hoy: S/ ${ventasHoy.toStringAsFixed(2)} (${transaccionesHoy} transacciones)');
      print('   - Ventas Semana: S/ ${ventasSemana.toStringAsFixed(2)} (${transaccionesSemana} transacciones)');
      print('   - Ventas Mes: S/ ${ventasMes.toStringAsFixed(2)} (${transaccionesMes} transacciones)');
      print('   - Ventas Año: S/ ${ventasAno.toStringAsFixed(2)}');

      return {
        'ventasHoy': ventasHoy,
        'ventasSemana': ventasSemana,
        'ventasMes': ventasMes,
        'ventasAno': ventasAno,
        'transaccionesHoy': transaccionesHoy,
        'transaccionesSemana': transaccionesSemana,
        'transaccionesMes': transaccionesMes,
        'transaccionesTotal': ventas.length,
        'ticketPromedioHoy': ticketPromedioHoy,
        'ticketPromedioSemana': ticketPromedioSemana,
        'ticketPromedioMes': ticketPromedioMes,
        'totalGeneral': totalGeneral, //
      };
    } catch (e) {
      print('❌ Error al obtener métricas de ventas: $e');
      return _retornarMetricasVacias();
    }
  }

//FUNCIÓN HELPER: Retornar métricas vacías
  static Map<String, dynamic> _retornarMetricasVacias() {
    return {
      'ventasHoy': 0.0,
      'ventasSemana': 0.0,
      'ventasMes': 0.0,
      'ventasAno': 0.0,
      'transaccionesHoy': 0,
      'transaccionesSemana': 0,
      'transaccionesMes': 0,
      'transaccionesTotal': 0,
      'ticketPromedioHoy': 0.0,
      'ticketPromedioSemana': 0.0,
      'ticketPromedioMes': 0.0,
      'totalGeneral': 0.0,
    };
  }


}