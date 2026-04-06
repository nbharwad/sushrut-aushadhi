import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/lab_order_model.dart';

class TestSummaryCard extends StatelessWidget {
  final String? packageName;
  final List<LabTestItem> selectedItems;
  final List<LabTestModel> allTests;
  final List<String> preselectedTestIds;
  final double totalAmount;
  final bool isPackageBooking;

  const TestSummaryCard({
    super.key,
    this.packageName,
    required this.selectedItems,
    required this.allTests,
    required this.preselectedTestIds,
    required this.totalAmount,
    required this.isPackageBooking,
  });

  List<String> get _displayTests {
    if (isPackageBooking) {
      return preselectedTestIds.map((testId) {
        final matching = allTests.where((t) => t.id == testId).toList();
        return matching.isNotEmpty ? matching.first.name : testId;
      }).toList();
    }
    return selectedItems.map((e) => e.testName).toList();
  }

  @override
  Widget build(BuildContext context) {
    final testCount =
        isPackageBooking ? preselectedTestIds.length : selectedItems.length;
    final displayTests = _displayTests;
    final hasMultipleTests = testCount > 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.labPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPackageBooking
                        ? Icons.inventory_2_rounded
                        : Icons.science_rounded,
                    color: AppColors.labPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPackageBooking
                            ? (packageName ?? 'Lab Package')
                            : 'Selected Tests',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$testCount ${testCount == 1 ? 'test' : 'tests'}',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.labPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\u20B9${totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (displayTests.isNotEmpty) ...[
            const Divider(height: 1),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showTestsBottomSheet(context),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: displayTests
                              .take(3)
                              .map((test) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.labPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            test,
                                            style: GoogleFonts.sora(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      if (hasMultipleTests) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.labPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+${testCount - 3} more',
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.labPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.expand_more_rounded,
                                size: 16,
                                color: AppColors.labPrimary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTestsBottomSheet(BuildContext context) {
    final displayTests = _displayTests;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.labPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.science_rounded,
                      color: AppColors.labPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPackageBooking
                            ? (packageName ?? 'Package Tests')
                            : 'Selected Tests',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${displayTests.length} tests',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...displayTests.map((test) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.labPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          test,
                          style: GoogleFonts.sora(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
