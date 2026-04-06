import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/lab_order_model.dart';
import '../../../../models/lab_package_model.dart';

enum SelectionMode { packages, individualTests }

class TestSelector extends StatefulWidget {
  final List<LabTestModel> tests;
  final List<LabPackageModel> packages;
  final SelectionMode initialMode;
  final Function(SelectionMode) onModeChanged;
  final Function(LabPackageModel?) onPackageSelected;
  final Function(Map<String, bool>) onTestsSelected;
  final LabPackageModel? selectedPackage;
  final Map<String, bool> selectedTests;

  const TestSelector({
    super.key,
    required this.tests,
    required this.packages,
    required this.initialMode,
    required this.onModeChanged,
    required this.onPackageSelected,
    required this.onTestsSelected,
    this.selectedPackage,
    required this.selectedTests,
  });

  @override
  State<TestSelector> createState() => _TestSelectorState();
}

class _TestSelectorState extends State<TestSelector> {
  late SelectionMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final padding = screenWidth * 0.04;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: padding),
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
              _buildModeToggle(padding),
              Divider(height: 1),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentMode == SelectionMode.packages
                    ? _buildPackagesSection(padding, screenWidth)
                    : _buildTestsSection(padding),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggle(double padding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isVeryCompact = screenWidth < 320;

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.02),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegment(
            label: 'Packages',
            index: 0,
            icon: Icons.inventory_2_rounded,
            isCompact: isCompact,
            isVeryCompact: isVeryCompact,
          ),
          const SizedBox(width: 4),
          _buildSegment(
            label: 'Individual Tests',
            index: 1,
            icon: Icons.science_rounded,
            isCompact: isCompact,
            isVeryCompact: isVeryCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required int index,
    required IconData icon,
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final isPackagesSelected = _currentMode == SelectionMode.packages;
    final isSelected = index == 0 ? isPackagesSelected : !isPackagesSelected;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(
          index == 0 ? SelectionMode.packages : SelectionMode.individualTests,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: isVeryCompact ? 8 : 10,
            horizontal: isVeryCompact ? 4 : (isCompact ? 6 : 8),
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isVeryCompact ? 14 : 16,
                color:
                    isSelected ? AppColors.labPrimary : AppColors.textSecondary,
              ),
              SizedBox(width: isVeryCompact ? 2 : 4),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    fontSize: isVeryCompact ? 10 : (isCompact ? 11.5 : 12.5),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.labPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchMode(SelectionMode mode) {
    if (_currentMode != mode) {
      setState(() => _currentMode = mode);
      widget.onModeChanged(mode);
    }
  }

  Widget _buildPackagesSection(
      [double padding = 16, double screenWidth = 360]) {
    if (widget.packages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'No packages available',
      );
    }

    final cardWidth = screenWidth * 0.45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
          child: Text(
            'Select a package',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            itemCount: widget.packages.length,
            itemBuilder: (context, index) {
              final package = widget.packages[index];
              return _PackageCard(
                cardWidth: cardWidth,
                package: package,
                isSelected: widget.selectedPackage?.id == package.id,
                onTap: () {
                  if (_currentMode != SelectionMode.packages) {
                    setState(() => _currentMode = SelectionMode.packages);
                    widget.onModeChanged(SelectionMode.packages);
                  }
                  widget.onPackageSelected(package);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTestsSection([double padding = 16]) {
    if (widget.tests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.science_outlined,
        message: 'No tests available',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
          child: Text(
            'Select tests (multi-select)',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: padding),
          itemCount: widget.tests.length,
          itemBuilder: (context, index) {
            final test = widget.tests[index];
            final isSelected = widget.selectedTests[test.id] ?? false;
            return _TestTile(
              test: test,
              isSelected: isSelected,
              onChanged: (selected) {
                final newSelection =
                    Map<String, bool>.from(widget.selectedTests);
                newSelection[test.id] = selected;
                widget.onTestsSelected(newSelection);
              },
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.sora(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final LabPackageModel package;
  final bool isSelected;
  final VoidCallback onTap;
  final double cardWidth;

  const _PackageCard({
    super.key,
    required this.package,
    required this.isSelected,
    required this.onTap,
    this.cardWidth = 180,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth * 0.45;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.labPrimaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.labPrimary : const Color(0xFFE8ECE7),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.labPrimary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.labPrimary
                        : AppColors.labPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.labPrimary,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.labPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              package.name,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${package.testCount} tests',
              style: GoogleFonts.sora(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (package.hasDiscount) ...[
                  Text(
                    '\u20B9${package.originalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '\u20B9${package.price.toStringAsFixed(0)}',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.labPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TestTile extends StatelessWidget {
  final LabTestModel test;
  final bool isSelected;
  final Function(bool) onChanged;

  const _TestTile({
    required this.test,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.labPrimaryLight : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.labPrimary : const Color(0xFFE8ECE7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.labPrimary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.labPrimary
                      : const Color(0xFFBDBDBD),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.name,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${test.sampleType} • ${test.tatHours}h report',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\u20B9${test.price.toStringAsFixed(0)}',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.labPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
