import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnRequestModel {
  final String id;
  final String orderId;
  final String userId;
  final String userPhone;
  final List<String> items;
  final String reason;
  final String description;
  final String? photoUrl;
  final String status; // pending, approved, rejected, completed
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReturnRequestModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userPhone,
    required this.items,
    required this.reason,
    required this.description,
    this.photoUrl,
    required this.status,
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReturnRequestModel.fromMap(Map<String, dynamic> data, String id) {
    return ReturnRequestModel(
      id: id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      userPhone: data['userPhone'] ?? '',
      items: (data['items'] as List?)?.cast<String>() ?? [],
      reason: data['reason'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'] as String?,
      status: data['status'] ?? 'pending',
      adminNote: data['adminNote'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending Review';
    }
  }
}
