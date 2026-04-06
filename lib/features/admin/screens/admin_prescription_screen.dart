import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/auth_provider.dart';
import '../admin_prescriptions_screen.dart';

class AdminPrescriptionScreen extends ConsumerWidget {
  const AdminPrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAuth = ref.watch(adminAuthStateProvider);

    return adminAuth.when(
      loading: () => _loadingScaffold(context),
      error: (e, _) => _accessDeniedScaffold(context),
      data: (state) {
        if (state.status == AdminAuthStatus.admin) {
          return const AdminPrescriptionsScreen();
        }
        return _accessDeniedScaffold(context);
      },
    );
  }

  Widget _loadingScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Prescriptions',
              style: GoogleFonts.sora(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accessDeniedScaffold(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Access Denied'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E56),
              ),
              child: const Text('Go Home', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
