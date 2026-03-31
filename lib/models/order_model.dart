import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItem {
  final String medicineId;
  final String medicineName;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.medicineId,
    required this.medicineName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      medicineId: data['medicineId'] ?? '',
      medicineName: data['medicineName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}

class OrderModel {
  final String orderId;
  final String userId;
  final String userPhone;
  final String userName;
  final String deliveryAddress;
  final List<OrderItem> items;
  final String? prescriptionUrl;
  final double totalAmount;
  final OrderStatus status;
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;
  final int? rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.userPhone,
    required this.userName,
    required this.deliveryAddress,
    required this.items,
    this.prescriptionUrl,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.notes,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderModel(
      orderId: id,
      userId: data['userId'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userName: data['userName'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      items: (data['items'] as List?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      prescriptionUrl: data['prescriptionUrl'],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.fromString(data['status'] ?? 'pending'),
      paymentMethod: data['paymentMethod'] ?? 'cod',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      notes: data['notes'],
      rating: data['rating'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userPhone': userPhone,
      'userName': userName,
      'deliveryAddress': deliveryAddress,
      'items': items.map((e) => e.toMap()).toList(),
      'prescriptionUrl': prescriptionUrl,
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
