import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  Future<void> initialize() async {
    final permission = await _messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.authorized) {
      await _messaging.getToken();
    }
  }

  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  Future<void> saveTokenToFirestore(String userId, String token) async {
    await _db.collection('users').doc(userId).update({
      'fcmToken': token,
    });
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
}
