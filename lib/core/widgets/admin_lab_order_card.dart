import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/lab_order_model.dart';
import 'admin_lab_status_chip.dart';

class AdminLabOrderCard extends StatelessWidget {
  final LabOrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onWhatsAppTap;

  const AdminLabOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onCallTap,
    this.onWhatsAppTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8ECE7)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(),
            _buildCustomerSection(),
            _buildTestsSection(),
            if (order.status != LabOrderStatus.completed &&
                order.status != LabOrderStatus.cancelled)
              _buildStatusUpdateRow(),
            _buildCardFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFF3EF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SA-LB-${order.orderId.substring(0, 4).toUpperCase()}',
                  style: GoogleFonts.sora(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(order.createdAt),
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          AdminLabStatusChip(status: order.status),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFF3EF))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF00897B),
            child: Text(
              order.userName.isNotEmpty ? order.userName[0].toUpperCase() : 'U',
              style: GoogleFonts.sora(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  order.userPhone,
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (order.homeCollectionAddress != null &&
                    order.homeCollectionAddress!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.homeCollectionAddress!,
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
          ),
          if (onCallTap != null)
            _ActionButton(
              icon: Icons.call_rounded,
              color: AppColors.primary,
              onTap: onCallTap!,
            ),
          if (onWhatsAppTap != null) ...[
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF1B8E3E),
              onTap: onWhatsAppTap!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestsSection() {
    final displayTests = order.tests.take(3).toList();
    final remaining = order.testCount - displayTests.length;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.labPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${order.testCount} test${order.testCount == 1 ? '' : 's'}',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...displayTests.map<Widget>((test) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00897B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        test.testName,
                        style: GoogleFonts.sora(fontSize: 12),
                      ),
                    ),
                    Text(
                      '\u20B9${test.price.toStringAsFixed(0)}',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
          if (remaining > 0)
            Text(
              '+$remaining more test${remaining > 1 ? 's' : ''}',
              style: GoogleFonts.sora(
                fontSize: 11,
                color: AppColors.labPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateRow() {
    final nextStatuses = _getNextStatuses(order.status);
    if (nextStatuses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEFF3EF)),
          bottom: BorderSide(color: Color(0xFFEFF3EF)),
        ),
      ),
      child: Row(
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
              spacing: 8,
              runSpacing: 6,
              children: nextStatuses
                  .map(
                    (status) => _StatusChipButton(
                      label: status.displayName,
                      color: _getStatusColor(status),
                      onTap: () {},
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter() {
    final isPaid = order.paymentStatus == 'paid';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.sora(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '\u20B9${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.labPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isPaid ? 'Paid' : 'Pending Payment',
              style: GoogleFonts.sora(
                color: isPaid ? AppColors.primary : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LabOrderStatus> _getNextStatuses(LabOrderStatus current) {
    switch (current) {
      case LabOrderStatus.pending:
        return [LabOrderStatus.sampleCollected, LabOrderStatus.cancelled];
      case LabOrderStatus.sampleCollected:
        return [LabOrderStatus.processing, LabOrderStatus.cancelled];
      case LabOrderStatus.processing:
        return [LabOrderStatus.completed];
      case LabOrderStatus.completed:
        return [];
      case LabOrderStatus.cancelled:
        return [];
    }
  }

  Color _getStatusColor(LabOrderStatus status) {
    switch (status) {
      case LabOrderStatus.pending:
        return AppColors.statusPending;
      case LabOrderStatus.sampleCollected:
        return AppColors.labPrimary;
      case LabOrderStatus.processing:
        return AppColors.statusPreparing;
      case LabOrderStatus.completed:
        return AppColors.statusDelivered;
      case LabOrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
