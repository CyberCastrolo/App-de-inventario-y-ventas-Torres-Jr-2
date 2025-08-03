import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../servicios/auth_service.dart';

class PantallaReportes extends StatefulWidget {
  const PantallaReportes({super.key});

  @override
  State<PantallaReportes> createState() => _PantallaReportesState();
}

class _PantallaReportesState extends State<PantallaReportes> with TickerProviderStateMixin {
  late TabController _tabController;
  bool isManager = false;
  bool _cargandoDatos = true;

  // Datos de reportes reales
  Map<String, dynamic> _metricasVentas = {};
  Map<String, dynamic> _metricasInventario = {};
  List<Map<String, dynamic>> _productosMasVendidos = [];
  List<Map<String, dynamic>> _productosStockBajo = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _verificarPermisos();
  }

  void _verificarPermisos() async {
    bool manager = await AuthService.isManager();
    if (!manager) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      isManager = manager;
    });
    _cargarDatosReales();
  }

  void _cargarDatosReales() async {
    try {
      // Cargar todos los datos en paralelo
      final futures = await Future.wait([
        FirestoreService.obtenerMetricasVentasConDebug(),
        FirestoreService.obtenerMetricasInventario(),
        FirestoreService.obtenerProductosMasVendidos(limite: 10),
        FirestoreService.obtenerProductosStockBajo(limite: 10),
      ]);

      setState(() {
        _metricasVentas = futures[0] as Map<String, dynamic>;
        _metricasInventario = futures[1] as Map<String, dynamic>;
        _productosMasVendidos = futures[2] as List<Map<String, dynamic>>;
        _productosStockBajo = futures[3] as List<Map<String, dynamic>>;
        _cargandoDatos = false;
      });
    } catch (e) {
      setState(() {
        _cargandoDatos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar reportes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isManager) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reportes Reales',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            Tab(icon: Icon(Icons.trending_up), text: 'Ventas'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventario'),
            Tab(icon: Icon(Icons.warning), text: 'Alertas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              await FirestoreService.debugVentas();
            },
            tooltip: 'Debug ventas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _cargandoDatos = true;
              });
              _cargarDatosReales();
            },
            tooltip: 'Actualizar datos',
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
        child: _cargandoDatos
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
                'Generando reportes reales...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            : TabBarView(
          controller: _tabController,
          children: [
            _buildResumenTab(),
            _buildVentasTab(),
            _buildInventarioTab(),
            _buildAlertasTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Resumen ejecutivo
          _buildResumenEjecutivo(),
          const SizedBox(height: 20),

          // Métricas rápidas
          _buildMetricasRapidas(),
          const SizedBox(height: 20),

          // Top productos
          _buildSeccionHeader('🏆 Productos Más Vendidos', Icons.star),
          const SizedBox(height: 10),
          _buildTopProductos(),
        ],
      ),
    );
  }

  Widget _buildVentasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSeccionHeader('📈 Métricas de Ventas', Icons.trending_up),
          const SizedBox(height: 10),
          _buildMetricasVentasDetalladas(),
          const SizedBox(height: 20),

          _buildSeccionHeader('💰 Resumen Financiero', Icons.attach_money),
          const SizedBox(height: 10),
          _buildResumenFinanciero(),
        ],
      ),
    );
  }

  Widget _buildInventarioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSeccionHeader('📦 Estado del Inventario', Icons.inventory),
          const SizedBox(height: 10),
          _buildMetricasInventarioDetalladas(),
          const SizedBox(height: 20),

          _buildSeccionHeader('💎 Valor del Inventario', Icons.diamond),
          const SizedBox(height: 10),
          _buildValorInventario(),
        ],
      ),
    );
  }

  Widget _buildAlertasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSeccionHeader('⚠️ Alertas de Stock', Icons.warning),
          const SizedBox(height: 10),
          _buildAlertasStock(),
          const SizedBox(height: 20),

          _buildSeccionHeader('📊 Recomendaciones', Icons.lightbulb),
          const SizedBox(height: 10),
          _buildRecomendaciones(),
        ],
      ),
    );
  }

  Widget _buildResumenEjecutivo() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
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
            const Row(
              children: [
                Icon(Icons.dashboard, color: Colors.indigo, size: 28),
                SizedBox(width: 10),
                Text(
                  'Resumen Ejecutivo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaCard(
                    'Ventas Hoy',
                    'S/ ${_metricasVentas['ventasHoy']?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.today,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricaCard(
                    'Transacciones',
                    '${_metricasVentas['transaccionesHoy'] ?? 0}',
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaCard(
                    'Stock Total',
                    '${_metricasInventario['stockTotal'] ?? 0}',
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricaCard(
                    'Stock Bajo',
                    '${_metricasInventario['productosStockBajo'] ?? 0}',
                    Icons.warning,
                    (_metricasInventario['productosStockBajo'] ?? 0) > 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasRapidas() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            const Text(
              '📊 Métricas Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilaMetrica(
              'Ticket Promedio Hoy',
              _metricasVentas['ticketPromedioHoy']?.toStringAsFixed(2) ?? '0.00',
              Icons.monetization_on,
              Colors.green,
              esMoneda: true,
            ),
            _buildFilaMetrica(
              'Productos Únicos',
              '${_metricasInventario['productosUnicos'] ?? 0}',
              Icons.category,
              Colors.blue,
            ),
            _buildFilaMetrica(
              'Valor Inventario',
              _metricasInventario['valorInventario']?.toStringAsFixed(2) ?? '0.00',
              Icons.diamond,
              Colors.purple,
              esMoneda: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductos() {
    if (_productosMasVendidos.isEmpty) {
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(20),
        ),
      );
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            const Text(
              'Productos Más Vendidos (Real)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            ..._productosMasVendidos.take(5).map((producto) =>
                _buildProductoVendido(producto)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoVendido(Map<String, dynamic> producto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto['productName'] ?? 'Producto sin nombre',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'S/ ${producto['precio']?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${producto['cantidadVendida']} vendidos',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'S/ ${producto['totalVentas']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasVentasDetalladas() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            _buildFilaMetrica(
              'Ventas de Hoy',
              _metricasVentas['ventasHoy']?.toStringAsFixed(2) ?? '0.00',
              Icons.today,
              Colors.green,
              esMoneda: true,
            ),
            const Divider(),
            _buildFilaMetrica(
              'Ventas de la Semana',
              _metricasVentas['ventasSemana']?.toStringAsFixed(2) ?? '0.00',
              Icons.date_range,
              Colors.blue,
              esMoneda: true,
            ),
            const Divider(),
            _buildFilaMetrica(
              'Ventas del Mes',
              _metricasVentas['ventasMes']?.toStringAsFixed(2) ?? '0.00',
              Icons.calendar_month,
              Colors.purple,
              esMoneda: true,
            ),
            const Divider(),
            _buildFilaMetrica(
              'Ventas del Año',
              _metricasVentas['ventasAno']?.toStringAsFixed(2) ?? '0.00',
              Icons.calendar_today,
              Colors.indigo,
              esMoneda: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenFinanciero() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            const Text(
              '💰 Análisis Financiero',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilaMetrica(
              'Ticket Promedio Hoy',
              _metricasVentas['ticketPromedioHoy']?.toStringAsFixed(2) ?? '0.00',
              Icons.receipt,
              Colors.green,
              esMoneda: true,
            ),
            _buildFilaMetrica(
              'Ticket Promedio Semanal',
              _metricasVentas['ticketPromedioSemana']?.toStringAsFixed(2) ?? '0.00',
              Icons.trending_up,
              Colors.blue,
              esMoneda: true,
            ),
            _buildFilaMetrica(
              'Ticket Promedio Mensual',
              _metricasVentas['ticketPromedioMes']?.toStringAsFixed(2) ?? '0.00',
              Icons.analytics,
              Colors.purple,
              esMoneda: true,
            ),
            const Divider(),
            _buildFilaMetrica(
              'Total Transacciones',
              '${_metricasVentas['transaccionesTotal'] ?? 0}',
              Icons.shopping_cart,
              Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasInventarioDetalladas() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            _buildFilaMetrica(
              'Stock en Tienda',
              '${_metricasInventario['stockTotalTienda'] ?? 0}',
              Icons.store,
              Colors.green,
            ),
            const Divider(),
            _buildFilaMetrica(
              'Stock en Almacén',
              '${_metricasInventario['stockTotalAlmacen'] ?? 0}',
              Icons.warehouse,
              Colors.blue,
            ),
            const Divider(),
            _buildFilaMetrica(
              'Stock Total',
              '${_metricasInventario['stockTotal'] ?? 0}',
              Icons.inventory,
              Colors.purple,
            ),
            const Divider(),
            _buildFilaMetrica(
              'Productos Únicos',
              '${_metricasInventario['productosUnicos'] ?? 0}',
              Icons.category,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValorInventario() {
    double valorInventario = _metricasInventario['valorInventario']?.toDouble() ?? 0.0;
    int stockTotal = _metricasInventario['stockTotal'] ?? 0;
    double valorPromedioPorUnidad = stockTotal > 0 ? valorInventario / stockTotal : 0.0;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            const Text(
              '💎 Valor del Inventario',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilaMetrica(
              'Valor Total',
              valorInventario.toStringAsFixed(2),
              Icons.diamond,
              Colors.purple,
              esMoneda: true,
            ),
            _buildFilaMetrica(
              'Valor Promedio por Unidad',
              valorPromedioPorUnidad.toStringAsFixed(2),
              Icons.monetization_on,
              Colors.green,
              esMoneda: true,
            ),
            _buildFilaMetrica(
              'Registros de Stock',
              '${_metricasInventario['registrosStock'] ?? 0}',
              Icons.list,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertasStock() {
    if (_productosStockBajo.isEmpty) {
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                '¡Todo en orden!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No hay productos con stock crítico',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _productosStockBajo.map((producto) => _buildAlertaStockCard(producto)).toList(),
    );
  }

  Widget _buildAlertaStockCard(Map<String, dynamic> producto) {
    bool esAgotado = producto['alertLevel'] == 'AGOTADO';
    Color color = esAgotado ? Colors.red : Colors.orange;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                esAgotado ? Icons.error : Icons.warning,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['productName'] ?? 'Producto sin nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Talla: ${producto['size']} - Color: ${producto['color']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Ubicación: ${producto['location'] == 'STORE' ? 'Tienda' : 'Almacén'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Stock: ${producto['quantity']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  esAgotado ? 'AGOTADO' : 'STOCK BAJO',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecomendaciones() {
    List<Map<String, dynamic>> recomendaciones = [];

    // Generar recomendaciones basadas en datos reales
    int productosAgotados = _metricasInventario['productosAgotados'] ?? 0;
    int productosStockBajo = _metricasInventario['productosStockBajo'] ?? 0;
    double ventasHoy = _metricasVentas['ventasHoy']?.toDouble() ?? 0.0;
    double ventasSemana = _metricasVentas['ventasSemana']?.toDouble() ?? 0.0;

    if (productosAgotados > 0) {
      recomendaciones.add({
        'titulo': 'Productos Agotados',
        'descripcion': 'Tienes $productosAgotados productos sin stock. Considera reabastecer urgentemente.',
        'icono': Icons.error,
        'color': Colors.red,
        'prioridad': 'ALTA',
      });
    }

    if (productosStockBajo > 5) {
      recomendaciones.add({
        'titulo': 'Stock Bajo Crítico',
        'descripcion': '$productosStockBajo productos tienen stock bajo. Planifica reabastecimiento.',
        'icono': Icons.warning,
        'color': Colors.orange,
        'prioridad': 'MEDIA',
      });
    }

    if (ventasHoy < 100) {
      recomendaciones.add({
        'titulo': 'Ventas Bajas Hoy',
        'descripcion': 'Las ventas de hoy están por debajo del promedio. Considera promociones.',
        'icono': Icons.trending_down,
        'color': Colors.blue,
        'prioridad': 'MEDIA',
      });
    }

    if (ventasSemana > ventasHoy * 7 * 1.5) {
      recomendaciones.add({
        'titulo': 'Buen Rendimiento',
        'descripcion': 'Las ventas están por encima del promedio. ¡Sigue así!',
        'icono': Icons.trending_up,
        'color': Colors.green,
        'prioridad': 'INFO',
      });
    }

    if (recomendaciones.isEmpty) {
      recomendaciones.add({
        'titulo': 'Todo en Orden',
        'descripcion': 'No hay recomendaciones urgentes en este momento.',
        'icono': Icons.check_circle,
        'color': Colors.green,
        'prioridad': 'INFO',
      });
    }

    return Column(
      children: recomendaciones.map((rec) => _buildRecomendacionCard(rec)).toList(),
    );
  }

  Widget _buildRecomendacionCard(Map<String, dynamic> recomendacion) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: recomendacion['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                recomendacion['icono'],
                color: recomendacion['color'],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recomendacion['titulo'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: recomendacion['color'],
                    ),
                  ),
                  Text(
                    recomendacion['descripcion'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: recomendacion['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recomendacion['prioridad'],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: recomendacion['color'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo, IconData icono) {
    return Row(
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
    );
  }

  Widget _buildFilaMetrica(String titulo, String valor, IconData icono, Color color, {bool esMoneda = false}) {
    String valorTexto = esMoneda ? 'S/ $valor' : valor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            valorTexto,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}