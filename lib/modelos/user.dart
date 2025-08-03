import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String displayName;
  final String email;
  final String role; // MANAGER, EMPLOYEE
  final DateTime createdAt;
  final String? photoUrl;

  User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.photoUrl,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
    };
  }

  bool get isManager => role == 'MANAGER';
  bool get isEmployee => role == 'EMPLOYEE';
}