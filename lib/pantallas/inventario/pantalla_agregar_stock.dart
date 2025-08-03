import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../modelos/product.dart';

class PantallaAgregarStock extends StatefulWidget {
  const PantallaAgregarStock({super.key});

  @override
  State<PantallaAgregarStock> createState() => _PantallaAgregarStockState();
}

class _PantallaAgregarStockState extends State<PantallaAgregarStock> {
  final TextEditingController _txtCantidad = TextEditingController();
  final TextEditingController _txtTalla = TextEditingController();
  final TextEditingController _txtColor = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Product? _productoSeleccionado;
  List<Product> _productos = [];
  bool _cargandoProductos = true;
  String _ubicacionSeleccionada = 'STORE';

  final List<String> _ubicaciones = [
    'STORE',
    'WAREHOUSE',
  ];

  final List<String> _tallasComunes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL',
    '28', '30', '32', '34', '36', '38', '40', '42',
    'Única'
  ];

  final List<String> _coloresComunes = [
    'Blanco', 'Negro', 'Azul', 'Rojo', 'Verde', 'Amarillo',
    'Rosa', 'Morado', 'Gris', 'Beige', 'Marrón', 'Naranja'
  ];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  void _cargarProductos() async {
    try {
      List<Product> productos = await FirestoreService.leerProductos();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar Stock Inicial',
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
                          Icons.add_box,
                          size: 50,
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Agregar Stock Inicial',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Selector de producto
                        if (_cargandoProductos)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (_productos.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No hay productos registrados. Crea productos primero.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<Product>(
                            value: _productoSeleccionado,
                            decoration: InputDecoration(
                              hintText: 'Seleccionar producto',
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
                            items: _productos.map((producto) {
                              return DropdownMenuItem<Product>(
                                value: producto,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      producto.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'S/ ${producto.price.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (Product? nuevoProducto) {
                              setState(() {
                                _productoSeleccionado = nuevoProducto;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor seleccione un producto';
                              }
                              return null;
                            },
                          ),

                        const SizedBox(height: 20),

                        // Selector de ubicación
                        DropdownButtonFormField<String>(
                          value: _ubicacionSeleccionada,
                          decoration: InputDecoration(
                            hintText: 'Ubicación',
                            prefixIcon: Icon(
                              _ubicacionSeleccionada == 'STORE' ? Icons.store : Icons.warehouse,
                              color: Colors.indigo,
                            ),
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
                          items: _ubicaciones.map((ubicacion) {
                            return DropdownMenuItem<String>(
                              value: ubicacion,
                              child: Row(
                                children: [
                                  Icon(
                                    ubicacion == 'STORE' ? Icons.store : Icons.warehouse,
                                    color: ubicacion == 'STORE' ? Colors.green : Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(ubicacion == 'STORE' ? 'Tienda' : 'Almacén'),
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

                        const SizedBox(height: 15),

                        // Campo de talla
                        _buildTextField(
                          controller: _txtTalla,
                          hintText: 'Talla',
                          icon: Icons.straighten,
                          suggestionsList: _tallasComunes,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese la talla';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Campo de color
                        _buildTextField(
                          controller: _txtColor,
                          hintText: 'Color',
                          icon: Icons.palette,
                          suggestionsList: _coloresComunes,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el color';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Campo de cantidad
                        _buildTextField(
                          controller: _txtCantidad,
                          hintText: 'Cantidad inicial',
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
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _productos.isEmpty ? null : _agregarStock,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_box, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'AGREGAR STOCK',
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
    List<String>? suggestionsList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
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
        ),
        if (suggestionsList != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: suggestionsList.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  controller.text = suggestion;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _agregarStock() async {
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

        await FirestoreService.agregarStock(
          _productoSeleccionado!.id,
          _ubicacionSeleccionada,
          _txtTalla.text.trim(),
          _txtColor.text.trim(),
          cantidad,
        );

        // Cerrar indicador de carga
        Navigator.pop(context);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Stock agregado: ${_productoSeleccionado!.name} - $cantidad unidades en ${_ubicacionSeleccionada == 'STORE' ? 'tienda' : 'almacén'}'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Limpiar campos
        setState(() {
          _productoSeleccionado = null;
          _txtCantidad.clear();
          _txtTalla.clear();
          _txtColor.clear();
        });
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

  @override
  void dispose() {
    _txtCantidad.dispose();
    _txtTalla.dispose();
    _txtColor.dispose();
    super.dispose();
  }
}