import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/lab_order_card.dart';
import '../../core/widgets/lab_filter_chips.dart';
import '../../core/widgets/lab_orders_loading_shimmer.dart';
import '../../models/lab_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lab_providers.dart';

final selectedLabFilterProvider = StateProvider<String?>((ref) => null);

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
              Expanded(child: _buildOrdersContent(context, ref)),
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
              decoration: const BoxDecoration(
                color: AppColors.labPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  size: 48, color: AppColors.labPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'Login Required',
              style:
                  GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to view your lab orders',
              style: GoogleFonts.sora(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.labPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Login',
                  style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersContent(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userLabOrdersProvider);
    final selectedFilter = ref.watch(selectedLabFilterProvider);

    return ordersAsync.when(
      data: (orders) {
        final filteredOrders = _filterOrders(orders, selectedFilter);
        final filterCounts = _getFilterCounts(orders);

        return Column(
          children: [
            _buildFilterSection(selectedFilter, filterCounts),
            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyState(context)
                  : _buildOrdersList(context, ref, filteredOrders),
            ),
          ],
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(context, ref, error),
    );
  }

  Widget _buildFilterSection(String? selectedFilter, Map<String, int> counts) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabFilterChips(
            selectedFilter: selectedFilter,
            onFilterSelected: (filter) {},
            counts: counts,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Map<String, int> _getFilterCounts(List<LabOrderModel> orders) {
    return {
      'all': orders.length,
      'pending': orders.where((o) => o.status == LabOrderStatus.pending).length,
      'sampleCollected': orders
          .where((o) => o.status == LabOrderStatus.sampleCollected)
          .length,
      'processing':
          orders.where((o) => o.status == LabOrderStatus.processing).length,
      'completed':
          orders.where((o) => o.status == LabOrderStatus.completed).length,
      'cancelled':
          orders.where((o) => o.status == LabOrderStatus.cancelled).length,
    };
  }

  List<LabOrderModel> _filterOrders(
      List<LabOrderModel> orders, String? filter) {
    if (filter == null || filter == 'all') {
      return orders;
    }
    final status = LabOrderStatus.fromString(filter);
    return orders.where((o) => o.status == status).toList();
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildFilterSection(null, {}),
        const Expanded(
          child: LabOrdersLoadingList(itemCount: 5),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style:
                  GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.sora(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(userLabOrdersProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.labPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: AppColors.labPrimary,
      onRefresh: () async {},
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.labPrimaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.biotech_rounded,
                          size: 48, color: AppColors.labPrimary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Lab Orders Yet',
                      style: GoogleFonts.sora(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You haven't booked any lab tests yet.\nBook now to get tested at home!",
                      style: GoogleFonts.sora(
                          fontSize: 14, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.push('/lab/book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.labPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Book Lab Test',
                          style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
      BuildContext context, WidgetRef ref, List<LabOrderModel> orders) {
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
        itemBuilder: (context, index) {
          final order = orders[index];
          return LabOrderCard(
            order: order,
            onTap: () => context.push('/lab/order/${order.orderId}'),
          );
        },
      ),
    );
  }
}
