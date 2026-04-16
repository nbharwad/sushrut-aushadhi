import '../core/di/service_providers.dart';
import '../models/coupon_model.dart';

sealed class CouponResult {}

class CouponSuccess extends CouponResult {
  final CouponModel coupon;
  CouponSuccess(this.coupon);
}

class CouponError extends CouponResult {
  final String message;
  CouponError(this.message);
}

class CouponService {
  final _firestoreRef;

  CouponService(this._firestoreRef);

  Future<CouponResult> validateAndApply({
    required String code,
    required double cartTotal,
    required String userId,
  }) async {
    if (code.trim().isEmpty) return CouponError('Enter a promo code');

    try {
      final data = await _firestoreRef.getCoupon(code.trim());
      if (data == null) return CouponError('Invalid promo code');

      final coupon = CouponModel.fromMap(data, data['id'] as String);

      if (!coupon.isActive) return CouponError('This promo code is no longer active');

      if (coupon.expiryDate != null && coupon.expiryDate!.isBefore(DateTime.now())) {
        return CouponError('This promo code has expired');
      }

      if (cartTotal < coupon.minCartValue) {
        return CouponError(
            'Minimum cart value ₹${coupon.minCartValue.toStringAsFixed(0)} required');
      }

      if (coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!) {
        return CouponError('This promo code has reached its usage limit');
      }

      return CouponSuccess(coupon);
    } catch (e) {
      return CouponError('Could not validate code. Try again.');
    }
  }
}
