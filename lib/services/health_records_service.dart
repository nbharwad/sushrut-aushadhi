import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class HealthRecordsService {
  static const _uuid = Uuid();
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  HealthRecordsService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<void> uploadRecord({
    required String userId,
    required File file,
    required String title,
    required String type,
    required String fileType, // 'pdf' or 'image'
    required DateTime date,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final ext = fileType == 'pdf' ? 'pdf' : 'jpg';
    final ref = _storage
        .ref()
        .child('health_records')
        .child(userId)
        .child('$id.$ext');

    final contentType = fileType == 'pdf' ? 'application/pdf' : 'image/jpeg';
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    final url = await uploadTask.ref.getDownloadURL();

    await _db
        .collection('users')
        .doc(userId)
        .collection('healthRecords')
        .doc(id)
        .set({
      'title': title,
      'type': type,
      'fileUrl': url,
      'fileType': fileType,
      'date': Timestamp.fromDate(date),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRecord({
    required String userId,
    required String recordId,
    required String fileUrl,
  }) async {
    // Delete from Firestore
    await _db
        .collection('users')
        .doc(userId)
        .collection('healthRecords')
        .doc(recordId)
        .delete();

    // Delete from Storage
    try {
      await _storage.refFromURL(fileUrl).delete();
    } catch (_) {
      // Ignore if already deleted
    }
  }
}
