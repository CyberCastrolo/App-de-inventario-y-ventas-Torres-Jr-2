import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final double priceWithoutIgv;
  final double igvAmount;
  final DocumentReference category;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.priceWithoutIgv,
    required this.igvAmount,
    required this.category,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      priceWithoutIgv: (data['priceWithoutIgv'] ?? 0.0).toDouble(),
      igvAmount: (data['igvAmount'] ?? 0.0).toDouble(),
      category: data['category'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'priceWithoutIgv': priceWithoutIgv,
      'igvAmount': igvAmount,
      'category': category,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Método para calcular IGV automáticamente
  static Map<String, double> calcularIGV(double precioConIGV) {
    double precioSinIGV = precioConIGV / 1.18;
    double montoIGV = precioConIGV - precioSinIGV;

    return {
      'priceWithoutIgv': double.parse(precioSinIGV.toStringAsFixed(2)),
      'igvAmount': double.parse(montoIGV.toStringAsFixed(2)),
    };
  }
}