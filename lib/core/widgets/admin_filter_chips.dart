import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../constants/app_colors.dart';

class AdminFilterChips extends StatelessWidget {
  final String? selectedFilter;
  final ValueChanged<String?> onFilterSelected;
  final Map<String, int>? counts;

  const AdminFilterChips({
    super.key,
    this.selectedFilter,
    required this.onFilterSelected,
    this.counts,
  });

  static const List<_AdminFilterOption> _filters = [
    _AdminFilterOption(key: 'all', label: 'All'),
    _AdminFilterOption(key: 'pending', label: 'Pending'),
    _AdminFilterOption(key: 'confirmed', label: 'Confirmed'),
    _AdminFilterOption(key: 'preparing', label: 'Preparing'),
    _AdminFilterOption(key: 'outForDelivery', label: 'Out for Delivery'),
    _AdminFilterOption(key: 'delivered', label: 'Delivered'),
    _AdminFilterOption(key: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = selectedFilter == filter.key ||
              (selectedFilter == null && filter.key == 'all');
          final count = counts?[filter.key];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filter.label),
                  if (count != null && count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                onFilterSelected(
                  filter.key == 'all' ? null : filter.key,
                );
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              showCheckmark: false,
              elevation: 0,
              pressElevation: 2,
            ),
          );
        }).toList(),
      ),
    );
  }

  static OrderStatus? getStatusFromFilter(String? filter) {
    if (filter == null || filter == 'all') return null;
    return OrderStatus.fromString(filter);
  }
}

class _AdminFilterOption {
  final String key;
  final String label;

  const _AdminFilterOption({
    required this.key,
    required this.label,
  });
}
