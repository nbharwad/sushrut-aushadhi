import 'package:cloud_firestore/cloud_firestore.dart';

class HealthRecordModel {
  final String id;
  final String title;
  final String type; // 'lab_report', 'xray', 'discharge', 'other'
  final String fileUrl;
  final String fileType; // 'pdf' or 'image'
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  HealthRecordModel({
    required this.id,
    required this.title,
    required this.type,
    required this.fileUrl,
    required this.fileType,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory HealthRecordModel.fromFirestore(Map<String, dynamic> data, String id) {
    return HealthRecordModel(
      id: id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'other',
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? 'image',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get typeDisplayName {
    switch (type) {
      case 'lab_report':
        return 'Lab Report';
      case 'xray':
        return 'X-Ray';
      case 'discharge':
        return 'Discharge Summary';
      default:
        return 'Other';
    }
  }
}
