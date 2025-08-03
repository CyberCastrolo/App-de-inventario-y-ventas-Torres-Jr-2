import 'package:flutter/material.dart';
import 'package:torresjr/servicios/firestore_service.dart';

class WidgetBusquedaProductos extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onResultados;
  final bool mostrarFiltros;
  final bool soloConStock;
  final String? ubicacionFiltro;

  const WidgetBusquedaProductos({
    super.key,
    required this.onResultados,
    this.mostrarFiltros = true,
    this.soloConStock = false,
    this.ubicacionFiltro,
  });

  @override
  State<WidgetBusquedaProductos> createState() => _WidgetBusquedaProductosState();
}

class _WidgetBusquedaProductosState extends State<WidgetBusquedaProductos> {
  final TextEditingController _controladorBusqueda = TextEditingController();
  bool _mostrandoFiltros = false;
  bool _buscando = false;

  // Filtros
  List<String> _categoriasSeleccionadas = [];
  double _precioMinimo = 0.0;
  double _precioMaximo = 1000.0;
  String _ordenarPor = 'name';
  bool _descendente = false;

  // Datos para filtros
  List<Map<String, dynamic>> _categorias = [];
  double _precioMinimoDisponible = 0.0;
  double _precioMaximoDisponible = 1000.0;

  //NUEVA: Flag para controlar cuando los filtros están listos
  bool _filtrosCargados = false;

  @override
  void initState() {
    super.initState();
    _cargarFiltrosDisponibles();
    _controladorBusqueda.addListener(_onBusquedaCambiada);
  }

  void _cargarFiltrosDisponibles() async {
    try {
      Map<String, dynamic> filtros = await FirestoreService.obtenerFiltrosDisponibles();
      setState(() {
        _categorias = List<Map<String, dynamic>>.from(filtros['categorias']);
        _precioMinimoDisponible = filtros['precioMinimo'];
        _precioMaximoDisponible = filtros['precioMaximo'];

        //CORRECCIÓN: Asegurar que los valores iniciales estén dentro del rango
        _precioMinimo = _precioMinimoDisponible;
        _precioMaximo = _precioMaximoDisponible;

        //VALIDACIÓN ADICIONAL: Si el rango es inválido, usar valores por defecto
        if (_precioMaximoDisponible <= _precioMinimoDisponible) {
          _precioMinimoDisponible = 0.0;
          _precioMaximoDisponible = 1000.0;
          _precioMinimo = 0.0;
          _precioMaximo = 1000.0;
        }

        _filtrosCargados = true;
      });
    } catch (e) {
      print('Error al cargar filtros: $e');
      //FALLBACK: Valores seguros en caso de error
      setState(() {
        _precioMinimoDisponible = 0.0;
        _precioMaximoDisponible = 1000.0;
        _precioMinimo = 0.0;
        _precioMaximo = 1000.0;
        _filtrosCargados = true;
      });
    }
  }

  void _onBusquedaCambiada() {
    if (_controladorBusqueda.text.length > 2 || _controladorBusqueda.text.isEmpty) {
      _realizarBusqueda();
    }
  }

