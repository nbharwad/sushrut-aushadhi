import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/service_providers.dart';
import '../models/points_transaction_model.dart';
import '../providers/auth_provider.dart';

final pointsHistoryProvider =
    StreamProvider<List<PointsTransactionModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .getPointsHistory(uid)
      .map((list) => list
          .map((m) => PointsTransactionModel.fromMap(m, m['id'] as String))
          .toList());
});

/// Points to rupees conversion: 1 point = ₹0.50
double pointsToRupees(int points) => points * 0.5;

/// Rupees to points conversion
int rupeesToPoints(double rupees) => (rupees / 0.5).floor();

/// Maximum redeemable fraction of cart (20%)
double maxRedeemFraction = 0.20;
