import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class ConfirmButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;
  final String label;

  const ConfirmButton({
    super.key,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
    this.label = 'Confirm Booking',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final padding = screenWidth * 0.04;
        final isCompact = screenWidth < 360;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, padding * 0.75, padding, 0),
              child: SizedBox(
                width: double.infinity,
                height: isCompact ? 48 : 54,
                child: ElevatedButton(
                  onPressed: isLoading || !isEnabled ? null : onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.labPrimary,
                    disabledBackgroundColor:
                        AppColors.labPrimary.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: isCompact ? 18 : 22,
                              height: isCompact ? 18 : 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Text(
                              'Processing...',
                              style: GoogleFonts.sora(
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: isCompact ? 18 : 22),
                            SizedBox(width: screenWidth * 0.025),
                            Text(
                              label,
                              style: GoogleFonts.sora(
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
