import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/user.dart';

class AuthService {
  static final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  static auth.User? get currentUser => _auth.currentUser;

  // Stream del estado de autenticación
  static Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar sesión
  static Future<User> signIn(String email, String password) async {
    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtener datos del usuario desde Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en la base de datos');
      }

      return User.fromFirestore(userDoc);
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener datos del usuario actual
  static Future<User?> getCurrentUserData() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        return User.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // Verificar si el usuario es manager
  static Future<bool> isManager() async {
    User? user = await getCurrentUserData();
    return user?.isManager ?? false;
  }

  // Verificar si el usuario es empleado
  static Future<bool> isEmployee() async {
    User? user = await getCurrentUserData();
    return user?.isEmployee ?? false;
  }
}