import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../modelos/category.dart';

class PantallaGuardarCategoria extends StatefulWidget {
  const PantallaGuardarCategoria({super.key});

  @override
  State<PantallaGuardarCategoria> createState() => _PantallaGuardarCategoriaState();
}

class _PantallaGuardarCategoriaState extends State<PantallaGuardarCategoria> {
  final TextEditingController _txtNombre = TextEditingController();
  final TextEditingController _txtDescripcion = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Category? _categoriaPadre;
  List<Category> _categoriasPrincipales = [];
  bool _cargandoCategorias = true;
  bool _esSubcategoria = false;

  @override
  void initState() {
    super.initState();
    _cargarCategoriasPrincipales();
  }

  void _cargarCategoriasPrincipales() async {
    try {
      List<Category> categorias = await FirestoreService.leerCategoriasPrincipales();
      setState(() {
        _categoriasPrincipales = categorias;
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
          'Nueva Categoría',
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
                          Icons.category,
                          size: 50,
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Información de la Categoría',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Switch para subcategoría
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _esSubcategoria ? Icons.folder_open : Icons.folder,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _esSubcategoria ? 'Crear Subcategoría' : 'Crear Categoría Principal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _esSubcategoria,
                                onChanged: (value) {
                                  setState(() {
                                    _esSubcategoria = value;
                                    if (!value) {
                                      _categoriaPadre = null;
                                    }
                                  });
                                },
                                activeColor: Colors.indigo,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _txtNombre,
                          hintText: 'Nombre de la categoría',
                          icon: Icons.label,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el nombre de la categoría';
                            }
                            if (value.length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Dropdown de categoría padre (solo si es subcategoría)
                        if (_esSubcategoria) ...[
                          if (_cargandoCategorias)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            )
                          else if (_categoriasPrincipales.isEmpty)
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
                                      'No hay categorías principales. Crea primero una categoría principal.',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<Category>(
                              value: _categoriaPadre,
                              decoration: InputDecoration(
                                hintText: 'Seleccionar categoría padre',
                                prefixIcon: const Icon(Icons.folder, color: Colors.indigo),
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
                              items: _categoriasPrincipales.map((categoria) {
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
                                  _categoriaPadre = nuevaCategoria;
                                });
                              },
                              validator: (value) {
                                if (_esSubcategoria && value == null) {
                                  return 'Por favor seleccione una categoría padre';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 15),
                        ],

                        _buildTextField(
                          controller: _txtDescripcion,
                          hintText: 'Descripción (opcional)',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _categoriasPrincipales.isEmpty && _esSubcategoria
                                ? null
                                : _guardarCategoria,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _esSubcategoria ? Icons.folder_open : Icons.folder,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _esSubcategoria ? 'GUARDAR SUBCATEGORÍA' : 'GUARDAR CATEGORÍA',
                                  style: const TextStyle(
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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

  void _guardarCategoria() async {
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

        await FirestoreService.guardarCategoria(
          _txtNombre.text.trim(),
          _txtDescripcion.text.trim().isEmpty ? null : _txtDescripcion.text.trim(),
          _esSubcategoria ? _categoriaPadre?.id : null,
        );

        // Cerrar indicador de carga
        Navigator.pop(context);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_esSubcategoria ? "Subcategoría" : "Categoría"} "${_txtNombre.text.trim()}" guardada exitosamente'
            ),
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
    _txtDescripcion.dispose();
    super.dispose();
  }
}