import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class BookingHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isPackageBooking;

  const BookingHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.isPackageBooking = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 360;
        final isVeryCompact = screenWidth < 320;
        final padding = screenWidth * 0.04;

        return Container(
          padding: EdgeInsets.fromLTRB(
            padding,
            padding,
            padding,
            isCompact ? padding * 0.75 : padding,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.labPrimary,
                AppColors.labPrimary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.labPrimary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isVeryCompact ? 8 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPackageBooking
                      ? Icons.inventory_2_rounded
                      : Icons.science_rounded,
                  color: Colors.white,
                  size: isVeryCompact ? 20 : (isCompact ? 22 : 24),
                ),
              ),
              SizedBox(width: screenWidth * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: isVeryCompact ? 15 : (isCompact ? 17 : 19),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      subtitle,
                      style: GoogleFonts.sora(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: isVeryCompact ? 10 : (isCompact ? 11.5 : 12),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.all(isVeryCompact ? 4 : 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: isVeryCompact ? 14 : 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
