import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/lab_order_model.dart';

class AdminLabStatusChip extends StatelessWidget {
  final LabOrderStatus status;
  final bool showIcon;

  const AdminLabStatusChip({
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
          backgroundColor: AppColors.statusPending,
          icon: Icons.hourglass_top_rounded,
        );
      case LabOrderStatus.sampleCollected:
        return _LabStatusConfig(
          label: 'Sample Collected',
          backgroundColor: AppColors.labPrimary,
          icon: Icons.bloodtype_rounded,
        );
      case LabOrderStatus.processing:
        return _LabStatusConfig(
          label: 'Processing',
          backgroundColor: AppColors.statusPreparing,
          icon: Icons.science_rounded,
        );
      case LabOrderStatus.completed:
        return _LabStatusConfig(
          label: 'Completed',
          backgroundColor: AppColors.statusDelivered,
          icon: Icons.task_alt_rounded,
        );
      case LabOrderStatus.cancelled:
        return _LabStatusConfig(
          label: 'Cancelled',
          backgroundColor: AppColors.statusCancelled,
          icon: Icons.cancel_outlined,
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
