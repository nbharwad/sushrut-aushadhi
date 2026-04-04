import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/remote_config_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/whatsapp_service.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOrder = 'newest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(allOrdersProvider);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _onSortChanged(String sortOrder) {
    setState(() {
      _sortOrder = sortOrder;
    });
  }

  void _jumpToTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < 6) {
      _tabController.animateTo(tabIndex);
    }
  }

  List<OrderModel> _filterAndSortOrders(List<OrderModel> orders) {
    var filtered = orders.where((order) {
      if (_searchQuery.isEmpty) return true;
      return order.orderId.toLowerCase().contains(_searchQuery) ||
          order.userName.toLowerCase().contains(_searchQuery) ||
          order.userPhone.contains(_searchQuery);
    }).toList();

    switch (_sortOrder) {
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'amount_high':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'amount_low':
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminFromClaimsProvider);
    final isAdmin = isAdminAsync.valueOrNull ?? false;
    final ordersAsync = ref.watch(allOrdersProvider);
    final stats = ordersAsync.maybeWhen(
      data: _AdminOrderStats.fromOrders,
      orElse: _AdminOrderStats.empty,
    );

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/home'),
          ),
          title: Text(
            'Access Denied',
            style: GoogleFonts.sora(color: Colors.white),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Admin Access Required',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have permission to view this page.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildCustomAppBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _buildStatsGrid(stats),
            ),
            _buildLabNavRow(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchAndSort(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildTabBar(stats),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(ordersAsync, 'pending'),
                  _buildOrderList(ordersAsync, 'confirmed'),
                  _buildOrderList(ordersAsync, 'preparing'),
                  _buildOrderList(ordersAsync, 'outForDelivery'),
                  _buildOrderList(ordersAsync, 'delivered'),
                  _buildOrderList(ordersAsync, 'all'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top > 0 ? 8 : 16,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Orders',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sushrut Aushadhi store operations',
                  style: GoogleFonts.sora(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _onRefresh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(_AdminOrderStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 4
            : width >= 600
                ? 2
                : 2;
        final spacing = 12.0;
        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        final cards = [
          _AdminStatCardData(
            label: 'Pending',
            value: '${stats.pendingCount}',
            color: const Color(0xFFFF9800),
            icon: Icons.pending_actions_rounded,
            tabIndex: 0,
          ),
          _AdminStatCardData(
            label: 'Confirmed',
            value: '${stats.confirmedCount}',
            color: const Color(0xFF185FA5),
            icon: Icons.inventory_2_rounded,
            tabIndex: 1,
          ),
          _AdminStatCardData(
            label: 'Delivered Today',
            value: '${stats.deliveredTodayCount}',
            color: AppColors.primary,
            icon: Icons.local_shipping_rounded,
            tabIndex: 4,
          ),
          _AdminStatCardData(
            label: 'Today Revenue',
            value: 'Rs ${stats.todayRevenue.toStringAsFixed(0)}',
            color: const Color(0xFF0E8E62),
            icon: Icons.payments_rounded,
            tabIndex: null,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: _buildStatCard(card)))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_AdminStatCardData card) {
    final isClickable = card.tabIndex != null;
    final cardWidget = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(card.icon, color: card.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    color: card.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isClickable) return cardWidget;

    return InkWell(
      onTap: () => _jumpToTab(card.tabIndex!),
      borderRadius: BorderRadius.circular(16),
      child: cardWidget,
    );
  }

  Widget _buildLabNavRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _navChip('Lab Orders', Icons.science_outlined, () => context.push('/admin/lab-orders'), const Color(0xFF0277BD)),
          const SizedBox(width: 8),
          _navChip('Lab Packages', Icons.inventory_2_outlined, () => context.push('/admin/lab-packages'), const Color(0xFF6A1B9A)),
          const SizedBox(width: 8),
          _navChip('Manage Tests', Icons.biotech_outlined, () => context.push('/admin/lab-tests'), const Color(0xFF00838F)),
          const SizedBox(width: 8),
          _navChip('Prescriptions', Icons.description_outlined, () => context.push('/admin/prescriptions'), const Color(0xFFE65100)),
        ],
      ),
    );
  }

  Widget _navChip(String label, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8ECE7)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                hintStyle: GoogleFonts.sora(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: GoogleFonts.sora(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8ECE7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOrder,
              icon: const Icon(Icons.sort, color: AppColors.textSecondary, size: 20),
              style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Newest')),
                DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                DropdownMenuItem(value: 'amount_high', child: Text('Amount ↑')),
                DropdownMenuItem(value: 'amount_low', child: Text('Amount ↓')),
              ],
              onChanged: (value) {
                if (value != null) _onSortChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(_AdminOrderStats stats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.sora(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.w600),
        tabs: [
          _AdminCountTab(label: 'Pending', count: stats.pendingCount),
          _AdminCountTab(label: 'Confirmed', count: stats.confirmedCount),
          _AdminCountTab(label: 'Preparing', count: stats.preparingCount),
          _AdminCountTab(label: 'Out for Delivery', count: stats.outForDeliveryCount),
          _AdminCountTab(label: 'Delivered', count: stats.deliveredCount),
          _AdminCountTab(label: 'All', count: stats.totalCount),
        ],
      ),
    );
  }

  Widget _buildOrderList(AsyncValue<List<OrderModel>> ordersAsync, String status) {
    return ordersAsync.when(
      data: (orders) {
        var filteredOrders = status == 'all'
            ? orders
            : orders.where((order) => order.status.name == status).toList();
        
        filteredOrders = _filterAndSortOrders(filteredOrders);

        if (filteredOrders.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          color: Colors.white,
          backgroundColor: const Color(0xFF0F6E56),
          onRefresh: _onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) => _buildOrderCard(filteredOrders[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorStateWidget(
            message: 'Could not load orders.\n$error',
            onRetry: _onRefresh,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    final widget = switch (status) {
      'pending' => const EmptyStateWidget(
          emoji: '⏳',
          title: 'No Pending Orders',
          subtitle: 'There are no orders waiting for confirmation.',
        ),
      'confirmed' => const EmptyStateWidget(
          emoji: '📋',
          title: 'No Confirmed Orders',
          subtitle: 'There are no confirmed orders to prepare.',
        ),
      'delivered' => const EmptyStateWidget(
          emoji: '🚚',
          title: 'No Delivered Orders',
          subtitle: 'There are no delivered orders yet.',
        ),
      _ => const EmptyStateWidget(
          emoji: '📦',
          title: 'No Orders',
          subtitle: 'There are no orders yet.',
        ),
    };

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF0F6E56),
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [SizedBox(height: MediaQuery.of(context).size.height * 0.45, child: widget)],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(order),
          _buildCustomerSection(order),
          _buildItemsList(order),
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            _buildStatusUpdateRow(order),
          _buildCardFooter(order),
        ],
      ),
    );
  }

  Widget _buildCardHeader(OrderModel order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFF3EF))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          final statusChip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Helpers.getStatusColor(order.status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              order.status.displayName,
              style: GoogleFonts.sora(
                color: Helpers.getStatusColor(order.status),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SA-${order.orderId.substring(0, 4).toUpperCase()}',
                  style: GoogleFonts.sora(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getTimeAgo(order.createdAt),
                        style: GoogleFonts.sora(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    statusChip,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  'SA-${order.orderId.substring(0, 4).toUpperCase()}',
                  style: GoogleFonts.sora(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                _getTimeAgo(order.createdAt),
                style: GoogleFonts.sora(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              statusChip,
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerSection(OrderModel order) {
    final initials = order.userName.isNotEmpty
        ? order.userName
            .split(' ')
            .map((segment) => segment.isNotEmpty ? segment[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'CU';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFF3EF))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actionButtons = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionIconButton(
                icon: Icons.call_rounded,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onTap: () => _launchUrl('tel:${order.userPhone}'),
              ),
              _ActionIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                backgroundColor: const Color(0xFFE8F5E9),
                foregroundColor: const Color(0xFF1B8E3E),
                onTap: () async {
                  final itemNames =
                      order.items.map((item) => item.medicineName).toList();
                  try {
                    await WhatsAppService.sendOrderUpdate(
                      customerPhone: order.userPhone,
                      orderId: order.orderId,
                      customerName: order.userName,
                      status: order.status.name,
                      totalAmount: order.totalAmount,
                      itemNames: itemNames,
                      storePhone: RemoteConfigService.storePhone,
                    );
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp is not available on this device'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
              if (order.prescriptionUrl != null && order.prescriptionUrl!.isNotEmpty)
                _ActionIconButton(
                  icon: Icons.description_outlined,
                  backgroundColor: const Color(0xFFF3E5F5),
                  foregroundColor: const Color(0xFF7B1FA2),
                  onTap: () => _showPrescriptionViewer(order.prescriptionUrl!),
                ),
            ],
          );

          final customerDetails = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.userName.isNotEmpty ? order.userName : 'Customer',
                  style: GoogleFonts.sora(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.userPhone,
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (!order.deliveryAddress.isEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.deliveryAddress.toDisplayString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          );

          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    customerDetails,
                  ],
                ),
                const SizedBox(height: 12),
                actionButtons,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  initials,
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              customerDetails,
              const SizedBox(width: 12),
              Flexible(child: Align(alignment: Alignment.topRight, child: actionButtons)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsList(OrderModel order) {
    final displayItems = order.items.take(3).toList();
    final remainingCount = order.items.length - displayItems.length;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
            style: GoogleFonts.sora(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...displayItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.medicineName} x ${item.quantity}',
                      style: GoogleFonts.sora(fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (remainingCount > 0)
            Text(
              '+$remainingCount more items',
              style: GoogleFonts.sora(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateRow(OrderModel order) {
    final nextStatuses = _getNextStatuses(order.status);
    if (nextStatuses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPDATE STATUS',
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nextStatuses
                .map(
                  (status) => InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _updateOrderStatus(order.orderId, status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status.displayName,
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter(OrderModel order) {
    final actionButtons = <Widget>[
      if (order.status != OrderStatus.cancelled &&
          order.status != OrderStatus.delivered)
        OutlinedButton(
          onPressed: () => _showRejectConfirmDialog(order.orderId),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: Text('Reject', style: GoogleFonts.sora(fontSize: 12)),
        ),
      if (order.status != OrderStatus.cancelled &&
          order.status != OrderStatus.delivered)
        ElevatedButton(
          onPressed: () => _showConfirmDialog(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(
            order.status == OrderStatus.pending ? 'Confirm' : 'Update',
            style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: Rs ${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (order.prescriptionUrl != null && order.prescriptionUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Prescription attached',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          );

          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                totalBlock,
                if (actionButtons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: totalBlock),
              if (actionButtons.isNotEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
            ],
          );
        },
      ),
    );
  }

  List<OrderStatus> _getNextStatuses(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.preparing, OrderStatus.outForDelivery];
      case OrderStatus.preparing:
        return [OrderStatus.outForDelivery];
      case OrderStatus.outForDelivery:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return [];
    }
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus, {String? updatedBy}) async {
    try {
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      
      final orderData = orderDoc.data()!;
      final currentStatus = orderData['status'] ?? 'pending';
      final userId = orderData['userId'] ?? '';
      
      final existingHistory = (orderData['statusHistory'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      existingHistory.add({
        'status': newStatus.name,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy ?? 'admin',
        'role': 'admin',
      });
      
      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': existingHistory,
      };
      
      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }
      
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(updateData);
      
      if (userId.isNotEmpty && currentStatus != newStatus.name) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': 'Order Status Updated',
          'body': 'Your order has been ${newStatus.displayName.toLowerCase()}.',
          'type': 'order_status',
          'orderId': orderId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated to ${newStatus.displayName}',
            style: GoogleFonts.sora(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $error', style: GoogleFonts.sora()),
        ),
      );
    }
  }

  void _showConfirmDialog(OrderModel order) {
    final nextStatuses = _getNextStatuses(order.status);
    if (nextStatuses.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Confirm Status',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: nextStatuses
              .map(
                (status) => ListTile(
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

  void _showRejectConfirmDialog(String orderId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            child: Text('Reject', style: GoogleFonts.sora(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionViewer(String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(dialogContext).padding.top + 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}

class _AdminCountTab extends StatelessWidget {
  const _AdminCountTab({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: foregroundColor),
      ),
    );
  }
}

class _AdminStatCardData {
  const _AdminStatCardData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.tabIndex,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final int? tabIndex;
}

class _AdminOrderStats {
  const _AdminOrderStats({
    required this.totalCount,
    required this.pendingCount,
    required this.confirmedCount,
    required this.preparingCount,
    required this.outForDeliveryCount,
    required this.deliveredCount,
    required this.deliveredTodayCount,
    required this.todayRevenue,
  });

  final int totalCount;
  final int pendingCount;
  final int confirmedCount;
  final int preparingCount;
  final int outForDeliveryCount;
  final int deliveredCount;
  final int deliveredTodayCount;
  final double todayRevenue;

  factory _AdminOrderStats.fromOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var pendingCount = 0;
    var confirmedCount = 0;
    var preparingCount = 0;
    var outForDeliveryCount = 0;
    var deliveredCount = 0;
    var deliveredTodayCount = 0;
    var todayRevenue = 0.0;

    for (final order in orders) {
      if (order.status == OrderStatus.pending) {
        pendingCount++;
      }
      if (order.status == OrderStatus.confirmed) {
        confirmedCount++;
      }
      if (order.status == OrderStatus.preparing) {
        preparingCount++;
      }
      if (order.status == OrderStatus.outForDelivery) {
        outForDeliveryCount++;
      }
      if (order.status == OrderStatus.delivered) {
        deliveredCount++;
        final deliveredDate = order.deliveredAt ?? order.createdAt;
        final orderDay = DateTime(
          deliveredDate.year,
          deliveredDate.month,
          deliveredDate.day,
        );
        if (orderDay == today) {
          deliveredTodayCount++;
          todayRevenue += order.totalAmount;
        }
      }
    }

    return _AdminOrderStats(
      totalCount: orders.length,
      pendingCount: pendingCount,
      confirmedCount: confirmedCount,
      preparingCount: preparingCount,
      outForDeliveryCount: outForDeliveryCount,
      deliveredCount: deliveredCount,
      deliveredTodayCount: deliveredTodayCount,
      todayRevenue: todayRevenue,
    );
  }

  static _AdminOrderStats empty() {
    return const _AdminOrderStats(
      totalCount: 0,
      pendingCount: 0,
      confirmedCount: 0,
      preparingCount: 0,
      outForDeliveryCount: 0,
      deliveredCount: 0,
      deliveredTodayCount: 0,
      todayRevenue: 0,
    );
  }
}
