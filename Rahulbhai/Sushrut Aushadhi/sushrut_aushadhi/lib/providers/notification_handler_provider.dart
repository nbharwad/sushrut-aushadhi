import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di/service_providers.dart';
import '../models/order_model.dart';

class NotificationHandlerNotifier extends StateNotifier<bool> {
  final Ref _ref;
  bool _isInitialized = false;
  GoRouter? _router;

  NotificationHandlerNotifier(this._ref) : super(false);

  Future<void> initialize(GoRouter router) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _router = router;

    final notificationService = _ref.read(notificationServiceProvider);
    await notificationService.initialize();

    await notificationService.setupMessageHandlers(
      onForegroundMessage: _handleForegroundMessage,
      onBackgroundMessage: _handleBackgroundMessage,
      onMessageOpenedApp: _handleMessageOpenedApp,
    );

    notificationService.setOrderNotificationTapCallback((String orderId) {
      if (_router != null) {
        _router!.push('/order/$orderId');
      }
    });

    state = true;
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    final notificationService = _ref.read(notificationServiceProvider);
    final data = notificationService.parseNotificationData(message);
    
    if (message.notification != null) {
      final orderId = notificationService.getOrderIdFromData(data);
      final type = data?['type'] as String? ?? 'general';
      
      if (notificationService.isOrderNotification(data)) {
        notificationService.handleOrderNotificationTap(orderId);
      }

      await notificationService.saveNotificationToFirestore(
        userId: '',
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        type: type,
        orderId: orderId,
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) async {
    final notificationService = _ref.read(notificationServiceProvider);
    final data = notificationService.parseNotificationData(message);
    final orderId = notificationService.getOrderIdFromData(data);
    final type = data?['type'] as String? ?? 'general';
    final userId = data?['userId'] as String? ?? '';

    if (message.notification != null) {
      await notificationService.saveNotificationToFirestore(
        userId: userId,
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        type: type,
        orderId: orderId,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final notificationService = _ref.read(notificationServiceProvider);
    final data = notificationService.parseNotificationData(message);
    final orderId = notificationService.getOrderIdFromData(data);

    if (notificationService.isOrderNotification(data) && orderId != null) {
      notificationService.handleOrderNotificationTap(orderId);
    }
  }

  Future<void> sendOrderNotificationToAdmin(
    OrderModel order,
    String adminWhatsApp,
  ) async {
    final notificationService = _ref.read(notificationServiceProvider);
    await notificationService.sendOrderNotificationToAdmin(order, adminWhatsApp);
  }

  Future<void> callCustomer(String phoneNumber) async {
    final notificationService = _ref.read(notificationServiceProvider);
    await notificationService.callCustomer(phoneNumber);
  }
}

final notificationHandlerProvider = StateNotifierProvider<NotificationHandlerNotifier, bool>((ref) {
  return NotificationHandlerNotifier(ref);
});
