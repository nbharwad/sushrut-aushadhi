import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../models/lab_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lab_providers.dart';

class LabOrdersScreen extends ConsumerWidget {
  const LabOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            if (user == null)
              Expanded(child: _buildLoginPrompt(context))
            else
              Expanded(child: _buildOrdersList(context, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.labPrimary, AppColors.labSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'My Lab Orders',
              style: GoogleFonts.sora(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/lab/book'),
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Book New Test',
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.labPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 48, color: AppColors.labPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'Login Required',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to view your lab orders',
              style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.labPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Login', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userLabOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(context);
        }
        return RefreshIndicator(
          color: Colors.white,
          backgroundColor: AppColors.labPrimary,
          onRefresh: () async {
            ref.invalidate(userLabOrdersProvider);
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) => _LabOrderListTile(order: orders[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.labPrimary)),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Could not load orders', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(error.toString(), style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.labPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.biotech_outlined, size: 48, color: AppColors.labPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Lab Orders Yet',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Book your first lab test and get results at home',
              style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/lab/book'),
              icon: const Icon(Icons.add),
              label: Text('Book a Lab Test', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.labPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabOrderListTile extends StatelessWidget {
  final LabOrderModel order;

  const _LabOrderListTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final shortId = order.orderId.length >= 6
        ? order.orderId.substring(0, 6).toUpperCase()
        : order.orderId.toUpperCase();

    return GestureDetector(
      onTap: () => context.push('/lab-order/${order.orderId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECE7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_statusIcon(order.status), color: statusColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SA-LB-$shortId',
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.testCount} ${order.testCount == 1 ? 'test' : 'tests'} • \u20B9${order.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: GoogleFonts.sora(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _statusColor(LabOrderStatus status) {
    switch (status) {
      case LabOrderStatus.pending:
        return Colors.orange;
      case LabOrderStatus.sampleCollected:
        return Colors.blue;
      case LabOrderStatus.processing:
        return Colors.purple;
      case LabOrderStatus.completed:
        return AppColors.labPrimary;
      case LabOrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _statusIcon(LabOrderStatus status) {
    switch (status) {
      case LabOrderStatus.pending:
        return Icons.hourglass_empty;
      case LabOrderStatus.sampleCollected:
        return Icons.bloodtype;
      case LabOrderStatus.processing:
        return Icons.science;
      case LabOrderStatus.completed:
        return Icons.check_circle;
      case LabOrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}
