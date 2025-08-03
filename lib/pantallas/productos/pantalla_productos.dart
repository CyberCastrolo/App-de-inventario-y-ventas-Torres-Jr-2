import 'package:flutter/material.dart';
import 'package:torresjr/pantallas/widgets/widget_busqueda_productos.dart';
import '../../servicios/firestore_service.dart';
import '../../servicios/auth_service.dart';

class PantallaProductos extends StatefulWidget {
  const PantallaProductos({super.key});

  @override
  State<PantallaProductos> createState() => _PantallaProductosState();
}

class _PantallaProductosState extends State<PantallaProductos> {
  bool isManager = false;
  List<Map<String, dynamic>> _productos = [];
  bool _cargandoProductos = true;
  bool _mostrandoBusqueda = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
    _cargarProductos();
  }

  void _verificarPermisos() async {
    bool manager = await AuthService.isManager();
    setState(() {
      isManager = manager;
    });
  }

  void _cargarProductos() async {
    setState(() {
      _cargandoProductos = true;
    });

    try {
      // Cargar productos con información de stock
      List<Map<String, dynamic>> productos = await FirestoreService.busquedaAvanzada(
        soloConStock: false,
        ordenarPor: 'name',
      );

      setState(() {
        _productos = productos;
        _cargandoProductos = false;
      });
    } catch (e) {
      setState(() {
        _cargandoProductos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onResultadosBusqueda(List<Map<String, dynamic>> resultados) {
    setState(() {
      _productos = resultados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Productos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(
              _mostrandoBusqueda ? Icons.search_off : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _mostrandoBusqueda = !_mostrandoBusqueda;
                if (!_mostrandoBusqueda) {
                  // Si ocultamos la búsqueda, recargar todos los productos
                  _cargarProductos();
                }
              });
            },
            tooltip: _mostrandoBusqueda ? 'Ocultar búsqueda' : 'Buscar productos',
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
            // Widget de búsqueda (condicional)
            if (_mostrandoBusqueda)
              Container(
                margin: const EdgeInsets.all(16.0),
                child: WidgetBusquedaProductos(
                  onResultados: _onResultadosBusqueda,
                  mostrarFiltros: true,
                  soloConStock: false,
                ),
              ),

            // Lista de productos
            Expanded(
              child: _cargandoProductos
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Cargando productos...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : _productos.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _mostrandoBusqueda
                          ? 'No se encontraron productos'
                          : 'No hay productos registrados',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isManager && !_mostrandoBusqueda)
                      const Text(
                        'Presiona + para agregar el primer producto',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    if (_mostrandoBusqueda)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _mostrandoBusqueda = false;
                          });
                          _cargarProductos();
                        },
                        icon: const Icon(Icons.clear, color: Colors.white),
                        label: const Text(
                          'Limpiar búsqueda',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _productos.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> producto = _productos[index];
                  return _buildProductoCard(producto);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/productos/nuevo');
          _cargarProductos(); // Recargar después de agregar
        },
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Producto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          : null,
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    int stockTotal = producto['stockTotal'] ?? 0;
    List<Map<String, dynamic>> stockInfo = producto['stockInfo'] ?? [];

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16.0),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: stockTotal > 0 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            producto['name'] ?? 'Producto sin nombre',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.indigo,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'S/ ${(producto['price'] ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stockTotal > 0 ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Stock: $stockTotal',
                      style: TextStyle(
                        color: stockTotal > 0 ? Colors.green[700] : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Sin IGV: S/ ${(producto['priceWithoutIgv'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  producto['categoriaNombre'] ?? 'Sin categoría',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (producto['description'] != null && (producto['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  producto['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: isManager
              ? PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.indigo),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'stock',
                child: Row(
                  children: [
                    Icon(Icons.add_box, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Agregar Stock'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'eliminar') {
                _mostrarDialogoEliminar(producto);
              } else if (value == 'editar') {
                _mostrarDialogoEditar(producto);
              } else if (value == 'stock') {
                Navigator.pushNamed(context, '/inventario/agregar');
              }
            },
          )
              : const Icon(Icons.expand_more, color: Colors.indigo),
          children: [
            // Detalles del stock por ubicación
            if (stockInfo.isNotEmpty) ...[
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
                    const Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.indigo, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Stock Detallado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...stockInfo.map((stock) => _buildStockDetalle(stock)).toList(),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Sin stock disponible',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockDetalle(Map<String, dynamic> stock) {
    String ubicacion = stock['location'] == 'STORE' ? 'Tienda' : 'Almacén';
    Color colorUbicacion = stock['location'] == 'STORE' ? Colors.green : Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorUbicacion,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$ubicacion - ${stock['size']} - ${stock['color']}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '${stock['quantity']} unidades',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorUbicacion,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminar(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar "${producto['name']}"?\n\nEsta acción no se puede deshacer.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _eliminarProducto(producto['id'], producto['name']);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarProducto(String productId, String productName) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      await FirestoreService.eliminarProducto(productId);

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto "$productName" eliminado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Refrescar la lista
      _cargarProductos();
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
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _mostrarDialogoEditar(Map<String, dynamic> producto) {
    // Por simplicidad, redirigir a la pantalla de edición
    // En una implementación completa, podrías crear una pantalla de edición
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Edición de productos próximamente...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}