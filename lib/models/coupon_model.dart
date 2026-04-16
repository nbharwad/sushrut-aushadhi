import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String code;
  final String discountType; // 'percent' or 'flat'
  final double discountValue;
  final double minCartValue;
  final double? maxDiscount;
  final DateTime? expiryDate;
  final bool isActive;
  final int? usageLimit;
  final int usedCount;
  final List<String> applicableCategories;

  CouponModel({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minCartValue,
    this.maxDiscount,
    this.expiryDate,
    required this.isActive,
    this.usageLimit,
    required this.usedCount,
    this.applicableCategories = const [],
  });

  factory CouponModel.fromMap(Map<String, dynamic> data, String code) {
    return CouponModel(
      code: code,
      discountType: data['discountType'] ?? 'percent',
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0,
      minCartValue: (data['minCartValue'] as num?)?.toDouble() ?? 0,
      maxDiscount: (data['maxDiscount'] as num?)?.toDouble(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? false,
      usageLimit: (data['usageLimit'] as num?)?.toInt(),
      usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
      applicableCategories:
          (data['applicableCategories'] as List?)?.cast<String>() ?? [],
    );
  }

  double calculateDiscount(double cartTotal) {
    double discount;
    if (discountType == 'percent') {
      discount = cartTotal * discountValue / 100;
    } else {
      discount = discountValue;
    }
    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }
    return discount > cartTotal ? cartTotal : discount;
  }
}
