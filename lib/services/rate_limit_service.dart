import 'package:cloud_firestore/cloud_firestore.dart';

class RateLimitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int maxOrdersPerDay = 10;
  static const int maxPrescriptionsPerDay = 5;
  static const int maxSearchPerMinute = 30;

  Future<void> checkOrderRateLimit(String userId) async {
    await _checkRateLimit(
      userId: userId,
      collection: 'orders',
      field: 'createdAt',
      limit: maxOrdersPerDay,
      errorMessage: 'Daily order limit reached. Please try again tomorrow.',
    );
  }

  Future<void> checkPrescriptionRateLimit(String userId) async {
    await _checkRateLimit(
      userId: userId,
      collection: 'prescriptions',
      field: 'createdAt',
      limit: maxPrescriptionsPerDay,
      errorMessage: 'Daily upload limit reached ($maxPrescriptionsPerDay/day). Please try again tomorrow.',
    );
  }

  Future<void> _checkRateLimit({
    required String userId,
    required String collection,
    required String field,
    required int limit,
    required String errorMessage,
  }) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final countQuery = await _db
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .where(field, isGreaterThan: Timestamp.fromDate(startOfDay))
          .where(field, isLessThan: Timestamp.fromDate(endOfDay))
          .count()
          .get();

      final count = countQuery.count ?? 0;
      if (count >= limit) {
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Daily') || e.toString().contains('limit')) {
        rethrow;
      }
    }
  }

  Future<bool> canPerformAction({
    required String userId,
    required String actionType,
    int windowMinutes = 1,
    int maxActions = 5,
  }) async {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: windowMinutes));

    try {
      final docRef = _db.collection('rate_limits').doc(userId);
      
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          actionType: 1,
          'lastReset': FieldValue.serverTimestamp(),
        });
        return true;
      }

      final data = doc.data()!;
      final lastReset = (data['lastReset'] as Timestamp?)?.toDate();
      final actionCount = data[actionType] ?? 0;

      if (lastReset != null && now.difference(lastReset).inMinutes >= windowMinutes) {
        await docRef.update({
          actionType: 1,
          'lastReset': FieldValue.serverTimestamp(),
        });
        return true;
      }

      if (actionCount >= maxActions) {
        return false;
      }

      await docRef.update({
        actionType: FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      return true;
    }
  }
}
