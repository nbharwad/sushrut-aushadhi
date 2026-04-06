import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class AddressCard extends StatelessWidget {
  final String address;
  final String? mobileNumber;
  final VoidCallback onEdit;
  final bool hasError;

  const AddressCard({
    super.key,
    required this.address,
    this.mobileNumber,
    required this.onEdit,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final padding = screenWidth * 0.04;
        final isCompact = screenWidth < 360;
        final hasAddress = address.trim().isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? AppColors.error.withValues(alpha: 0.5)
                  : hasAddress
                      ? const Color(0xFFE8ECE7)
                      : AppColors.statusPending.withValues(alpha: 0.3),
              width: hasError ? 1.5 : 1,
            ),
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
                padding: EdgeInsets.fromLTRB(
                    padding, padding, padding * 0.5, padding * 0.75),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: hasAddress
                            ? AppColors.labPrimaryLight
                            : AppColors.statusPending.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: hasAddress
                            ? AppColors.labPrimary
                            : AppColors.statusPending,
                        size: isCompact ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.035),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample Collection Address',
                            style: GoogleFonts.sora(
                              fontSize: isCompact ? 14 : 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.005),
                          Text(
                            'Our phlebotomist will visit this address',
                            style: GoogleFonts.sora(
                              fontSize: isCompact ? 11 : 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8 : 12,
                          vertical: isCompact ? 6 : 8,
                        ),
                        backgroundColor: AppColors.labPrimaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Edit',
                        style: GoogleFonts.sora(
                          fontSize: isCompact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.labPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasError || !hasAddress) ...[
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Container(
                    padding: EdgeInsets.all(padding * 0.75),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        SizedBox(width: screenWidth * 0.025),
                        Expanded(
                          child: Text(
                            hasError
                                ? 'Please add address to continue'
                                : 'Address required for sample collection',
                            style: GoogleFonts.sora(
                              fontSize: isCompact ? 12 : 13,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.home_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: screenWidth * 0.025),
                          Expanded(
                            child: Text(
                              address,
                              style: GoogleFonts.sora(
                                fontSize: isCompact ? 13 : 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (mobileNumber != null && mobileNumber!.isNotEmpty) ...[
                        SizedBox(height: screenWidth * 0.025),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Text(
                              mobileNumber!,
                              style: GoogleFonts.sora(
                                fontSize: isCompact ? 12 : 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
