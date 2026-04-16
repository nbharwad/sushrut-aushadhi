import 'package:cloud_firestore/cloud_firestore.dart';

class PointsTransactionModel {
  final String id;
  final String type; // 'earned' or 'redeemed'
  final int points;
  final String? orderId;
  final String description;
  final DateTime createdAt;

  PointsTransactionModel({
    required this.id,
    required this.type,
    required this.points,
    this.orderId,
    required this.description,
    required this.createdAt,
  });

  factory PointsTransactionModel.fromMap(Map<String, dynamic> data, String id) {
    return PointsTransactionModel(
      id: id,
      type: data['type'] ?? 'earned',
      points: (data['points'] as num?)?.toInt() ?? 0,
      orderId: data['orderId'] as String?,
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
