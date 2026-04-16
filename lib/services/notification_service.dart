import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/order_model.dart';
import '../models/subscription_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;

  static const String _deviceIdKey = 'fcm_device_id';
  
  String? _deviceId;
  Function(String orderId)? _onOrderNotificationTap;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isInitialized = false;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _deviceId = await _getOrCreateDeviceId();
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }

  String? get deviceId => _deviceId;

  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> subscribeToTokenRefresh() async {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _handleTokenRefresh(newToken);
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    if (_deviceId == null) return;
  }

  Future<void> setupMessageHandlers({
    required Function(RemoteMessage) onForegroundMessage,
    required Function(RemoteMessage) onBackgroundMessage,
    required Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      onForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onMessageOpenedApp(message);
    });

    await subscribeToTokenRefresh();
  }

  void setOrderNotificationTapCallback(Function(String orderId) callback) {
    _onOrderNotificationTap = callback;
  }

  void handleOrderNotificationTap(String? orderId) {
    if (orderId != null && _onOrderNotificationTap != null) {
      _onOrderNotificationTap!(orderId);
    }
  }

  Future<void> saveTokenToFirestore(String userId, String token) async {
    _deviceId ??= await _getOrCreateDeviceId();

    await _db.collection('users').doc(userId).set({
      'fcmTokens': {
        _deviceId!: token,
      },
    }, SetOptions(merge: true));
  }

  Future<void> updateTokenInFirestore(String userId, String newToken) async {
    if (_deviceId == null) return;

    await _db.collection('users').doc(userId).update({
      'fcmTokens.$_deviceId': newToken,
    });
  }

  Future<void> removeTokenFromFirestore(String userId) async {
    if (_deviceId == null) return;

    await _db.collection('users').doc(userId).update({
      'fcmTokens.$_deviceId': FieldValue.delete(),
    });
  }

  Future<void> saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? orderId,
    String? deviceId,
  }) async {
    final docRef = _db.collection('notifications').doc();
    
    await docRef.set({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'deviceId': deviceId ?? _deviceId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addLocalNotification({
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) async {
    final doc = _db.collection('notifications').doc();
    await doc.set({
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic>? parseNotificationData(RemoteMessage message) {
    return message.data;
  }

  String? getOrderIdFromData(Map<String, dynamic>? data) {
    return data?['orderId'] as String?;
  }

  bool isOrderNotification(Map<String, dynamic>? data) {
    if (data == null) return false;
    final type = data['type'] as String?;
    return type == 'new_order' || type == 'order_status';
  }

  Future<void> sendOrderNotificationToAdmin(
    OrderModel order,
    String adminWhatsApp,
  ) async {
    final shortId = order.orderId.length >= 8
        ? order.orderId.substring(0, 8)
        : order.orderId;
    final message = 'New Order #$shortId\n'
        'Customer: ${order.userName}\n'
        'Phone: ${order.userPhone}\n'
        'Total: Rs ${order.totalAmount.toStringAsFixed(2)}\n'
        'Items: ${order.itemCount}\n'
        'Check app for details.';

    final whatsappUrl =
        'https://wa.me/$adminWhatsApp?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    }
  }

  Future<void> callCustomer(String phoneNumber) async {
    final telUrl = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(telUrl))) {
      await launchUrl(Uri.parse(telUrl));
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _onOrderNotificationTap = null;
  }

  // ── Refill Reminders (F8) ─────────────────────────────────────────────────

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _localInitialized = false;

  Future<void> _ensureLocalInitialized() async {
    if (_localInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
        android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(settings);
    _localInitialized = true;
  }

  Future<void> scheduleRefillReminder(SubscriptionModel sub) async {
    await _ensureLocalInitialized();
    const androidDetails = AndroidNotificationDetails(
      'refill_reminders',
      'Refill Reminders',
      channelDescription: 'Reminders to refill your medicines',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      sub.id.hashCode,
      'Time to refill ${sub.medicineName}!',
      'Your ${sub.frequencyDays}-day supply is running out. Tap to reorder.',
      details,
    );
  }
}
