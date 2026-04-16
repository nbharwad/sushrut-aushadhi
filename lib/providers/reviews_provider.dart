import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/service_providers.dart';
import '../models/review_model.dart';

final medicineReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, medicineId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService
      .getMedicineReviews(medicineId)
      .map((list) => list.map((m) => ReviewModel.fromMap(m, m['id'] as String)).toList());
});

final averageRatingProvider = Provider.family<double, String>((ref, medicineId) {
  final reviews = ref.watch(medicineReviewsProvider(medicineId)).valueOrNull ?? [];
  if (reviews.isEmpty) return 0.0;
  final sum = reviews.fold<int>(0, (s, r) => s + r.rating);
  return sum / reviews.length;
});
