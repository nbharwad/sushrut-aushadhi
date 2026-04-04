import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionType {
  medicine,
  lab;

  String get displayName {
    switch (this) {
      case PrescriptionType.medicine:
        return 'Medicine';
      case PrescriptionType.lab:
        return 'Lab';
    }
  }

  static PrescriptionType fromString(String? value) {
    switch (value) {
      case 'lab':
        return PrescriptionType.lab;
      default:
        return PrescriptionType.medicine;
    }
  }
}

enum PrescriptionStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case PrescriptionStatus.pending:
        return 'Pending';
      case PrescriptionStatus.approved:
        return 'Approved';
      case PrescriptionStatus.rejected:
        return 'Rejected';
    }
  }

  static PrescriptionStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return PrescriptionStatus.approved;
      case 'rejected':
        return PrescriptionStatus.rejected;
      default:
        return PrescriptionStatus.pending;
    }
  }
}

class PrescriptionModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhone;
  final String imageUrl;
  final PrescriptionStatus status;
  final PrescriptionType prescriptionType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  PrescriptionModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhone,
    required this.imageUrl,
    this.status = PrescriptionStatus.pending,
    this.prescriptionType = PrescriptionType.medicine,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory PrescriptionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PrescriptionModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'],
      userPhone: data['userPhone'],
      imageUrl: data['imageUrl'] ?? '',
      status: PrescriptionStatus.fromString(data['status']),
      prescriptionType: PrescriptionType.fromString(data['prescriptionType']),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'imageUrl': imageUrl,
      'status': status.name,
      'prescriptionType': prescriptionType.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  PrescriptionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? imageUrl,
    PrescriptionStatus? status,
    PrescriptionType? prescriptionType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      prescriptionType: prescriptionType ?? this.prescriptionType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}