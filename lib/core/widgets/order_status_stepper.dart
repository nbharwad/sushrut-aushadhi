import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';

class OrderStatusStepper extends StatelessWidget {
  final OrderModel order;

  const OrderStatusStepper({super.key, required this.order});

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final activeSteps = isCancelled ? _stepsUpToCancelled() : _steps;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                for (int i = 0; i < activeSteps.length; i++)
                  _buildStep(
                    status: activeSteps[i],
                    isLast: i == activeSteps.length - 1 && !isCancelled,
                    isCompleted: _isCompleted(activeSteps[i]),
                    isActive: _isActive(activeSteps[i]),
                    showConnector: i < activeSteps.length - 1 || isCancelled,
                  ),
                if (isCancelled) _buildCancelledNode(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<OrderStatus> _stepsUpToCancelled() {
    final lastActive = _findLastActiveBeforeCancelled();
    if (lastActive == null) return [_steps.first];
    final idx = _steps.indexOf(lastActive);
    return _steps.sublist(0, idx + 1);
  }

  OrderStatus? _findLastActiveBeforeCancelled() {
    // Find the last status in the history that is not cancelled
    for (final entry in order.statusHistory.reversed) {
      final s = OrderStatus.fromString(entry.status);
      if (s != OrderStatus.cancelled) return s;
    }
    return null;
  }

  bool _isCompleted(OrderStatus status) {
    if (order.status == OrderStatus.cancelled) {
      final idx = _steps.indexOf(status);
      final lastActiveIdx = _steps.indexOf(_findLastActiveBeforeCancelled() ?? _steps.first);
      return idx <= lastActiveIdx;
    }
    final currentIdx = _steps.indexOf(order.status);
    final stepIdx = _steps.indexOf(status);
    return stepIdx < currentIdx;
  }

  bool _isActive(OrderStatus status) {
    if (order.status == OrderStatus.cancelled) return false;
    return status == order.status;
  }

  DateTime? _timestampFor(OrderStatus status) {
    for (final entry in order.statusHistory) {
      if (OrderStatus.fromString(entry.status) == status) {
        return entry.timestamp;
      }
    }
    return null;
  }

  DateTime? _cancelledTimestamp() {
    for (final entry in order.statusHistory) {
      if (OrderStatus.fromString(entry.status) == OrderStatus.cancelled) {
        return entry.timestamp;
      }
    }
    return null;
  }

  Widget _buildStep({
    required OrderStatus status,
    required bool isLast,
    required bool isCompleted,
    required bool isActive,
    required bool showConnector,
  }) {
    final timestamp = _timestampFor(status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _buildIndicator(isCompleted: isCompleted, isActive: isActive),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.primary : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 16 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.displayName,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? AppColors.primary
                          : isCompleted
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM, h:mm a').format(timestamp),
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledNode() {
    final ts = _cancelledTimestamp();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancelled',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                if (ts != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM, h:mm a').format(ts),
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isCompleted, required bool isActive}) {
    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2.5),
          shape: BoxShape.circle,
          color: AppColors.primaryLight,
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}
