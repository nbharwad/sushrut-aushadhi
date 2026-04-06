import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';

class AdminStatusChip extends StatelessWidget {
  final OrderStatus status;
  final bool showIcon;

  const AdminStatusChip({
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

  _AdminStatusConfig _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _AdminStatusConfig(
          label: 'Pending',
          backgroundColor: AppColors.statusPending,
          icon: Icons.hourglass_top_rounded,
        );
      case OrderStatus.confirmed:
        return _AdminStatusConfig(
          label: 'Confirmed',
          backgroundColor: AppColors.statusConfirmed,
          icon: Icons.check_circle_outline,
        );
      case OrderStatus.preparing:
        return _AdminStatusConfig(
          label: 'Preparing',
          backgroundColor: AppColors.statusPreparing,
          icon: Icons.inventory_2_outlined,
        );
      case OrderStatus.outForDelivery:
        return _AdminStatusConfig(
          label: 'Out for Delivery',
          backgroundColor: AppColors.statusOutForDelivery,
          icon: Icons.local_shipping_outlined,
        );
      case OrderStatus.delivered:
        return _AdminStatusConfig(
          label: 'Delivered',
          backgroundColor: AppColors.statusDelivered,
          icon: Icons.task_alt,
        );
      case OrderStatus.cancelled:
        return _AdminStatusConfig(
          label: 'Cancelled',
          backgroundColor: AppColors.statusCancelled,
          icon: Icons.cancel_outlined,
        );
    }
  }
}

class _AdminStatusConfig {
  final String label;
  final Color backgroundColor;
  final IconData? icon;

  _AdminStatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.icon,
  });
}
