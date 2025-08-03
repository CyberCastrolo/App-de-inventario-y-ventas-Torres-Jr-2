import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../modelos/stock_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaTransferirStock extends StatefulWidget {
  const PantallaTransferirStock({super.key});

  @override
  State<PantallaTransferirStock> createState() => _PantallaTransferirStockState();
}

class _PantallaTransferirStockState extends State<PantallaTransferirStock> {
  final TextEditingController _txtCantidad = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  StockItem? _stockSeleccionado;
  List<StockItem> _stockItems = [];
  bool _cargandoStock = true;
  String _direccionTransferencia = 'STORE_TO_WAREHOUSE'; // STORE_TO_WAREHOUSE, WAREHOUSE_TO_STORE

  @override
  void initState() {
    super.initState();
    _cargarStock();
  }

  void _cargarStock() async {
    try {
      List<StockItem> stock = await FirestoreService.leerStock();
      setState(() {
        _stockItems = stock.where((item) => item.quantity > 0).toList();
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

  List<StockItem> get _stockFiltrado {
    String ubicacionOrigen = _direccionTransferencia == 'STORE_TO_WAREHOUSE' ? 'STORE' : 'WAREHOUSE';
    return _stockItems.where((item) => item.location == ubicacionOrigen && item.quantity > 0).toList();
  }

  String get _ubicacionOrigen {
    return _direccionTransferencia == 'STORE_TO_WAREHOUSE' ? 'STORE' : 'WAREHOUSE';
  }

  String get _ubicacionDestino {
    return _direccionTransferencia == 'STORE_TO_WAREHOUSE' ? 'WAREHOUSE' : 'STORE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transferir Stock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(25.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          size: 50,
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Transferencia de Stock',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Selector de dirección de transferencia
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Dirección de Transferencia',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.store, color: Colors.green, size: 16),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward, size: 16),
                                          SizedBox(width: 4),
                                          Icon(Icons.warehouse, color: Colors.blue, size: 16),
                                        ],
                                      ),
                                      subtitle: const Text('Tienda → Almacén', style: TextStyle(fontSize: 12)),
                                      value: 'STORE_TO_WAREHOUSE',
                                      groupValue: _direccionTransferencia,
                                      onChanged: (value) {
                                        setState(() {
                                          _direccionTransferencia = value!;
                                          _stockSeleccionado = null;
                                          _txtCantidad.clear();
                                        });
                                      },
                                      activeColor: Colors.indigo,
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warehouse, color: Colors.blue, size: 16),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward, size: 16),
                                          SizedBox(width: 4),
                                          Icon(Icons.store, color: Colors.green, size: 16),
                                        ],
                                      ),
                                      subtitle: const Text('Almacén → Tienda', style: TextStyle(fontSize: 12)),
                                      value: 'WAREHOUSE_TO_STORE',
                                      groupValue: _direccionTransferencia,
                                      onChanged: (value) {
                                        setState(() {
                                          _direccionTransferencia = value!;
                                          _stockSeleccionado = null;
                                          _txtCantidad.clear();
                                        });
                                      },
                                      activeColor: Colors.indigo,
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Dropdown de productos disponibles
                        if (_cargandoStock)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (_stockFiltrado.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No hay stock disponible en ${_direccionTransferencia == 'STORE_TO_WAREHOUSE' ? 'la tienda' : 'el almacén'}',
                                    style: const TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<StockItem>(
                            value: _stockSeleccionado,
                            decoration: InputDecoration(
                              hintText: 'Seleccionar producto a transferir',
                              prefixIcon: const Icon(Icons.inventory, color: Colors.indigo),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.indigo, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            items: _stockFiltrado.map((stockItem) {
                              return DropdownMenuItem<StockItem>(
                                value: stockItem,
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: stockItem.product.get(),
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
                                            'Talla: ${stockItem.size} - Color: ${stockItem.color} (Stock: ${stockItem.quantity})',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      );
                                    }
                                    return const Text('Cargando...');
                                  },
                                ),
                              );
                            }).toList(),
                            onChanged: (StockItem? nuevoStock) {
                              setState(() {
                                _stockSeleccionado = nuevoStock;
                                _txtCantidad.clear();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor seleccione un producto';
                              }
                              return null;
                            },
                          ),

                        if (_stockSeleccionado != null) ...[
                          const SizedBox(height: 20),
                          // Información del producto seleccionado
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _ubicacionOrigen == 'STORE' ? Icons.store : Icons.warehouse,
                                      color: _ubicacionOrigen == 'STORE' ? Colors.green : Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Origen:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(_ubicacionOrigen == 'STORE' ? 'Tienda' : 'Almacén'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      _ubicacionDestino == 'STORE' ? Icons.store : Icons.warehouse,
                                      color: _ubicacionDestino == 'STORE' ? Colors.green : Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Destino:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(_ubicacionDestino == 'STORE' ? 'Tienda' : 'Almacén'),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Stock disponible:'),
                                    Text(
                                      '${_stockSeleccionado!.quantity} unidades',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Talla:'),
                                    Text(
                                      _stockSeleccionado!.size,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Color:'),
                                    Text(
                                      _stockSeleccionado!.color,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Campo cantidad a transferir
                          _buildTextField(
                            controller: _txtCantidad,
                            hintText: 'Cantidad a transferir',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese la cantidad';
                              }
                              int? cantidad = int.tryParse(value);
                              if (cantidad == null || cantidad <= 0) {
                                return 'Ingrese una cantidad válida mayor a 0';
                              }
                              if (cantidad > _stockSeleccionado!.quantity) {
                                return 'La cantidad no puede ser mayor al stock disponible (${_stockSeleccionado!.quantity})';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),
                          // Resumen de la transferencia
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '📋 Resumen de Transferencia',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FutureBuilder<DocumentSnapshot>(
                                  future: _stockSeleccionado!.product.get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      var productData = snapshot.data!.data() as Map<String, dynamic>;
                                      int cantidad = int.tryParse(_txtCantidad.text) ?? 0;
                                      return Column(
                                        children: [
                                          Text('Producto: ${productData['name']}'),
                                          Text('Cantidad: ${cantidad > 0 ? cantidad : "?"} unidades'),
                                          Text('De: ${_ubicacionOrigen == 'STORE' ? 'Tienda' : 'Almacén'} → ${_ubicacionDestino == 'STORE' ? 'Tienda' : 'Almacén'}'),
                                        ],
                                      );
                                    }
                                    return const Text('Cargando...');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _stockSeleccionado == null ? null : _realizarTransferencia,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _stockSeleccionado == null ? Colors.grey : Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.swap_horiz, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'REALIZAR TRANSFERENCIA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.indigo),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  void _realizarTransferencia() async {
    if (_formKey.currentState!.validate()) {
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

        int cantidad = int.parse(_txtCantidad.text.trim());

        //USAR LA FUNCIÓN REAL DE TRANSFERENCIA
        await FirestoreService.transferirStock(
          _stockSeleccionado!.id,
          _ubicacionOrigen,
          _ubicacionDestino,
          cantidad,
        );

        // Cerrar indicador de carga
        Navigator.pop(context);

        // Obtener nombre del producto para el mensaje
        DocumentSnapshot productDoc = await _stockSeleccionado!.product.get();
        Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
        String productName = productData['name'] ?? 'Producto';

        // Mostrar mensaje de éxito
        String origen = _ubicacionOrigen == 'STORE' ? 'tienda' : 'almacén';
        String destino = _ubicacionDestino == 'STORE' ? 'tienda' : 'almacén';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Transferencia exitosa: $cantidad unidades de "$productName" de $origen a $destino'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

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
            content: Text('❌ Error en transferencia: $mensaje'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _txtCantidad.dispose();
    super.dispose();
  }
}