import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/lab_order_model.dart';
import '../constants/app_colors.dart';

class AdminLabFilterChips extends StatelessWidget {
  final String? selectedFilter;
  final ValueChanged<String?> onFilterSelected;
  final Map<String, int>? counts;

  const AdminLabFilterChips({
    super.key,
    this.selectedFilter,
    required this.onFilterSelected,
    this.counts,
  });

  static const List<_LabFilterOption> _filters = [
    _LabFilterOption(key: 'all', label: 'All'),
    _LabFilterOption(key: 'pending', label: 'Pending'),
    _LabFilterOption(key: 'sampleCollected', label: 'Sample Collected'),
    _LabFilterOption(key: 'processing', label: 'Processing'),
    _LabFilterOption(key: 'completed', label: 'Completed'),
    _LabFilterOption(key: 'cancelled', label: 'Cancelled'),
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
                            : AppColors.labPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppColors.labPrimary,
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
              selectedColor: AppColors.labPrimary,
              labelStyle: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.labPrimary : Colors.grey.shade300,
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

  static LabOrderStatus? getStatusFromFilter(String? filter) {
    if (filter == null || filter == 'all') return null;
    return LabOrderStatus.fromString(filter);
  }
}

class _LabFilterOption {
  final String key;
  final String label;

  const _LabFilterOption({
    required this.key,
    required this.label,
  });
}
