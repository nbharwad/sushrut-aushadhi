import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/subscription_model.dart';
import 'notification_service.dart';

class SubscriptionService {
  static const _uuid = Uuid();

  Future<void> createSubscription({
    required String userId,
    required String medicineId,
    required String medicineName,
    required int quantity,
    required int frequencyDays,
  }) async {
    final id = _uuid.v4();
    final nextRefillDate = DateTime.now().add(Duration(days: frequencyDays));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .doc(id)
        .set({
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      'frequencyDays': frequencyDays,
      'nextRefillDate': Timestamp.fromDate(nextRefillDate),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSubscriptionStatus({
    required String userId,
    required String subscriptionId,
    required bool isActive,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .doc(subscriptionId)
        .update({'isActive': isActive});
  }

  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .doc(subscriptionId)
        .delete();
  }

  Future<void> bumpNextRefillDate({
    required String userId,
    required String subscriptionId,
    required int frequencyDays,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .doc(subscriptionId)
        .update({
      'nextRefillDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: frequencyDays))),
    });
  }

  /// Called on app launch — fires local notifications for upcoming refills.
  Future<void> checkAndNotify({
    required String userId,
    required NotificationService notificationService,
  }) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .where('isActive', isEqualTo: true)
          .get();

      final dueSoon = snap.docs
          .map((d) => SubscriptionModel.fromFirestore(d.data(), d.id))
          .where((s) => s.isDueSoon)
          .toList();

      for (final sub in dueSoon) {
        await notificationService.scheduleRefillReminder(sub);
      }
    } catch (_) {
      // Non-critical — silently ignore errors
    }
  }
}
