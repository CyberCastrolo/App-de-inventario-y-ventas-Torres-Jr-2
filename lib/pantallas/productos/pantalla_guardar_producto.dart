import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../modelos/category.dart';
import '../../modelos/product.dart';

class PantallaGuardarProducto extends StatefulWidget {
  const PantallaGuardarProducto({super.key});

  @override
  State<PantallaGuardarProducto> createState() => _PantallaGuardarProductoState();
}

class _PantallaGuardarProductoState extends State<PantallaGuardarProducto> {
  final TextEditingController _txtNombre = TextEditingController();
  final TextEditingController _txtPrecio = TextEditingController();
  final TextEditingController _txtDescripcion = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Category? _categoriaSeleccionada;
  List<Category> _categorias = [];
  bool _cargandoCategorias = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  void _cargarCategorias() async {
    try {
      List<Category> categorias = await FirestoreService.leerCategorias();
      setState(() {
        _categorias = categorias;
        _cargandoCategorias = false;
      });
    } catch (e) {
      setState(() {
        _cargandoCategorias = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar categorías: $e'),
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
          'Registrar Nuevo Producto',
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
                          Icons.inventory,
                          size: 50,
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Información del Producto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildTextField(
                          controller: _txtNombre,
                          hintText: 'Nombre del producto',
                          icon: Icons.label,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el nombre del producto';
                            }
                            if (value.length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _txtPrecio,
                          hintText: 'Precio (con IGV incluido)',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el precio';
                            }
                            double? precio = double.tryParse(value);
                            if (precio == null || precio <= 0) {
                              return 'Ingrese un precio válido mayor a 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        // Dropdown de categorías
                        if (_cargandoCategorias)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          )
                        else
                          DropdownButtonFormField<Category>(
                            value: _categoriaSeleccionada,
                            decoration: InputDecoration(
                              hintText: 'Seleccionar categoría',
                              prefixIcon: const Icon(Icons.category, color: Colors.indigo),
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
                            items: _categorias.map((categoria) {
                              return DropdownMenuItem<Category>(
                                value: categoria,
                                child: Text(
                                  categoria.name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList(),
                            onChanged: (Category? nuevaCategoria) {
                              setState(() {
                                _categoriaSeleccionada = nuevaCategoria;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor seleccione una categoría';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _txtDescripcion,
                          hintText: 'Descripción (opcional)',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        // Mostrar cálculo de IGV en tiempo real
                        if (_txtPrecio.text.isNotEmpty) ...[
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
                                  'Desglose de Precios',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildPriceRow(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _guardarProducto,
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
                                Icon(Icons.save, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'GUARDAR PRODUCTO',
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: (value) {
        // Actualizar cálculo de IGV en tiempo real para el precio
        if (controller == _txtPrecio) {
          setState(() {});
        }
      },
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

  Widget _buildPriceRow() {
    double? precio = double.tryParse(_txtPrecio.text);
    if (precio == null || precio <= 0) {
      return const Text(
        'Ingrese un precio válido',
        style: TextStyle(color: Colors.grey),
      );
    }

    Map<String, double> calculosIGV = Product.calcularIGV(precio);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Precio con IGV:'),
            Text(
              'S/ ${precio.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Precio sin IGV:'),
            Text('S/ ${calculosIGV['priceWithoutIgv']!.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('IGV (18%):'),
            Text('S/ ${calculosIGV['igvAmount']!.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  void _guardarProducto() async {
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

        double precio = double.parse(_txtPrecio.text.trim());

        await FirestoreService.guardarProducto(
          _txtNombre.text.trim(),
          precio,
          _categoriaSeleccionada!.id,
          _txtDescripcion.text.trim().isEmpty ? null : _txtDescripcion.text.trim(),
        );

        // Cerrar indicador de carga
        Navigator.pop(context);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${_txtNombre.text.trim()}" guardado exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
    _txtNombre.dispose();
    _txtPrecio.dispose();
    _txtDescripcion.dispose();
    super.dispose();
  }
}