import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../models/order_model.dart';
import '../../../providers/admin_order_actions_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../services/remote_config_service.dart';
import '../../../services/whatsapp_service.dart';

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
  String _sortOrder = 'newest';
  String _deliveredDateFilter = 'today';

  _OrderStats _calculateStats(List<OrderModel> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int pending = 0;
    int confirmed = 0;
    int deliveredToday = 0;
    double revenueToday = 0;

    for (final order in orders) {
      if (order.status == OrderStatus.pending) pending++;
      if (order.status == OrderStatus.confirmed) confirmed++;
      if (order.status == OrderStatus.delivered) {
        final deliveredDate = order.deliveredAt ?? order.createdAt;
        if (deliveredDate.isAfter(today)) {
          deliveredToday++;
          revenueToday += order.totalAmount;
        }
      }
    }

    return _OrderStats(
      pending: pending,
      confirmed: confirmed,
      deliveredToday: deliveredToday,
      revenueToday: revenueToday,
    );
  }

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
    var filteredByStatus = _selectedStatus == 'all'
        ? orders
        : orders
            .where((order) => order.status.name == _selectedStatus)
            .toList();

    // Date filter for Delivered tab
    if (_selectedStatus == 'delivered' && _deliveredDateFilter != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      filteredByStatus = filteredByStatus.where((order) {
        if (order.status != OrderStatus.delivered) return true;
        final deliveredDate = order.deliveredAt ?? order.createdAt;
        final orderDay = DateTime(
          deliveredDate.year,
          deliveredDate.month,
          deliveredDate.day,
        );

        switch (_deliveredDateFilter) {
          case 'today':
            return orderDay.isAtSameMomentAs(today);
          case 'week':
            return deliveredDate
                .isAfter(today.subtract(const Duration(days: 7)));
          case 'month':
            return deliveredDate
                .isAfter(today.subtract(const Duration(days: 30)));
          default:
            return true;
        }
      }).toList();
    }

    List<OrderModel> sorted;
    switch (_sortOrder) {
      case 'oldest':
        sorted = [...filteredByStatus]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'amount_high':
        sorted = [...filteredByStatus]
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'amount_low':
        sorted = [...filteredByStatus]
          ..sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'newest':
      default:
        sorted = [...filteredByStatus]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

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

  Color? _getPendingAgeColor(OrderModel order) {
    if (order.status != OrderStatus.pending) return null;
    final age = DateTime.now().difference(order.createdAt);
    if (age.inMinutes > 60) return AppColors.error;
    if (age.inMinutes > 30) return const Color(0xFFFFA000);
    return null;
  }

  String _getPendingAgeLabel(OrderModel order) {
    if (order.status != OrderStatus.pending) return '';
    final age = DateTime.now().difference(order.createdAt);
    if (age.inHours > 0) return '${age.inHours}h';
    return '${age.inMinutes}m';
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
    final stats = _calculateStats(pageState.orders);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            if (!pageState.isInitialLoading || pageState.hasLoadedOnce)
              _buildStatsRow(stats),
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
                physics: const BouncingScrollPhysics(),
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
            if (_selectedStatus == 'delivered')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildDateChip('All', 'all'),
                      _buildDateChip('Today', 'today'),
                      _buildDateChip('Week', 'week'),
                      _buildDateChip('Month', 'month'),
                    ],
                  ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort orders',
            onSelected: (value) => setState(() => _sortOrder = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    if (_sortOrder == 'newest')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Text('Newest first', style: GoogleFonts.sora()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    if (_sortOrder == 'oldest')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Text('Oldest first', style: GoogleFonts.sora()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount_high',
                child: Row(
                  children: [
                    if (_sortOrder == 'amount_high')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Text('Amount ↑ (High to Low)', style: GoogleFonts.sora()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount_low',
                child: Row(
                  children: [
                    if (_sortOrder == 'amount_low')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Text('Amount ↓ (Low to High)', style: GoogleFonts.sora()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(_OrderStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.inventory_2_outlined,
              label: 'Pending',
              value: stats.pending.toString(),
              color: Colors.orange,
              onTap: () => setState(() => _selectedStatus = 'pending'),
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_outline,
              label: 'Confirmed',
              value: stats.confirmed.toString(),
              color: Colors.blue,
              onTap: () => setState(() => _selectedStatus = 'confirmed'),
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.local_shipping_outlined,
              label: 'Today',
              value: stats.deliveredToday.toString(),
              color: Colors.green,
              onTap: () => setState(() => _selectedStatus = 'delivered'),
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatItem(
              icon: Icons.attach_money,
              label: 'Revenue',
              value: '₹${stats.revenueToday.toStringAsFixed(0)}',
              color: AppColors.primary,
            ),
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

  Widget _buildDateChip(String label, String value) {
    final isSelected = _deliveredDateFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _deliveredDateFilter = value),
        selectedColor: AppColors.primary.withOpacity(0.2),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;

          if (isWideScreen) {
            return GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount:
                  visibleOrders.length + (pageState.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == visibleOrders.length) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                return _buildOrderTile(context, visibleOrders[index], true);
              },
            );
          }

          return ListView.separated(
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
              return _buildOrderTile(context, visibleOrders[index], false);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderTile(
      BuildContext context, OrderModel order, bool isWideScreen) {
    final statusColor = Helpers.getStatusColor(order.status);
    final ageColor = _getPendingAgeColor(order);
    final shortId = order.orderId.length >= 4
        ? order.orderId.substring(0, 4).toUpperCase()
        : order.orderId.toUpperCase();

    final initials = order.userName.isNotEmpty
        ? order.userName
            .split(' ')
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0])
            .join()
            .toUpperCase()
        : '?';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/admin/order/${order.orderId}'),
      child: Container(
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
            // Colored top border per status
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                      if (ageColor != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ageColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: ageColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 10,
                                color: ageColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _getPendingAgeLabel(order),
                                style: GoogleFonts.sora(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: ageColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          initials,
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.userName.isNotEmpty
                                  ? order.userName
                                  : 'Customer',
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.userPhone,
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (!order.deliveryAddress.isEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      order.deliveryAddress.toDisplayString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.sora(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${order.itemCount} items',
                              style: GoogleFonts.sora(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs ${order.totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDate(order.createdAt),
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _QuickActionButton(
                                icon: Icons.call_rounded,
                                color: AppColors.primary,
                                onTap: () =>
                                    _launchUrl('tel:${order.userPhone}'),
                              ),
                              const SizedBox(width: 6),
                              _QuickActionButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                color: const Color(0xFF1B8E3E),
                                onTap: () => _sendWhatsApp(order),
                              ),
                              if (order.prescriptionUrl != null &&
                                  order.prescriptionUrl!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                _QuickActionButton(
                                  icon: Icons.description_outlined,
                                  color: const Color(0xFF7B1FA2),
                                  onTap: () => _showPrescriptionViewer(
                                      order.prescriptionUrl!),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (order.status != OrderStatus.delivered &&
                order.status != OrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F4F0)),
              const SizedBox(height: 8),
              _buildStatusUpdateRow(order),
              const SizedBox(height: 10),
              _buildCardFooter(order),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsApp(OrderModel order) async {
    try {
      await WhatsAppService.sendOrderUpdate(
        customerPhone: order.userPhone,
        orderId: order.orderId,
        customerName: order.userName,
        status: order.status.name,
        totalAmount: order.totalAmount,
        itemNames: order.items.map((i) => i.medicineName).toList(),
        storePhone: RemoteConfigService.storePhone,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showPrescriptionViewer(String prescriptionUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Prescription'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Image.network(
              prescriptionUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Failed to load prescription'),
              ),
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

  Widget _buildStatusUpdateRow(OrderModel order) {
    final nextStatuses = getNextStatuses(order.status);
    if (nextStatuses.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          'Move to:',
          style: GoogleFonts.sora(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: nextStatuses
                .map(
                  (status) => _StatusChipButton(
                    label: status.displayName,
                    color: Helpers.getStatusColor(status),
                    onTap: () => _showStatusDialog(order, status),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter(OrderModel order) {
    final canAct = order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.delivered;

    if (!canAct) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Text(
            'Rs ${order.totalAmount.toStringAsFixed(0)}',
            style: GoogleFonts.sora(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () => _showRejectConfirmDialog(order.orderId),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Reject',
              style:
                  GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _showConfirmDialog(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            order.status == OrderStatus.pending ? 'Confirm' : 'Update',
            style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showStatusDialog(OrderModel order, OrderStatus newStatus) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsOverflowButtonSpacing: 8,
        title: Text(
          'Update Status',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Change order status to "${newStatus.displayName}"?',
          style: GoogleFonts.sora(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _updateOrderStatus(order.orderId, newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Update', style: GoogleFonts.sora()),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final actionState = ref.read(adminOrderActionsProvider);
    if (actionState.isLoading) return;

    final success = await ref
        .read(adminOrderActionsProvider.notifier)
        .updateOrderStatus(orderId, newStatus);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated to ${newStatus.displayName}',
            style: GoogleFonts.sora(),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      await ref.read(adminOrdersPageProvider.notifier).refresh();
    } else if (mounted) {
      final error = ref.read(adminOrderActionsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to update status',
              style: GoogleFonts.sora()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showRejectConfirmDialog(String orderId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsOverflowButtonSpacing: 8,
        title: Text(
          'Reject Order',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to reject this order?',
          style: GoogleFonts.sora(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _updateOrderStatus(orderId, OrderStatus.cancelled);
            },
            child:
                Text('Reject', style: GoogleFonts.sora(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(OrderModel order) {
    final nextStatuses = getNextStatuses(order.status);
    if (nextStatuses.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Update Status',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: nextStatuses
              .map(
                (status) => ListTile(
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: Helpers.getStatusColor(status),
                  ),
                  title: Text(status.displayName, style: GoogleFonts.sora()),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _updateOrderStatus(order.orderId, status);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _StatusChipButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusChipButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _OrderStats {
  final int pending;
  final int confirmed;
  final int deliveredToday;
  final double revenueToday;

  _OrderStats({
    required this.pending,
    required this.confirmed,
    required this.deliveredToday,
    required this.revenueToday,
  });
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }
    return content;
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
