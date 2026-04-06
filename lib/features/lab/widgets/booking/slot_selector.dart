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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.labPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
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
                        'Select Date & Time',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a convenient time slot for sample collection',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select Date',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            height: 85,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _availableDates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
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
                    width: 72,
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
                                ? AppColors.labPrimary.withValues(alpha: 0.3)
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Select Time Slot',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final isSelected = selectedTimeSlot == slot;
                  return GestureDetector(
                    onTap: () => onTimeSlotSelected(slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select a date to view available time slots',
                        style: GoogleFonts.sora(
                          fontSize: 12.5,
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please select date and time slot',
                        style: GoogleFonts.sora(
                          fontSize: 13,
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
  }
}