  void _realizarBusqueda() async {
    setState(() {
      _buscando = true;
    });

    try {
      List<Map<String, dynamic>> resultados = await FirestoreService.busquedaAvanzada(
        texto: _controladorBusqueda.text.trim(),
        categoriaIds: _categoriasSeleccionadas,
        precioMin: _precioMinimo,
        precioMax: _precioMaximo,
        ubicaciones: widget.ubicacionFiltro != null ? [widget.ubicacionFiltro!] : null,
        soloConStock: widget.soloConStock,
        ordenarPor: _ordenarPor,
        descendente: _descendente,
      );

      widget.onResultados(resultados);
    } catch (e) {
      print('Error en búsqueda: $e');
      widget.onResultados([]);
    } finally {
      setState(() {
        _buscando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controladorBusqueda,
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        prefixIcon: _buscando
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                            : const Icon(Icons.search, color: Colors.indigo),
                        suffixIcon: _controladorBusqueda.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controladorBusqueda.clear();
                            _realizarBusqueda();
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  if (widget.mostrarFiltros) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _mostrandoFiltros = !_mostrandoFiltros;
                        });
                      },
                      icon: Icon(
                        _mostrandoFiltros ? Icons.filter_list_off : Icons.filter_list,
                        color: _mostrandoFiltros ? Colors.orange : Colors.indigo,
                      ),
                      tooltip: _mostrandoFiltros ? 'Ocultar filtros' : 'Mostrar filtros',
                    ),
                  ],
                ],
              ),

              // Filtros expandibles
              if (_mostrandoFiltros && widget.mostrarFiltros) ...[
                const SizedBox(height: 16),
                _buildFiltros(),
              ],
            ],
          ),
        ),

        // Contador de resultados
        if (_controladorBusqueda.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Text(
              'Buscar: "${_controladorBusqueda.text}"',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Filtros Avanzados',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),

          // Filtro por categorías
          if (_categorias.isNotEmpty) ...[
            const Text(
              'Categorías:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _categorias.map((categoria) {
                bool seleccionada = _categoriasSeleccionadas.contains(categoria['id']);
                return FilterChip(
                  label: Text(categoria['name']),
                  selected: seleccionada,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _categoriasSeleccionadas.add(categoria['id']);
                      } else {
                        _categoriasSeleccionadas.remove(categoria['id']);
                      }
                    });
                    _realizarBusqueda();
                  },
                  selectedColor: Colors.indigo.withOpacity(0.2),
                  checkmarkColor: Colors.indigo,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          //FILTRO POR PRECIO CORREGIDO
          const Text(
            'Rango de Precio:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          //MOSTRAR SOLO SI LOS FILTROS ESTÁN CARGADOS Y EL RANGO ES VÁLIDO
          if (_filtrosCargados && _precioMaximoDisponible > _precioMinimoDisponible) ...[
            RangeSlider(
              values: RangeValues(
                _precioMinimo.clamp(_precioMinimoDisponible, _precioMaximoDisponible),
                _precioMaximo.clamp(_precioMinimoDisponible, _precioMaximoDisponible),
              ),
              min: _precioMinimoDisponible,
              max: _precioMaximoDisponible,
              divisions: 20,
              labels: RangeLabels(
                'S/ ${_precioMinimo.toStringAsFixed(0)}',
                'S/ ${_precioMaximo.toStringAsFixed(0)}',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _precioMinimo = values.start;
                  _precioMaximo = values.end;
                });
              },
              onChangeEnd: (RangeValues values) {
                _realizarBusqueda();
              },
              activeColor: Colors.indigo,
            ),
          ] else if (_filtrosCargados) ...[
            // MOSTRAR MENSAJE SI NO HAY RANGO DE PRECIOS VÁLIDO
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.grey, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Rango de precios no disponible',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ] else ...[
            //MOSTRAR LOADING MIENTRAS CARGAN LOS FILTROS
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Ordenamiento
          Row(
            children: [
              const Text(
                'Ordenar por:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _ordenarPor,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Nombre')),
                    DropdownMenuItem(value: 'price', child: Text('Precio')),
                    DropdownMenuItem(value: 'stock', child: Text('Stock')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _ordenarPor = value!;
                    });
                    _realizarBusqueda();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _descendente = !_descendente;
                  });
                  _realizarBusqueda();
                },
                icon: Icon(
                  _descendente ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.indigo,
                ),
                tooltip: _descendente ? 'Descendente' : 'Ascendente',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              TextButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _realizarBusqueda,
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _controladorBusqueda.clear();
      _categoriasSeleccionadas.clear();
      //CORRECCIÓN: Usar valores seguros al limpiar
      _precioMinimo = _precioMinimoDisponible;
      _precioMaximo = _precioMaximoDisponible;
      _ordenarPor = 'name';
      _descendente = false;
    });
    _realizarBusqueda();
  }

  @override
  void dispose() {
    _controladorBusqueda.removeListener(_onBusquedaCambiada);
    _controladorBusqueda.dispose();
    super.dispose();
  }
}