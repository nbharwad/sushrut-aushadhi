import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class SlotSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final Function(DateTime) onDateSelected;
  final Function(String) onTimeSlotSelected;
  final bool hasError;

  const SlotSelector({
    super.key,
    this.selectedDate,
    this.selectedTimeSlot,
    required this.onDateSelected,
    required this.onTimeSlotSelected,
    this.hasError = false,
  });

  List<DateTime> get _availableDates {
    final now = DateTime.now();
    return List.generate(7, (index) => now.add(Duration(days: index)));
  }

  List<String> get _timeSlots => [
        '06:00 AM - 08:00 AM',
        '08:00 AM - 10:00 AM',
        '10:00 AM - 12:00 PM',
        '12:00 PM - 02:00 PM',
        '02:00 PM - 04:00 PM',
        '04:00 PM - 06:00 PM',
        '06:00 PM - 08:00 PM',
      ];

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final padding = screenWidth * 0.04;
        final isCompact = screenWidth < 360;
        final dateCardWidth = screenWidth * 0.18;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? AppColors.error.withValues(alpha: 0.5)
                  : const Color(0xFFE8ECE7),
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
                    padding, padding, padding, padding * 0.75),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: AppColors.labPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.labPrimary,
                        size: isCompact ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.035),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Date & Time',
                            style: GoogleFonts.sora(
                              fontSize: isCompact ? 14 : 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.005),
                          Text(
                            'Choose a convenient time slot for sample collection',
                            style: GoogleFonts.sora(
                              fontSize: isCompact ? 10.5 : 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    padding, padding, padding, padding * 0.5),
                child: Text(
                  'Select Date',
                  style: GoogleFonts.sora(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                height: 85,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableDates.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: screenWidth * 0.025),
                  itemBuilder: (context, index) {
                    final date = _availableDates[index];
                    final isSelected = selectedDate != null &&
                        date.year == selectedDate!.year &&
                        date.month == selectedDate!.month &&
                        date.day == selectedDate!.day;
                    final isToday = _isToday(date);

                    return GestureDetector(
                      onTap: () => onDateSelected(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: dateCardWidth,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.labPrimary
                              : isToday
                                  ? AppColors.labPrimaryLight
                                  : const Color(0xFFF8F9F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.labPrimary
                                : isToday
                                    ? AppColors.labPrimary
                                        .withValues(alpha: 0.3)
                                    : const Color(0xFFE8ECE7),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isToday
                                  ? 'Today'
                                  : [
                                      'Sun',
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat'
                                    ][date.weekday - 1],
                              style: GoogleFonts.sora(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: GoogleFonts.sora(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isToday
                                  ? ''
                                  : [
                                      'Jan',
                                      'Feb',
                                      'Mar',
                                      'Apr',
                                      'May',
                                      'Jun',
                                      'Jul',
                                      'Aug',
                                      'Sep',
                                      'Oct',
                                      'Nov',
                                      'Dec'
                                    ][date.month - 1]
                                      .substring(0, 3),
                              style: GoogleFonts.sora(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selectedDate != null) ...[
                SizedBox(height: screenWidth * 0.04),
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(padding, 0, padding, padding * 0.5),
                  child: Text(
                    'Select Time Slot',
                    style: GoogleFonts.sora(
                      fontSize: isCompact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                  child: Wrap(
                    spacing: screenWidth * 0.02,
                    runSpacing: screenWidth * 0.02,
                    children: _timeSlots.map((slot) {
                      final isSelected = selectedTimeSlot == slot;
                      return GestureDetector(
                        onTap: () => onTimeSlotSelected(slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 10 : 14,
                            vertical: isCompact ? 8 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.labPrimary
                                : const Color(0xFFF8F9F8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.labPrimary
                                  : const Color(0xFFE8ECE7),
                            ),
                          ),
                          child: Text(
                            slot,
                            style: GoogleFonts.sora(
                              fontSize: isCompact ? 11 : 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                SizedBox(height: screenWidth * 0.02),
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                  child: Container(
                    padding: EdgeInsets.all(padding * 0.75),
                    decoration: BoxDecoration(
                      color: AppColors.labPrimaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.labPrimary,
                        ),
                        SizedBox(width: screenWidth * 0.025),
                        Expanded(
                          child: Text(
                            'Select a date to view available time slots',
                            style: GoogleFonts.sora(
                              fontSize: isCompact ? 11 : 12.5,
                              color: AppColors.labPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (hasError &&
                  (selectedDate == null || selectedTimeSlot == null)) ...[
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
                            'Please select date and time slot',
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
              ],
            ],
          ),
        );
      },
    );
  }
}
