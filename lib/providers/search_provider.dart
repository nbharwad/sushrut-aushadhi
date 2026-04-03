import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/medicine_cache_service.dart';
import '../models/medicine_model.dart';
import '../core/di/service_providers.dart';

final cacheLoadedProvider = Provider<bool>((ref) => MedicineCacheService.isLoaded);

final hybridSearchProvider = FutureProvider.family<List<MedicineModel>, String>((ref, query) async {
  if (query.length < 2) return [];

  if (MedicineCacheService.isLoaded) {
    final cacheResults = MedicineCacheService.search(query);
    if (cacheResults.isNotEmpty) {
      return cacheResults.map((m) => MedicineModel.fromFirestore(m, m['id'] as String)).toList();
    }
  }

  try {
    final firestoreService = ref.read(firestoreServiceProvider);
    final results = await firestoreService.searchMedicines(query);
    return results;
  } catch (e) {
    return [];
  }
});
