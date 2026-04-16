import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class HomeSectionSwitcher extends StatelessWidget {
  final int activeSection;
  final ValueChanged<int> onSectionChanged;

  const HomeSectionSwitcher({
    super.key,
    required this.activeSection,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SwitcherTab(
                  icon: Icons.medication_rounded,
                  label: 'Medicines',
                  isActive: activeSection == 0,
                  activeColor: AppColors.primary,
                  activeGradient: const [Color(0xFF0A5C45), Color(0xFF1AAE7A)],
                  onTap: () => onSectionChanged(0),
                ),
              ),
              Expanded(
                child: _SwitcherTab(
                  icon: Icons.biotech_rounded,
                  label: 'Lab Tests',
                  isActive: activeSection == 1,
                  activeColor: AppColors.labPrimary,
                  activeGradient: const [Color(0xFF0760A8), Color(0xFF0B9FE0)],
                  onTap: () => onSectionChanged(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitcherTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final List<Color> activeGradient;
  final VoidCallback onTap;

  const _SwitcherTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.activeGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: activeGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
