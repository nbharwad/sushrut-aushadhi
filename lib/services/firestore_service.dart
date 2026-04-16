import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/medicine_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../core/utils/app_logger.dart';
import 'local_data_service.dart';
import 'rate_limit_service.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  final _uuid = const Uuid();
  late final RateLimitService _rateLimit;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _rateLimit = RateLimitService(firestore: _db);
  }

  String placeOrderId() => _uuid.v4();

  Stream<List<MedicineModel>> getMedicinesStream({String? category}) async* {
    Query<Map<String, dynamic>> query = _db
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .limit(50);

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    try {
      await for (final snapshot in query.snapshots()) {
        yield snapshot.docs
            .map((doc) => MedicineModel.fromFirestore(doc.data(), doc.id))
            .toList();
      }
    } catch (_) {
      final fallback = await _fallbackMedicines(category: category);
      yield fallback;
    }
  }

  Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final doc = await _db.collection('medicines').doc(id).get();
      if (!doc.exists) return null;
      return MedicineModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (_) {
      final fallback = await LocalDataService.getMedicineById(id);
      if (fallback == null) return null;
      return MedicineModel.fromFirestore(
          fallback, fallback['id']?.toString() ?? id);
    }
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _db
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => MedicineModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (_) {
      final fallback = await LocalDataService.searchMedicines(query);
      return fallback
          .map((item) => MedicineModel.fromFirestore(
                Map<String, dynamic>.from(item as Map),
                (item as Map)['id']?.toString() ?? '',
              ))
          .toList();
    }
  }

  Future<List<MedicineModel>> _fallbackMedicines({String? category}) async {
    final fallback = await LocalDataService.getMedicines(category: category);
    return fallback
        .map((item) => MedicineModel.fromFirestore(
              Map<String, dynamic>.from(item as Map),
              (item as Map)['id']?.toString() ?? '',
            ))
        .toList();
  }

  Future<String> placeOrder(OrderModel order) async {
    await _rateLimit.checkOrderRateLimit(order.userId);

    final sanitizedName = _sanitizeString(order.userName);
    final sanitizedNotes =
        order.notes != null ? _sanitizeString(order.notes!) : null;

    final orderId = order.orderId.isNotEmpty ? order.orderId : placeOrderId();
    final orderWithId = OrderModel(
      orderId: orderId,
      userId: order.userId,
      userPhone: order.userPhone,
      userName: sanitizedName,
      deliveryAddress: order.deliveryAddress,
      items: order.items,
      prescriptionUrl: order.prescriptionUrl,
      totalAmount: order.totalAmount,
      status: order.status,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      notes: sanitizedNotes,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );

    await _db.collection('orders').doc(orderId).set(orderWithId.toMap());

    AppLogger.info("Order placed: $orderId", tag: "Order");
    AppLogger.logCustomKey("order_id", orderId);
    AppLogger.logCustomKey("order_total", order.totalAmount.toString());

    return orderId;
  }

  String _sanitizeString(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<OrderModel>> getAllOrders({int limit = 200}) {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<({List<OrderModel> orders, DocumentSnapshot? lastDoc})>
      getOrdersPaginated({
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    AppLogger.debug('Admin orders fetch start', tag: 'Firestore');
    AppLogger.debug('UID: $uid, lastDoc: ${lastDoc != null}, limit: $limit',
        tag: 'Firestore');

    Query<Map<String, dynamic>> query = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    try {
      final snapshot = await query.get();
      AppLogger.debug('Admin orders fetch end: ${snapshot.docs.length} docs',
          tag: 'Firestore');
      return (
        orders: snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
            .toList(),
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      if (e is FirebaseException) {
        final code = e.code;
        final message = e.message?.toLowerCase() ?? '';
        AppLogger.error('Admin orders fetch error', error: e, tag: 'Firestore');
        if (code == 'permission-denied') {
          AppLogger.warning('Permission denied for admin orders',
              tag: 'Firestore');
        } else if (code == 'failed-precondition') {
          if (message.contains('index') || message.contains('query')) {
            AppLogger.warning('Missing index for admin orders query',
                tag: 'Firestore');
          } else {
            AppLogger.warning('Query precondition failed for admin orders',
                tag: 'Firestore');
          }
        } else if (code == 'unavailable') {
          AppLogger.warning('Firestore unavailable', tag: 'Firestore');
        }
      } else {
        AppLogger.error('Admin orders fetch error', error: e, tag: 'Firestore');
      }
      rethrow;
    }
  }

  Stream<List<OrderModel>> getOrdersByStatus(String status, {int limit = 100}) {
    return _db
        .collection('orders')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return OrderModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String updatedBy = 'system',
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': status,
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'updatedBy': updatedBy,
        }
      ]),
    };
    if (status == 'delivered') {
      updateData['deliveredAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('orders').doc(orderId).update(updateData);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc.data()!, uid);
    }
    return null;
  }

  Future<UserModel?> getUserFresh(String uid) async {
    final doc = await _db.collection('users').doc(uid).get(
          GetOptions(source: Source.server),
        );
    if (doc.exists) {
      return UserModel.fromFirestore(doc.data()!, uid);
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<List<CategoryModel>> getCategoriesStream() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    final id = _uuid.v4();
    await _db.collection('medicines').doc(id).set(
          MedicineModel(
            id: id,
            name: medicine.name,
            genericName: medicine.genericName,
            manufacturer: medicine.manufacturer,
            category: medicine.category,
            price: medicine.price,
            mrp: medicine.mrp,
            stock: medicine.stock,
            unit: medicine.unit,
            imageUrl: medicine.imageUrl,
            requiresPrescription: medicine.requiresPrescription,
            description: medicine.description,
            isActive: medicine.isActive,
            expiryDate: medicine.expiryDate,
            batchNumber: medicine.batchNumber,
            schedule: medicine.schedule,
            hsnCode: medicine.hsnCode,
          ).toMap(),
        );
  }

  // ── Notification Helper ───────────────────────────────────────────────────

  Future<void> saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      if (orderId != null) 'orderId': orderId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Generic Alternatives (F4) ──────────────────────────────────────────────

  Future<List<MedicineModel>> getGenericAlternatives({
    required String genericName,
    required String excludeId,
    int limit = 6,
  }) async {
    try {
      final snapshot = await _db
          .collection('medicines')
          .where('genericName', isEqualTo: genericName)
          .where('isActive', isEqualTo: true)
          .limit(limit + 1)
          .get();
      return snapshot.docs
          .map((doc) => MedicineModel.fromFirestore(doc.data(), doc.id))
          .where((m) => m.id != excludeId)
          .take(limit)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Reviews & Ratings (F5) ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getMedicineReviews(String medicineId) {
    return _db
        .collection('medicines')
        .doc(medicineId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> submitReview({
    required String medicineId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
    required String orderId,
    required bool isVerified,
  }) async {
    final reviewId = _uuid.v4();
    await _db
        .collection('medicines')
        .doc(medicineId)
        .collection('reviews')
        .doc(reviewId)
        .set({
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'orderId': orderId,
      'isVerified': isVerified,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // backward-compat: stamp last rating on order doc
    await _db
        .collection('orders')
        .doc(orderId)
        .set({'rating': rating}, SetOptions(merge: true));
  }

  Future<bool> hasReviewedMedicine({
    required String userId,
    required String medicineId,
  }) async {
    final snap = await _db
        .collection('medicines')
        .doc(medicineId)
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Coupon / Promo (F6) ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCoupon(String code) async {
    final doc = await _db.collection('coupons').doc(code.toUpperCase()).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  Future<void> incrementCouponUsage(String code) async {
    await _db
        .collection('coupons')
        .doc(code.toUpperCase())
        .update({'usedCount': FieldValue.increment(1)});
  }

  // ── Loyalty Points (F7) ───────────────────────────────────────────────────

  Future<void> awardPoints({
    required String userId,
    required String orderId,
    required double orderTotal,
    required int points,
  }) async {
    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(userId);
      tx.update(userRef, {'walletPoints': FieldValue.increment(points)});
      final histRef = userRef.collection('pointsHistory').doc(_uuid.v4());
      tx.set(histRef, {
        'type': 'earned',
        'points': points,
        'orderId': orderId,
        'description': 'Earned on order ₹${orderTotal.toStringAsFixed(0)}',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> redeemPoints({
    required String userId,
    required int pointsToRedeem,
    required String orderId,
  }) async {
    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(userId);
      final snap = await tx.get(userRef);
      final current = (snap.data()?['walletPoints'] as int?) ?? 0;
      if (current < pointsToRedeem) throw Exception('Insufficient points');
      tx.update(userRef, {'walletPoints': FieldValue.increment(-pointsToRedeem)});
      final histRef = userRef.collection('pointsHistory').doc(_uuid.v4());
      tx.set(histRef, {
        'type': 'redeemed',
        'points': pointsToRedeem,
        'orderId': orderId,
        'description': 'Redeemed for order',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Map<String, dynamic>>> getPointsHistory(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('pointsHistory')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Return Requests (F10) ─────────────────────────────────────────────────

  Future<String> submitReturnRequest(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    await _db.collection('returnRequests').doc(id).set({
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Stream<List<Map<String, dynamic>>> getReturnRequests({String? status}) {
    Query<Map<String, dynamic>> query = _db
        .collection('returnRequests')
        .orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getUserReturnRequests(String userId) {
    return _db
        .collection('returnRequests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> updateReturnStatus({
    required String requestId,
    required String status,
    String? adminNote,
  }) async {
    await _db.collection('returnRequests').doc(requestId).update({
      'status': status,
      if (adminNote != null) 'adminNote': adminNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
