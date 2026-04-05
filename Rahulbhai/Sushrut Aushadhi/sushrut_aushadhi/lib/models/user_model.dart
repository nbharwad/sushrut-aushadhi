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
  /// Deprecated: kept for Firestore backward-compatibility only.
  /// Use [role] == 'admin' for all role checks — never read isAdmin directly.
  final bool isAdmin;
  final String role;
  final String? fcmToken;
  final Map<String, String>? fcmTokens;
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
    this.fcmTokens,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
  }) : deliveryAddress =
            deliveryAddress ?? DeliveryAddress(line1: '', city: '', state: '', pincode: '');

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    final fcmTokensData = data['fcmTokens'] as Map<String, dynamic>?;
    final legacyToken = data['fcmToken'] as String?;
    
    Map<String, String>? fcmTokens;
    if (fcmTokensData != null) {
      fcmTokens = fcmTokensData.map((key, value) => MapEntry(key, value as String));
    } else if (legacyToken != null) {
      fcmTokens = {'default': legacyToken};
    }

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
      fcmToken: legacyToken,
      fcmTokens: fcmTokens,
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
      'fcmTokens': fcmTokens,
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
    Map<String, String>? fcmTokens,
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
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
