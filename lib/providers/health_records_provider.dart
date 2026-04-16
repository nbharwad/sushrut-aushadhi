import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_record_model.dart';
import '../providers/auth_provider.dart';

final healthRecordsProvider =
    StreamProvider<List<HealthRecordModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('healthRecords')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => HealthRecordModel.fromFirestore(doc.data(), doc.id))
          .toList());
});
