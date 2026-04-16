import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String medicineId;
  final String medicineName;
  final int quantity;
  final int frequencyDays; // 30, 60, or 90
  final DateTime nextRefillDate;
  final bool isActive;
  final String? lastOrderId;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.frequencyDays,
    required this.nextRefillDate,
    required this.isActive,
    this.lastOrderId,
    required this.createdAt,
  });

  factory SubscriptionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SubscriptionModel(
      id: id,
      medicineId: data['medicineId'] ?? '',
      medicineName: data['medicineName'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      frequencyDays: (data['frequencyDays'] as num?)?.toInt() ?? 30,
      nextRefillDate:
          (data['nextRefillDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      lastOrderId: data['lastOrderId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      'frequencyDays': frequencyDays,
      'nextRefillDate': Timestamp.fromDate(nextRefillDate),
      'isActive': isActive,
      if (lastOrderId != null) 'lastOrderId': lastOrderId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isDueSoon {
    final diff = nextRefillDate.difference(DateTime.now()).inDays;
    return diff <= 2 && diff >= 0;
  }
}
