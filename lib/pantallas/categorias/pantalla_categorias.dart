import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../servicios/auth_service.dart';
import '../../modelos/category.dart';

class PantallaCategorias extends StatefulWidget {
  const PantallaCategorias({super.key});

  @override
  State<PantallaCategorias> createState() => _PantallaCategoriasState();
}

class _PantallaCategoriasState extends State<PantallaCategorias> {
  bool isManager = false;

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
          'Gestión de Categorías',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: FutureBuilder<List<Category>>(
          future: FirestoreService.leerCategorias(),
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
                      'Cargando categorías...',
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
                      Icons.category_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No hay categorías registradas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isManager)
                      const Text(
                        'Presiona + para agregar la primera categoría',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              );
            }

            List<Category> categorias = snapshot.data!;

            // Separar categorías principales y subcategorías
            List<Category> categoriasPrincipales = categorias.where((c) => c.isMainCategory).toList();
            List<Category> subcategorias = categorias.where((c) => c.isSubcategory).toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Categorías principales
                _buildSeccionHeader('Categorías Principales', Icons.folder),
                ...categoriasPrincipales.map((categoria) =>
                    _buildCategoriaCard(categoria, true)).toList(),

                if (subcategorias.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSeccionHeader('Subcategorías', Icons.folder_open),
                  ...subcategorias.map((categoria) =>
                      _buildCategoriaCard(categoria, false)).toList(),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/categorias/nueva');
          setState(() {});
        },
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Categoría',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          : null,
    );
  }

  Widget _buildSeccionHeader(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icono, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(Category categoria, bool esPrincipal) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
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
              color: esPrincipal ? Colors.indigo : Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              esPrincipal ? Icons.folder : Icons.folder_open,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            categoria.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: esPrincipal ? Colors.indigo : Colors.orange[800],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (categoria.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  categoria.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              if (!esPrincipal) ...[
                const SizedBox(height: 8),
                FutureBuilder(
                  future: categoria.parentCategory?.get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var parentData = snapshot.data!.data() as Map<String, dynamic>;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Padre: ${parentData['name']}',
                          style: TextStyle(
                            color: Colors.indigo[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
          trailing: isManager
              ? PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: esPrincipal ? Colors.indigo : Colors.orange[800],
            ),
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
                _mostrarDialogoEliminar(categoria);
              } else if (value == 'editar') {
                _mostrarDialogoEditar(categoria);
              }
            },
          )
              : null,
        ),
      ),
    );
  }

  void _mostrarDialogoEliminar(Category categoria) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar "${categoria.name}"?\n\nEsta acción no se puede deshacer.'),
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
                await _eliminarCategoria(categoria.id, categoria.name);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarCategoria(String categoryId, String categoryName) async {
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

      await FirestoreService.eliminarCategoria(categoryId);

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Categoría "$categoryName" eliminada exitosamente'),
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

  void _mostrarDialogoEditar(Category categoria) async {
    final TextEditingController _txtNombre = TextEditingController(text: categoria.name);
    final TextEditingController _txtDescripcion = TextEditingController(text: categoria.description ?? '');
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    // Cargar categorías principales para seleccionar padre
    List<Category> categoriasPrincipales = await FirestoreService.leerCategoriasPrincipales();
    Category? categoriaPadre;
    bool esSubcategoria = categoria.isSubcategory;

    // Si es subcategoría, obtener el padre actual
    if (categoria.parentCategory != null) {
      var parentDoc = await categoria.parentCategory!.get();
      if (parentDoc.exists) {
        categoriaPadre = categoriasPrincipales.firstWhere(
              (cat) => cat.id == parentDoc.id,
          orElse: () => categoriasPrincipales.first,
        );
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Editar "${categoria.name}"'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                              esSubcategoria ? Icons.folder_open : Icons.folder,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                esSubcategoria ? 'Es Subcategoría' : 'Es Categoría Principal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                            Switch(
                              value: esSubcategoria,
                              onChanged: (value) {
                                setDialogState(() {
                                  esSubcategoria = value;
                                  if (!value) {
                                    categoriaPadre = null;
                                  }
                                });
                              },
                              activeColor: Colors.indigo,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _txtNombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la categoría',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (esSubcategoria) ...[
                        if (categoriasPrincipales.isEmpty)
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
                                    'No hay categorías principales disponibles',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<Category>(
                            value: categoriaPadre,
                            decoration: const InputDecoration(
                              labelText: 'Categoría Padre',
                              border: OutlineInputBorder(),
                            ),
                            items: categoriasPrincipales
                                .where((cat) => cat.id != categoria.id) // No puede ser padre de sí misma
                                .map((cat) {
                              return DropdownMenuItem<Category>(
                                value: cat,
                                child: Text(cat.name),
                              );
                            }).toList(),
                            onChanged: (Category? nuevaCategoria) {
                              setDialogState(() {
                                categoriaPadre = nuevaCategoria;
                              });
                            },
                            validator: (value) {
                              if (esSubcategoria && value == null) {
                                return 'Seleccione una categoría padre';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _txtDescripcion,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
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

                      await _editarCategoria(
                        categoria.id,
                        _txtNombre.text.trim(),
                        _txtDescripcion.text.trim().isEmpty ? null : _txtDescripcion.text.trim(),
                        esSubcategoria ? categoriaPadre?.id : null,
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editarCategoria(String categoryId, String name, String? description, String? parentCategoryId) async {
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

      await FirestoreService.editarCategoria(categoryId, name, description, parentCategoryId);

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Categoría "$name" editada exitosamente'),
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