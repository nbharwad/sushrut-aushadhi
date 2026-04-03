import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';

class MedicineCacheService {
  static List<Map<String, dynamic>> _cache = [];
  static bool _loaded = false;
  static bool _loading = false;
  static const String _cacheKey = 'medicine_names_cache';
  static const String _cacheTimeKey = 'medicine_cache_time';
  static const int _cacheHours = 24;

  static Future<void> loadCache() async {
    if (_loaded || _loading) return;
    _loading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoad = prefs.getInt(_cacheTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursPassed = (now - lastLoad) / (1000 * 60 * 60);

      if (hoursPassed < _cacheHours) {
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          _cache = List<Map<String, dynamic>>.from(
            jsonDecode(cached).map((e) => Map<String, dynamic>.from(e))
          );
          _loaded = true;
          _loading = false;
          AppLogger.info('Loaded ${_cache.length} medicines from local cache', tag: 'MedicineCache');
          return;
        }
      }

      AppLogger.info('Fetching medicine names from Firestore...', tag: 'MedicineCache');
      final snapshot = await FirebaseFirestore.instance
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .get();

      _cache = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? '',
        'manufacturer': doc.data()['manufacturer'] ?? '',
        'price': doc.data()['price'] ?? 0,
        'mrp': doc.data()['mrp'] ?? 0,
        'category': doc.data()['category'] ?? 'other',
        'requiresPrescription': doc.data()['requiresPrescription'] ?? false,
        'unit': doc.data()['unit'] ?? 'strip',
        'description': doc.data()['description'] ?? '',
        'dosage': doc.data()['dosage'] ?? '',
        'sideEffects': doc.data()['sideEffects'] ?? '',
        'imageUrl': doc.data()['imageUrl'] ?? '',
      }).toList();

      await prefs.setString(_cacheKey, jsonEncode(_cache));
      await prefs.setInt(_cacheTimeKey, now);
      _loaded = true;
      AppLogger.info('Cached ${_cache.length} medicine names locally', tag: 'MedicineCache');
    } catch (e) {
      AppLogger.error('Error loading medicine cache: $e', tag: 'MedicineCache');
    } finally {
      _loading = false;
    }
  }

  static List<Map<String, dynamic>> search(String query) {
    if (query.length < 2 || !_loaded) return [];
    final q = query.toLowerCase().trim();

    final results = _cache.where((med) {
      final name = (med['name'] as String).toLowerCase();
      final mfr = (med['manufacturer'] as String).toLowerCase();
      final generic = (med['genericName'] as String? ?? '').toLowerCase();
      return name.contains(q) || mfr.contains(q) || generic.contains(q);
    }).toList();

    results.sort((a, b) {
      final aName = (a['name'] as String).toLowerCase();
      final bName = (b['name'] as String).toLowerCase();
      final aStarts = aName.startsWith(q) ? 0 : 1;
      final bStarts = bName.startsWith(q) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return aName.compareTo(bName);
    });

    return results.take(20).toList();
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    _cache = [];
    _loaded = false;
  }

  static int get cacheSize => _cache.length;
  static bool get isLoaded => _loaded;
  static List<Map<String, dynamic>> get allMedicines => _cache;
}
