import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AdminStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const AdminStatsCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (valueColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: valueColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminStatsRow extends StatelessWidget {
  final List<AdminStatsCardData> stats;

  const AdminStatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .map((stat) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: stat.isLast ? 0 : 8,
                  ),
                  child: AdminStatsCard(
                    label: stat.label,
                    value: stat.value,
                    valueColor: stat.color,
                    icon: stat.icon,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class AdminStatsCardData {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final bool isLast;

  const AdminStatsCardData({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.isLast = false,
  });
}
