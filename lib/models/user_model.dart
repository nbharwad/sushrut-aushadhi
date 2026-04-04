import 'package:cloud_firestore/cloud_firestore.dart';

import 'delivery_address.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String pincode;
  final DeliveryAddress deliveryAddress;
  final bool isAdmin;
  final String role;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.pincode = '',
    DeliveryAddress? deliveryAddress,
    this.isAdmin = false,
    this.role = 'customer',
    this.fcmToken,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
  }) : deliveryAddress =
            deliveryAddress ?? DeliveryAddress(line1: '', city: '', state: '', pincode: '');

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      pincode: data['pincode'] ?? '',
      deliveryAddress: DeliveryAddress.fromFirestoreData(data['deliveryAddress']),
      isAdmin: data['isAdmin'] ?? false,
      role: data['role'] ?? 'customer',
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'pincode': pincode,
      'deliveryAddress': deliveryAddress.toMap(),
      'role': role,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? pincode,
    DeliveryAddress? deliveryAddress,
    bool? isAdmin,
    String? role,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      isAdmin: isAdmin ?? this.isAdmin,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
