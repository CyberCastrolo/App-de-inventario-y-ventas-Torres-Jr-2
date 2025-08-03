import 'package:flutter/material.dart';
import '../../servicios/firestore_service.dart';
import '../../servicios/auth_service.dart';
import '../../modelos/sale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PantallaVentas extends StatefulWidget {
  const PantallaVentas({super.key});

  @override
  State<PantallaVentas> createState() => _PantallaVentasState();
}

class _PantallaVentasState extends State<PantallaVentas> {
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
          'Gestión de Ventas',
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
                  value: 'reportes',
                  child: Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Ver Reportes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'exportar',
                  child: Row(
                    children: [
                      Icon(Icons.file_download, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Exportar Ventas'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'reportes') {
                  Navigator.pushNamed(context, '/reportes');
                } else if (value == 'exportar') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exportación próximamente...'),
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
        child: FutureBuilder<List<Sale>>(
          future: FirestoreService.leerVentas(),
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
                      'Cargando ventas...',
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.point_of_sale_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No hay ventas registradas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Presiona + para registrar la primera venta',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            List<Sale> ventas = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: ventas.length,
              itemBuilder: (context, index) {
                Sale venta = ventas[index];
                return _buildVentaCard(venta);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/ventas/nueva');
          setState(() {});
        },
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text(
          'Nueva Venta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildVentaCard(Sale venta) {
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
              color: _getStatusColor(venta.status),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(venta.status),
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta #${venta.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(venta.saleDate),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/ ${venta.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'IGV: S/ ${venta.totalIgv.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
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
                      color: _getStatusColor(venta.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getStatusText(venta.status),
                      style: TextStyle(
                        color: _getStatusColor(venta.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  FutureBuilder<DocumentSnapshot>(
                    future: venta.user.get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasData) {
                        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        return Text(
                          userData['displayName'] ?? 'Usuario',
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                      return const Text('Cargando...', style: TextStyle(fontSize: 12));
                    },
                  ),
                ],
              ),
            ],
          ),
          trailing: isManager
              ? PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.indigo),
            itemBuilder: (context) => [
              if (venta.isCompleted) ...[
                const PopupMenuItem(
                  value: 'devolucion',
                  child: Row(
                    children: [
                      Icon(Icons.undo, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Devolución'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cambio',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Cambio'),
                    ],
                  ),
                ),
              ],
            ],
            onSelected: (value) {
              if (value == 'devolucion' || value == 'cambio') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${value == 'devolucion' ? 'Devolución' : 'Cambio'} próximamente...'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          )
              : const Icon(Icons.expand_more, color: Colors.indigo),
          children: [
            // ✅ DETALLES COMPLETOS DE LA VENTA
            FutureBuilder<List<Map<String, dynamic>>>(
              future: FirestoreService.obtenerDetallesVenta(venta.id),
              builder: (context, detallesSnapshot) {
                if (detallesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (detallesSnapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error al cargar detalles: ${detallesSnapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!detallesSnapshot.hasData || detallesSnapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No se encontraron detalles de productos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                List<Map<String, dynamic>> detalles = detallesSnapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            'Productos Vendidos (${detalles.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Lista de productos vendidos
                    ...detalles.map((detalle) => _buildDetalleProducto(detalle)).toList(),
                    const SizedBox(height: 16),
                    // Resumen financiero
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
                              const Icon(Icons.calculate, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'Resumen Financiero',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildResumenRow('Subtotal:', 'S/ ${venta.totalWithoutIgv.toStringAsFixed(2)}'),
                          _buildResumenRow('IGV (18%):', 'S/ ${venta.totalIgv.toStringAsFixed(2)}'),
                          const Divider(),
                          _buildResumenRow(
                            'TOTAL:',
                            'S/ ${venta.totalAmount.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleProducto(Map<String, dynamic> detalle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Icono del producto
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.indigo[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.inventory, color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 12),
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle['productName'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text('${detalle['size']}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    const Icon(Icons.palette, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text('${detalle['color']}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cantidad: ${detalle['quantity']} x S/ ${detalle['pricePerUnit'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Precio
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${detalle['subtotal'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
              Text(
                'IGV: S/ ${detalle['subtotalIgv'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'RETURNED':
        return Colors.red;
      case 'PARTIAL_RETURNED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'RETURNED':
        return Icons.undo;
      case 'PARTIAL_RETURNED':
        return Icons.remove_circle_outline;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'Completada';
      case 'RETURNED':
        return 'Devuelta';
      case 'PARTIAL_RETURNED':
        return 'Devolución Parcial';
      default:
        return 'Desconocido';
    }
  }
}