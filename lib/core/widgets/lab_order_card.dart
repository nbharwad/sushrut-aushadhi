import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/lab_order_model.dart';

class LabStatusChip extends StatelessWidget {
  final LabOrderStatus status;
  final bool showIcon;

  const LabStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.backgroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.backgroundColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && config.icon != null) ...[
            Icon(
              config.icon,
              size: 12,
              color: config.backgroundColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            config.label,
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  _LabStatusConfig _getStatusConfig(LabOrderStatus status) {
    switch (status) {
      case LabOrderStatus.pending:
        return _LabStatusConfig(
          label: 'Pending',
          backgroundColor: Colors.orange,
          icon: Icons.hourglass_top_rounded,
        );
      case LabOrderStatus.sampleCollected:
        return _LabStatusConfig(
          label: 'Sample Collected',
          backgroundColor: Colors.blue,
          icon: Icons.bloodtype_rounded,
        );
      case LabOrderStatus.processing:
        return _LabStatusConfig(
          label: 'Processing',
          backgroundColor: Colors.purple,
          icon: Icons.science_rounded,
        );
      case LabOrderStatus.completed:
        return _LabStatusConfig(
          label: 'Completed',
          backgroundColor: Colors.green,
          icon: Icons.check_circle_rounded,
        );
      case LabOrderStatus.cancelled:
        return _LabStatusConfig(
          label: 'Cancelled',
          backgroundColor: Colors.red,
          icon: Icons.cancel_rounded,
        );
    }
  }
}

class _LabStatusConfig {
  final String label;
  final Color backgroundColor;
  final IconData? icon;

  _LabStatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.icon,
  });
}

class LabOrderCard extends StatelessWidget {
  final LabOrderModel order;
  final VoidCallback? onTap;

  const LabOrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildTestsList(),
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.labPrimaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.biotech_rounded,
            color: AppColors.labPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SA-LB-${order.orderId.substring(0, 4).toUpperCase()}',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(order.createdAt),
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        LabStatusChip(status: order.status),
      ],
    );
  }

  Widget _buildTestsList() {
    final displayTests = order.tests.take(2).toList();
    final remaining = order.tests.length - displayTests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayTests.map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppColors.labPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      test.testName,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildFooter() {
    return Row(
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.labPrimary,
              ),
            ),
          ],
        ),
        if (order.status == LabOrderStatus.pending)
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Cancel',
              style:
                  GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
