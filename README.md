# Torres Jr - Aplicación móvil de Gestión de Inventario

## Descripción General
Este proyecto es un sistema de gestión de inventario y ventas desarrollado con Flutter para la tienda "Torres Jr". La aplicación permite administrar productos, categorías, inventario en diferentes ubicaciones (tienda y almacén), registrar ventas y generar reportes. Utiliza Firebase para la autenticación de usuarios y como base de datos en tiempo real a través de Cloud Firestore.

## Características Principales
*   **Autenticación de Usuarios**: Sistema de inicio de sesión para empleados y administradores con roles definidos.
*   **Dashboard Interactivo**: Un panel central que ofrece acceso rápido a los módulos principales de la aplicación.
*   **Gestión de Productos**: Operaciones CRUD (Crear, Leer, Actualizar, Eliminar) para productos, con cálculo automático de IGV.
*   **Gestión de Categorías**: Administración de categorías y subcategorías para una mejor organización de los productos.
*   **Control de Inventario**:
    *   Registro de stock inicial para productos, especificando talla, color y ubicación.
    *   Visualización del stock disponible en tienda y almacén.
    *   Transferencia de stock entre la tienda y el almacén.
*   **Módulo de Ventas**:
    *   Creación de nuevas ventas seleccionando productos del stock de la tienda.
    *   Actualización automática del inventario después de cada venta.
    *   Historial de ventas con detalles de cada transacción.
*   **Reportes y Métricas**: Pantalla de reportes para administradores con métricas de ventas e inventario, productos más vendidos y alertas de stock bajo.
*   **Búsqueda Avanzada**: Funcionalidad de búsqueda de productos con filtros por categoría y rango de precios.

## Tecnología Utilizada
*   **Framework**: Flutter
*   **Lenguaje**: Dart
*   **Base de Datos**: Cloud Firestore
*   **Autenticación**: Firebase Authentication

## Estructura del Proyecto
El código fuente está organizado dentro del directorio `lib/` de la siguiente manera:
```
lib/
├── main.dart                 # Punto de entrada de la aplicación y definición de rutas.
├── firebase_options.dart     # Configuración de Firebase (generado).
├── modelos/                  # Clases de modelo de datos (Product, Category, Sale, etc.).
├── pantallas/                 # Contiene todas las pantallas y widgets de la UI.
│   ├── categorias/
│   ├── inventario/
│   ├── productos/
│   ├── reportes/
│   ├── ventas/
│   ├── widgets/
│   ├── dashboard.dart
│   └── login.dart
└── servicios/                # Lógica de negocio y comunicación con servicios externos.
    ├── auth_service.dart     # Manejo de la autenticación con Firebase.
    └── firestore_service.dart  # Operaciones CRUD con Cloud Firestore.
