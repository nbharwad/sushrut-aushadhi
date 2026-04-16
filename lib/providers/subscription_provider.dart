import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription_model.dart';
import '../providers/auth_provider.dart';

final subscriptionsProvider =
    StreamProvider<List<SubscriptionModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('subscriptions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => SubscriptionModel.fromFirestore(doc.data(), doc.id))
          .toList());
});

final activeSubscriptionsProvider = Provider<List<SubscriptionModel>>((ref) {
  final subs = ref.watch(subscriptionsProvider).valueOrNull ?? [];
  return subs.where((s) => s.isActive).toList();
});
