import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String id;
  final DocumentReference user;
  final DateTime saleDate;
  final double totalAmount;
  final double totalWithoutIgv;
  final double totalIgv;
  final String status; // COMPLETED, RETURNED, PARTIAL_RETURNED
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.user,
    required this.saleDate,
    required this.totalAmount,
    required this.totalWithoutIgv,
    required this.totalIgv,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      user: data['user'],
      saleDate: (data['saleDate'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      totalWithoutIgv: (data['totalWithoutIgv'] ?? 0.0).toDouble(),
      totalIgv: (data['totalIgv'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'COMPLETED',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user': user,
      'saleDate': Timestamp.fromDate(saleDate),
      'totalAmount': totalAmount,
      'totalWithoutIgv': totalWithoutIgv,
      'totalIgv': totalIgv,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isReturned => status == 'RETURNED';
  bool get isPartiallyReturned => status == 'PARTIAL_RETURNED';
}