import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class PaymentSummary extends StatelessWidget {
  final int testCount;
  final double totalAmount;
  final String? paymentMethod;
  final String? scheduledDate;
  final String? scheduledTime;

  const PaymentSummary({
    super.key,
    required this.testCount,
    required this.totalAmount,
    this.paymentMethod,
    this.scheduledDate,
    this.scheduledTime,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final padding = screenWidth * 0.04;
        final isCompact = screenWidth < 360;

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
                padding: EdgeInsets.fromLTRB(
                    padding, padding, padding, padding * 0.75),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: isCompact ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.035),
                    Expanded(
                      child: Text(
                        'Payment Summary',
                        style: GoogleFonts.sora(
                          fontSize: isCompact ? 14 : 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected Tests',
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 13 : 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$testCount ${testCount == 1 ? 'test' : 'tests'}',
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 13 : 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\u20B9${totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Home Collection',
                              style: GoogleFonts.sora(
                                fontSize: isCompact ? 13 : 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: screenWidth * 0.02),
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 4 : 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'FREE',
                                style: GoogleFonts.sora(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\u20B90',
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (scheduledDate != null && scheduledTime != null) ...[
                      SizedBox(height: screenWidth * 0.03),
                      Container(
                        padding: EdgeInsets.all(padding * 0.75),
                        decoration: BoxDecoration(
                          color:
                              AppColors.labPrimaryLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: AppColors.labPrimary,
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scheduled for',
                                    style: GoogleFonts.sora(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '$scheduledDate, $scheduledTime',
                                    style: GoogleFonts.sora(
                                      fontSize: isCompact ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.labPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: screenWidth * 0.04),
                    Divider(),
                    SizedBox(height: screenWidth * 0.04),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '\u20B9${totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.sora(
                            fontSize: isCompact ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 12,
                        vertical: isCompact ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Payment: Cash on Collection',
                            style: GoogleFonts.sora(
                              fontSize: isCompact ? 10.5 : 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
