import 'package:cloud_firestore/cloud_firestore.dart';

class StockItem {
  final String id;
  final DocumentReference product;
  final String location; // STORE, WAREHOUSE
  final String size;
  final String color;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockItem({
    required this.id,
    required this.product,
    required this.location,
    required this.size,
    required this.color,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StockItem(
      id: doc.id,
      product: data['product'],
      location: data['location'] ?? '',
      size: data['size'] ?? '',
      color: data['color'] ?? '',
      quantity: data['quantity'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product': product,
      'location': location,
      'size': size,
      'color': color,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isInStore => location == 'STORE';
  bool get isInWarehouse => location == 'WAREHOUSE';
  bool get hasStock => quantity > 0;
}