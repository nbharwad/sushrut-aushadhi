import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';

class HomeMedicineCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const HomeMedicineCard({
    super.key,
    required this.medicine,
    required this.onTap,
    required this.onAddToCart,
  });

  IconData _getMedicineIcon(String category) {
    switch (category) {
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
        return Icons.medication_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
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

  @override
  Widget build(BuildContext context) {
    final price = ((medicine['price'] ?? 0) as num).toDouble();
    final mrp = ((medicine['mrp'] ?? 0) as num).toDouble();
    final discount = Helpers.calculateDiscount(price, mrp);
    final requiresPrescription = medicine['requiresPrescription'] == true;
    final category = medicine['category']?.toString() ?? '';
    final categoryColor = _getCategoryColor(category);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;
        final imageSize = constraints.maxWidth * (isCompact ? 0.42 : 0.38);
        final spacing = isCompact ? 8.0 : 10.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (requiresPrescription)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 5 : 6,
                          vertical: isCompact ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Rx',
                          style: GoogleFonts.sora(
                            color: AppColors.error,
                            fontSize: isCompact ? 8 : 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    const Spacer(),
                    GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        width: isCompact ? 28 : 30,
                        height: isCompact ? 28 : 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A5C45), Color(0xFF1AAE7A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: isCompact ? 15 : 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Center(
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        _getMedicineIcon(category),
                        size: isCompact ? 30 : 36,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          medicine['name']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 12 : 13,
                            height: 1.3,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 3 : 4),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          medicine['brand']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 10 : 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (discount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.discountRed.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '$discount% off',
                            style: GoogleFonts.sora(
                              color: AppColors.discountRed,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\u20B9${price.toStringAsFixed(0)}',
                            style: GoogleFonts.sora(
                              color: AppColors.primary,
                              fontSize: isCompact ? 14 : 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (mrp > price)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Text(
                                '\u20B9${mrp.toStringAsFixed(0)}',
                                style: GoogleFonts.sora(
                                  color: AppColors.textSecondary,
                                  fontSize: isCompact ? 9 : 10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeMedicineGrid extends StatelessWidget {
  final List<Map<String, dynamic>> medicines;
  final Function(Map<String, dynamic>) onMedicineTap;
  final Function(Map<String, dynamic>) onAddToCart;

  const HomeMedicineGrid({
    super.key,
    required this.medicines,
    required this.onMedicineTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final displayMedicines = medicines.take(6).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Medicines',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'View all',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 360 ? 2 : 3;
                final itemHeight = constraints.maxWidth < 360 ? 200.0 : 220.0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: itemHeight,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: displayMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = displayMedicines[index];
                    return HomeMedicineCard(
                      medicine: medicine,
                      onTap: () => onMedicineTap(medicine),
                      onAddToCart: () => onAddToCart(medicine),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
