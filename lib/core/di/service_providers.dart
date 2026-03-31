import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/prescription_service.dart';
import '../../services/rate_limit_service.dart';
import '../../services/storage_service.dart';
import '../../services/search_history_service.dart';
import '../../services/notification_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/whatsapp_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final prescriptionServiceProvider = Provider<PrescriptionService>((ref) {
  return PrescriptionService();
});

final rateLimitServiceProvider = Provider<RateLimitService>((ref) {
  return RateLimitService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  return SearchHistoryService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final whatsappServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService();
});
