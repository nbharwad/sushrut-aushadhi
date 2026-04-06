import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/orders_provider.dart';

class AdminMedicineSimpleScreen extends ConsumerStatefulWidget {
  const AdminMedicineSimpleScreen({super.key});

  @override
  ConsumerState<AdminMedicineSimpleScreen> createState() =>
      _AdminMedicineSimpleScreenState();
}

class _AdminMedicineSimpleScreenState
    extends ConsumerState<AdminMedicineSimpleScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      final pageState = ref.read(adminOrdersPageProvider);
      if (!pageState.isLoadingMore &&
          !pageState.isRefreshing &&
          pageState.hasMore) {
        ref.read(adminOrdersPageProvider.notifier).loadNextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(adminOrdersPageProvider.notifier).refresh();
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    final filteredByStatus = _selectedStatus == 'all'
        ? orders
        : orders.where((order) => order.status.name == _selectedStatus).toList();

    final sorted = [...filteredByStatus]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_searchQuery.isEmpty) {
      return sorted;
    }

    final q = _searchQuery.toLowerCase();
    return sorted.where((order) {
      return order.orderId.toLowerCase().contains(q) ||
          order.userName.toLowerCase().contains(q) ||
          order.userPhone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final pageState = ref.watch(adminOrdersPageProvider);

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text('Access Denied', style: GoogleFonts.sora()),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: EmptyStateWidget(
              emoji: '🔒',
              title: 'Admin Access Required',
              subtitle: 'You do not have permission to view this page.',
            ),
          ),
        ),
      );
    }

    final visibleOrders = _filteredOrders(pageState.orders);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search order id, customer, phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE0E6E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE0E6E0)),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('pending', 'Pending'),
                  _buildFilterChip('confirmed', 'Confirmed'),
                  _buildFilterChip('preparing', 'Preparing'),
                  _buildFilterChip('outForDelivery', 'Delivery'),
                  _buildFilterChip('delivered', 'Delivered'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(pageState, visibleOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicine Orders',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Simple admin view for medicine orders',
                  style: GoogleFonts.sora(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () => context.push('/admin/prescription'),
            icon: const Icon(Icons.description_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedStatus = value),
        selectedColor: const Color(0xFF0F6E56),
        labelStyle: GoogleFonts.sora(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFDCE5DC)),
      ),
    );
  }

  Widget _buildBody(
    AdminOrdersPageState pageState,
    List<OrderModel> visibleOrders,
  ) {
    if (pageState.authStatus == AdminAuthStatus.loading ||
        (pageState.isInitialLoading && !pageState.hasLoadedOnce)) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Verifying admin access...'),
          ],
        ),
      );
    }

    if (pageState.authStatus == AdminAuthStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorStateWidget(
            message:
                'Could not verify admin access.\n${pageState.errorMessage ?? ''}',
            onRetry: _onRefresh,
          ),
        ),
      );
    }

    if (pageState.authStatus == AdminAuthStatus.notAdmin) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyStateWidget(
            emoji: '🔒',
            title: 'Access Denied',
            subtitle: 'You do not have permission to view this page.',
          ),
        ),
      );
    }

    if (pageState.errorType != PageErrorType.none && pageState.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorStateWidget(
            message: 'Could not load orders.\n${pageState.errorMessage ?? ''}',
            onRetry: _onRefresh,
          ),
        ),
      );
    }

    if (visibleOrders.isEmpty) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: AppColors.primary,
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            EmptyStateWidget(
              emoji: '📦',
              title: 'No Orders',
              subtitle: 'No medicine orders match the current filter.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: AppColors.primary,
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: visibleOrders.length + (pageState.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == visibleOrders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          return _buildOrderTile(context, visibleOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, OrderModel order) {
    final statusColor = Helpers.getStatusColor(order.status);
    final shortId = order.orderId.length >= 4
        ? order.orderId.substring(0, 4).toUpperCase()
        : order.orderId.toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/admin/order/${order.orderId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3EAE3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'SA-$shortId',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.userName,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.userPhone} • ${order.itemCount} items',
              style: GoogleFonts.sora(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Rs ${order.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final safeHour = hour == 0 ? 12 : hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year  $safeHour:$minute $suffix';
  }
}
