import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../servicios/auth_service.dart';
import '../../modelos/stock_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaInventario extends StatefulWidget {
  const PantallaInventario({super.key});

  @override
  State<PantallaInventario> createState() => _PantallaInventarioState();
}

class _PantallaInventarioState extends State<PantallaInventario> {
  bool isManager = false;
  String _ubicacionSeleccionada = 'TODAS';
  final List<String> _ubicaciones = ['TODAS', 'STORE', 'WAREHOUSE'];

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
  }

  void _verificarPermisos() async {
    bool manager = await AuthService.isManager();
    setState(() {
      isManager = manager;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Inventario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
          if (isManager)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'agregar',
                  child: Row(
                    children: [
                      Icon(Icons.add_box, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Agregar Stock'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'transferir',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Transferir Stock'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'ajustar',
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Ajustar Inventario'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'agregar') {
                  await Navigator.pushNamed(context, '/inventario/agregar');
                  setState(() {}); // Refrescar la pantalla
                } else if (value == 'transferir') {
                  await Navigator.pushNamed(context, '/inventario/transferir');
                  setState(() {}); // Refrescar la pantalla
                } else if (value == 'ajustar') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ajuste de inventario próximamente...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
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
            // Filtro de ubicación
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: _ubicacionSeleccionada,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                items: _ubicaciones.map((ubicacion) {
                  return DropdownMenuItem<String>(
                    value: ubicacion,
                    child: Row(
                      children: [
                        Icon(
                          ubicacion == 'TODAS'
                              ? Icons.inventory
                              : ubicacion == 'STORE'
                              ? Icons.store
                              : Icons.warehouse,
                          color: Colors.indigo,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          ubicacion == 'TODAS'
                              ? 'Todas las ubicaciones'
                              : ubicacion == 'STORE'
                              ? 'Tienda'
                              : 'Almacén',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? nuevaUbicacion) {
                  setState(() {
                    _ubicacionSeleccionada = nuevaUbicacion!;
                  });
                },
              ),
            ),

            // Lista de inventario
            Expanded(
              child: FutureBuilder<List<StockItem>>(
                future: FirestoreService.leerStock(
                  location: _ubicacionSeleccionada == 'TODAS' ? null : _ubicacionSeleccionada,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Cargando inventario...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
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
                            _ubicacionSeleccionada == 'TODAS'
                                ? 'No hay stock registrado'
                                : 'No hay stock en ${_ubicacionSeleccionada == 'STORE' ? 'la tienda' : 'el almacén'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          if (isManager)
                            const Text(
                              'Presiona + para agregar el primer stock',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  List<StockItem> stockItems = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: stockItems.length,
                    itemBuilder: (context, index) {
                      StockItem stockItem = stockItems[index];
                      return _buildStockCard(stockItem);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/inventario/agregar');
          setState(() {}); // Refrescar la pantalla después de agregar
        },
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar Stock',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          : null,
    );
  }

  Widget _buildStockCard(StockItem stockItem) {
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
        child: ListTile(
          contentPadding: const EdgeInsets.all(16.0),
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: stockItem.isInStore ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              stockItem.isInStore ? Icons.store : Icons.warehouse,
              color: Colors.white,
              size: 30,
            ),
          ),
          title: FutureBuilder<DocumentSnapshot>(
            future: stockItem.product.get(),
            builder: (context, productSnapshot) {
              if (productSnapshot.hasData) {
                var productData = productSnapshot.data!.data() as Map<String, dynamic>;
                return Text(
                  productData['name'] ?? 'Producto sin nombre',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo,
                  ),
                );
              }
              return const Text('Cargando...');
            },
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stockItem.isInStore ? Colors.green[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      stockItem.isInStore ? 'Tienda' : 'Almacén',
                      style: TextStyle(
                        color: stockItem.isInStore ? Colors.green[700] : Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stockItem.quantity > 0 ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Stock: ${stockItem.quantity}',
                      style: TextStyle(
                        color: stockItem.quantity > 0 ? Colors.green[700] : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Talla: ${stockItem.size}'),
                  const SizedBox(width: 15),
                  const Icon(Icons.palette, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Color: ${stockItem.color}'),
                ],
              ),
              const SizedBox(height: 8),
              // Mostrar precio del producto
              FutureBuilder<DocumentSnapshot>(
                future: stockItem.product.get(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.hasData) {
                    var productData = productSnapshot.data!.data() as Map<String, dynamic>;
                    double precio = (productData['price'] ?? 0.0).toDouble();
                    return Text(
                      'Precio: S/ ${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          trailing: isManager
              ? PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.indigo),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Editar Cantidad'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'transferir',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Transferir'),
                  ],
                ),
              ),
              const PopupMenuItem(
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
                _mostrarDialogoEliminar(stockItem);
              } else if (value == 'editar') {
                _mostrarDialogoEditar(stockItem);
              } else if (value == 'transferir') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transferencia próximamente...'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          )
              : null,
        ),
      ),
    );
  }

  void _mostrarDialogoEliminar(StockItem stockItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este registro de stock?\n\nEsta acción no se puede deshacer.'),
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
                await _eliminarStock(stockItem);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarStock(StockItem stockItem) async {
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

      await FirestoreService.eliminarStock(stockItem.id);

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock eliminado exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refrescar la lista
      setState(() {});
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

  void _mostrarDialogoEditar(StockItem stockItem) {
    final TextEditingController _txtCantidad = TextEditingController(text: stockItem.quantity.toString());
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Cantidad de Stock'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: stockItem.product.get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var productData = snapshot.data!.data() as Map<String, dynamic>;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productData['name'] ?? 'Sin nombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Talla: ${stockItem.size} - Color: ${stockItem.color}'),
                            Text('Ubicación: ${stockItem.isInStore ? 'Tienda' : 'Almacén'}'),
                            Text('Stock actual: ${stockItem.quantity}'),
                          ],
                        ),
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _txtCantidad,
                  decoration: const InputDecoration(
                    labelText: 'Nueva cantidad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la cantidad';
                    }
                    int? cantidad = int.tryParse(value);
                    if (cantidad == null || cantidad < 0) {
                      return 'Ingrese una cantidad válida (0 o mayor)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  await _editarStock(stockItem.id, int.parse(_txtCantidad.text.trim()));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarStock(String stockId, int nuevaCantidad) async {
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

      await FirestoreService.editarStock(stockId, nuevaCantidad);

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock actualizado a $nuevaCantidad unidades'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Refrescar la lista
      setState(() {});
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
}