import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../servicios/auth_service.dart';
import '../../modelos/stock_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaNuevaVenta extends StatefulWidget {
  const PantallaNuevaVenta({super.key});

  @override
  State<PantallaNuevaVenta> createState() => _PantallaNuevaVentaState();
}

class _PantallaNuevaVentaState extends State<PantallaNuevaVenta> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<StockItem> _stockDisponible = [];
  List<Map<String, dynamic>> _itemsVenta = [];
  bool _cargandoStock = true;
  double _totalVenta = 0.0;
  double _totalSinIGV = 0.0;
  double _totalIGV = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarStockDisponible();
  }

  void _cargarStockDisponible() async {
    try {
      List<StockItem> stock = await FirestoreService.leerStock(location: 'STORE');
      setState(() {
        _stockDisponible = stock.where((item) => item.quantity > 0).toList();
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() {
        _cargandoStock = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar stock: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nueva Venta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_itemsVenta.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _limpiarVenta,
              tooltip: 'Limpiar venta',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: Column(
          children: [
            // Botón agregar producto
            Container(
              margin: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _cargandoStock ? null : _mostrarDialogoAgregarProducto,
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text(
                  'Agregar Producto',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Lista de productos en la venta
            Expanded(
              child: _itemsVenta.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No hay productos en la venta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Presiona "Agregar Producto" para comenzar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _itemsVenta.length,
                itemBuilder: (context, index) {
                  return _buildItemVentaCard(_itemsVenta[index], index);
                },
              ),
            ),

            // Resumen de venta
            if (_itemsVenta.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text(
                              'Resumen de Venta',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildResumenRow('Productos:', '${_itemsVenta.length}'),
                        _buildResumenRow('Subtotal:', 'S/ ${_totalSinIGV.toStringAsFixed(2)}'),
                        _buildResumenRow('IGV (18%):', 'S/ ${_totalIGV.toStringAsFixed(2)}'),
                        const Divider(thickness: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            Text(
                              'S/ ${_totalVenta.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _procesarVenta,
                            icon: const Icon(Icons.payment, size: 24),
                            label: const Text(
                              'PROCESAR VENTA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildItemVentaCard(Map<String, dynamic> item, int index) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12.0),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory, color: Colors.green),
          ),
          title: Text(
            item['productName'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${item['size']}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.palette, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${item['color']}'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Cantidad: ${item['quantity']} x S/ ${item['pricePerUnit'].toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/ ${item['subtotal'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'IGV: S/ ${item['subtotalIgv'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _eliminarItem(index),
                tooltip: 'Eliminar producto',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoAgregarProducto() {
    if (_stockDisponible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos disponibles en tienda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        StockItem? stockSeleccionado;
        int cantidad = 1;
        final TextEditingController cantidadController = TextEditingController(text: '1');

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Agregar Producto'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<StockItem>(
                      value: stockSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar producto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      items: _stockDisponible.map((stock) {
                        return DropdownMenuItem<StockItem>(
                          value: stock,
                          child: FutureBuilder<DocumentSnapshot>(
                            future: stock.product.get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                var productData = snapshot.data!.data() as Map<String, dynamic>;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      productData['name'] ?? 'Sin nombre',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Talla: ${stock.size} - Color: ${stock.color}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Stock: ${stock.quantity} | Precio: S/ ${(productData['price'] ?? 0.0).toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                );
                              }
                              return const Text('Cargando...');
                            },
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          stockSeleccionado = value;
                          cantidad = 1;
                          cantidadController.text = '1';
                        });
                      },
                    ),
                    if (stockSeleccionado != null) ...[
                      const SizedBox(height: 16),
                      // Información del producto seleccionado
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📦 Producto Seleccionado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Stock disponible:'),
                                Text(
                                  '${stockSeleccionado!.quantity} unidades',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: stockSeleccionado!.quantity > 5 ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cantidadController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          cantidad = int.tryParse(value) ?? 1;
                        },
                      ),
                      if (cantidad > stockSeleccionado!.quantity)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Stock insuficiente. Disponible: ${stockSeleccionado!.quantity}',
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Agregar'),
                  onPressed: stockSeleccionado == null || cantidad <= 0 || cantidad > stockSeleccionado!.quantity
                      ? null
                      : () {
                    _agregarProductoAVenta(stockSeleccionado!, cantidad);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _agregarProductoAVenta(StockItem stock, int cantidad) async {
    try {
      //VALIDACIÓN DE STOCK ANTES DE AGREGAR
      bool stockDisponible = await FirestoreService.validarStockParaVenta(
        stock.product.id,
        'STORE',
        stock.size,
        stock.color,
        cantidad,
      );

      if (!stockDisponible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Stock insuficiente. Verifique disponibilidad'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Verificar si ya existe este producto en la venta
      int existingIndex = _itemsVenta.indexWhere((item) =>
      item['stockId'] == stock.id &&
          item['productId'] == stock.product.id &&
          item['size'] == stock.size &&
          item['color'] == stock.color);

      if (existingIndex != -1) {
        // Si ya existe, actualizar cantidad
        int nuevaCantidad = _itemsVenta[existingIndex]['quantity'] + cantidad;

        // Validar nueva cantidad total
        if (nuevaCantidad > stock.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ No se puede agregar. Total solicitado ($nuevaCantidad) supera el stock disponible (${stock.quantity})'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Actualizar item existente
        DocumentSnapshot productSnapshot = await stock.product.get();
        Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;

        double precio = (productData['price'] ?? 0.0).toDouble();
        double priceWithoutIgv = (productData['priceWithoutIgv'] ?? 0.0).toDouble();
        double igvAmount = (productData['igvAmount'] ?? 0.0).toDouble();

        setState(() {
          _itemsVenta[existingIndex]['quantity'] = nuevaCantidad;
          _itemsVenta[existingIndex]['subtotal'] = precio * nuevaCantidad;
          _itemsVenta[existingIndex]['subtotalWithoutIgv'] = priceWithoutIgv * nuevaCantidad;
          _itemsVenta[existingIndex]['subtotalIgv'] = igvAmount * nuevaCantidad;
          _calcularTotales();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cantidad actualizada: $nuevaCantidad unidades'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Si no existe, agregar nuevo item
        DocumentSnapshot productSnapshot = await stock.product.get();
        Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;

        double precio = (productData['price'] ?? 0.0).toDouble();
        double priceWithoutIgv = (productData['priceWithoutIgv'] ?? 0.0).toDouble();
        double igvAmount = (productData['igvAmount'] ?? 0.0).toDouble();

        Map<String, dynamic> item = {
          'stockId': stock.id,
          'productId': productSnapshot.id,
          'productName': productData['name'] ?? 'Sin nombre',
          'size': stock.size,
          'color': stock.color,
          'quantity': cantidad,
          'pricePerUnit': precio,
          'pricePerUnitWithoutIgv': priceWithoutIgv,
          'igvPerUnit': igvAmount,
          'subtotal': precio * cantidad,
          'subtotalWithoutIgv': priceWithoutIgv * cantidad,
          'subtotalIgv': igvAmount * cantidad,
        };

        setState(() {
          _itemsVenta.add(item);
          _calcularTotales();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Producto agregado: ${productData['name']} ($cantidad unidades)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al agregar producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _eliminarItem(int index) {
    setState(() {
      String productName = _itemsVenta[index]['productName'];
      _itemsVenta.removeAt(index);
      _calcularTotales();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Producto eliminado: $productName'),
          backgroundColor: Colors.orange,
        ),
      );
    });
  }

  void _limpiarVenta() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar Venta'),
          content: const Text('¿Estás seguro de que deseas eliminar todos los productos de la venta?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _itemsVenta.clear();
                  _calcularTotales();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🧹 Venta limpiada'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _calcularTotales() {
    _totalVenta = 0.0;
    _totalSinIGV = 0.0;
    _totalIGV = 0.0;

    for (var item in _itemsVenta) {
      _totalVenta += item['subtotal'];
      _totalSinIGV += item['subtotalWithoutIgv'];
      _totalIGV += item['subtotalIgv'];
    }
  }

  void _procesarVenta() async {
    if (_itemsVenta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Agregue al menos un producto a la venta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación con resumen
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment, color: Colors.green),
              SizedBox(width: 8),
              Text('Confirmar Venta'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Productos: ${_itemsVenta.length}'),
              Text('Total: S/ ${_totalVenta.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              const Text(
                '¿Procesar esta venta?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta acción actualizará automáticamente el inventario.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Procesar Venta', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  'Procesando venta...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
      );

      // Obtener usuario actual
      String? userId = AuthService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      //REGISTRAR LA VENTA CON VALIDACIÓN Y ACTUALIZACIÓN AUTOMÁTICA
      await FirestoreService.registrarVenta(
        userId,
        _itemsVenta,
        _totalVenta,
        _totalSinIGV,
        _totalIGV,
      );

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito detallado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅ Venta procesada exitosamente', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Total: S/ ${_totalVenta.toStringAsFixed(2)}'),
              Text('Productos: ${_itemsVenta.length}'),
              const Text('Inventario actualizado automáticamente', style: TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      // Limpiar venta y regresar
      setState(() {
        _itemsVenta.clear();
        _calcularTotales();
      });

      // Regresar a la pantalla anterior
      Navigator.pop(context);
    } catch (e) {
      // Cerrar indicador de carga si hay error
      Navigator.pop(context);

      // Mostrar mensaje de error específico
      String mensaje = e.toString();
      if (mensaje.contains('Exception:')) {
        mensaje = mensaje.replaceAll('Exception:', '').trim();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❌ Error al procesar venta', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(mensaje),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}