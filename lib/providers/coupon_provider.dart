import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/service_providers.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';

final appliedCouponProvider = StateProvider<CouponModel?>((ref) => null);

final couponDiscountProvider = Provider<double>((ref) {
  final coupon = ref.watch(appliedCouponProvider);
  if (coupon == null) return 0.0;
  // Cart total is read separately in cart_screen so this just returns the coupon.
  // The discount amount is computed in cart_screen with access to cartTotal.
  return 0.0; // placeholder; actual discount computed inline in cart_screen
});

final couponServiceProvider = Provider<CouponService>((ref) {
  return CouponService(ref.read(firestoreServiceProvider));
});
