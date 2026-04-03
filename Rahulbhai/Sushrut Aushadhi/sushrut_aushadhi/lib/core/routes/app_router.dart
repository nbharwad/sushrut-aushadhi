import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/main_shell.dart';
import '../../features/admin/admin_order_detail_screen.dart';
import '../../features/admin/admin_orders_screen.dart';
import '../../features/admin/admin_prescriptions_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/search_screen.dart';
import '../../features/medicine/medicine_detail_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/order_confirmation_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/prescription/my_prescriptions_screen.dart';
import '../../features/prescription/prescription_upload_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../providers/auth_provider.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final isVerifyingProvider = StateProvider<bool>((ref) => false);

final goRouterProvider = Provider<GoRouter>((ref) {
  final authReady = ref.watch(authReadyProvider);
  final isVerifying = ref.watch(isVerifyingProvider);
  final authListener = GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authListener,
    redirect: (context, state) {
      if (isVerifying) return null;

      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' || location == '/otp';

      final isProtected = location.startsWith('/order') ||
          location.startsWith('/prescription') ||
          location.startsWith('/admin') ||
          location == '/cart' ||
          location == '/profile';

      if (user != null && isAuthRoute) return '/home';

      if (user == null && isProtected) return '/login';

      if (location.startsWith('/admin') && !authReady) return '/home';

      if (location.startsWith('/admin')) {
        final isAdminAsync = ref.read(isAdminFromClaimsProvider);
        final isAdmin = isAdminAsync.valueOrNull ?? false;
        if (!isAdmin) return '/home';
      }

      return null;
    },
    routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final verificationId = extra?['verificationId'] as String?;
        final phoneNumber = extra?['phoneNumber'] as String?;
        if (verificationId == null ||
            verificationId.isEmpty ||
            phoneNumber == null ||
            phoneNumber.isEmpty) {
          return const LoginScreen();
        }
        return OtpScreen(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/medicine',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final hasDirectMedicinePayload = extra != null &&
            !extra.containsKey('medicine') &&
            !extra.containsKey('localMedicine') &&
            !extra.containsKey('medicineId');
        return MedicineDetailScreen(
          medicineId: extra?['medicineId'] as String? ?? extra?['id'] as String?,
          medicine: hasDirectMedicinePayload ? extra : extra?['medicine'] as Map<String, dynamic>?,
          localMedicine: extra?['localMedicine'] as Map<String, dynamic>?,
        );
      },
    ),
    GoRoute(
      path: '/medicine/:id',
      builder: (context, state) {
        final medicineId = state.pathParameters['id'];
        final extra = state.extra as Map<String, dynamic>?;

        if (medicineId != null && medicineId.isNotEmpty) {
          return MedicineDetailScreen(
            medicineId: medicineId,
            medicine: extra?['medicine'] as Map<String, dynamic>?,
            localMedicine: extra?['localMedicine'] as Map<String, dynamic>?,
          );
        }
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/prescription',
      builder: (context, state) => const PrescriptionUploadScreen(),
    ),
    GoRoute(
      path: '/my-prescriptions',
      builder: (context, state) => const MyPrescriptionsScreen(),
    ),
    GoRoute(
      path: '/order/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id'];
        if (orderId == null || orderId.isEmpty) {
          return const OrdersScreen();
        }
        return OrderDetailScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const HomeScreen();
        }
        return OrderConfirmationScreen(
          orderId: extra['orderId'] as String? ?? '',
          totalAmount: (extra['totalAmount'] as num?)?.toDouble() ?? 0.0,
          items: (extra['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          deliveryAddress: extra['deliveryAddress'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminOrdersScreen(),
    ),
    GoRoute(
      path: '/admin/order/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id'];
        if (orderId == null || orderId.isEmpty) {
          return const AdminOrdersScreen();
        }
        return AdminOrderDetailScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/admin/prescriptions',
      builder: (context, state) => const AdminPrescriptionsScreen(),
    ),
    ],
  );
});
