import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pantallas/login.dart';
import 'pantallas/dashboard.dart';
import 'pantallas/productos/pantalla_productos.dart';
import 'pantallas/productos/pantalla_guardar_producto.dart';
import 'pantallas/categorias/pantalla_categorias.dart';
import 'pantallas/categorias/pantalla_guardar_categoria.dart';
import 'pantallas/inventario/pantalla_inventario.dart';
import 'pantallas/inventario/pantalla_transferir_stock.dart';
import 'pantallas/inventario/pantalla_agregar_stock.dart';
import 'pantallas/ventas/pantalla_ventas.dart';
import 'pantallas/ventas/pantalla_nueva_venta.dart';
import 'pantallas/reportes/pantalla_reportes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TorresJrApp());
}

class TorresJrApp extends StatelessWidget {
  const TorresJrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Torres Jr - Inventario',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/productos': (context) => const PantallaProductos(),
        '/productos/nuevo': (context) => const PantallaGuardarProducto(),
        '/categorias': (context) => const PantallaCategorias(),
        '/categorias/nueva': (context) => const PantallaGuardarCategoria(),
        '/inventario': (context) => const PantallaInventario(),
        '/inventario/transferir': (context) => const PantallaTransferirStock(),
        '/inventario/agregar': (context) => const PantallaAgregarStock(), // NUEVA RUTA
        '/ventas': (context) => const PantallaVentas(),
        '/ventas/nueva': (context) => const PantallaNuevaVenta(),
        '/reportes': (context) => const PantallaReportes(),
      },
    );
  }
}