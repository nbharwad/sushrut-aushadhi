import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class HomeCategoryChipRow extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const HomeCategoryChipRow({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<Map<String, String>> categories = [
    {'id': 'all', 'name': 'All', 'icon': 'apps'},
    {'id': 'fever', 'name': 'Fever', 'icon': 'thermostat'},
    {'id': 'pain', 'name': 'Pain', 'icon': 'healing'},
    {'id': 'skin', 'name': 'Skin', 'icon': 'spa'},
    {'id': 'diabetes', 'name': 'Diabetes', 'icon': 'bloodtype'},
    {'id': 'heart', 'name': 'Heart', 'icon': 'favorite'},
    {'id': 'vitamins', 'name': 'Vitamins', 'icon': 'vaccines'},
  ];

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'apps':
        return Icons.apps_rounded;
      case 'thermostat':
        return Icons.thermostat_rounded;
      case 'healing':
        return Icons.healing_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'bloodtype':
        return Icons.bloodtype_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'vaccines':
        return Icons.vaccines_rounded;
      default:
        return Icons.medication_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 46,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category['id'] == selectedCategory;

            return GestureDetector(
              onTap: () => onCategorySelected(category['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF0A5C45), Color(0xFF1AAE7A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.divider,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIcon(category['icon']!),
                      size: 15,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['name']!,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomeCategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryTap;

  const HomeCategoriesSection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  Color _getCategoryColor(String id) {
    switch (id) {
      case 'fever':
        return const Color(0xFFE8803A);
      case 'pain':
        return const Color(0xFF3A9E6B);
      case 'skin':
        return const Color(0xFF5B9CF6);
      case 'diabetes':
        return const Color(0xFFDB6B9E);
      case 'heart':
        return const Color(0xFF8B72E8);
      case 'vitamins':
        return const Color(0xFF2EC4A9);
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String id) {
    switch (id) {
      case 'fever':
        return Icons.thermostat_rounded;
      case 'pain':
        return Icons.medication_rounded;
      case 'skin':
        return Icons.spa_rounded;
      case 'diabetes':
        return Icons.bloodtype_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'vitamins':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.local_hospital_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shop by Category',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => onCategoryTap('all'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'See all',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 112,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final c = categories[index] as Map<String, dynamic>;
                final id = c['id']?.toString() ?? '';
                final selected = selectedCategory == id;
                final color = _getCategoryColor(id);

                return GestureDetector(
                  onTap: () => onCategoryTap(id),
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: selected
                                ? LinearGradient(
                                    colors: [
                                      color,
                                      color.withOpacity(0.75),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: selected ? null : color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.30),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(id),
                              size: 28,
                              color: selected ? Colors.white : color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c['name']?.toString() ?? '',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            height: 1.2,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
