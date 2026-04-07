import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order_model.dart';

final adminOrderActionsProvider =
    StateNotifierProvider<AdminOrderActionsNotifier, AdminOrderActionState>(
        (ref) {
  return AdminOrderActionsNotifier();
});

class AdminOrderActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AdminOrderActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AdminOrderActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AdminOrderActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class AdminOrderActionsNotifier extends StateNotifier<AdminOrderActionState> {
  AdminOrderActionsNotifier() : super(const AdminOrderActionState());

  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? updatedBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'Order not found',
        );
        return false;
      }

      final orderData = orderDoc.data()!;
      final currentStatus = orderData['status'] ?? 'pending';
      final userId = orderData['userId'] ?? '';

      final existingHistory = (orderData['statusHistory'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      existingHistory.add({
        'status': newStatus.name,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy ?? 'admin',
        'role': 'admin',
      });

      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': existingHistory,
      };

      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      if (userId.isNotEmpty && currentStatus != newStatus.name) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': 'Order Status Updated',
          'body': 'Your order has been ${newStatus.displayName.toLowerCase()}.',
          'type': 'order_status',
          'orderId': orderId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Order status updated to ${newStatus.displayName}',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update order: $e',
      );
      return false;
    }
  }

  void clearState() {
    state = const AdminOrderActionState();
  }
}

List<OrderStatus> getNextStatuses(OrderStatus current) {
  switch (current) {
    case OrderStatus.pending:
      return [OrderStatus.confirmed, OrderStatus.cancelled];
    case OrderStatus.confirmed:
      return [OrderStatus.preparing, OrderStatus.outForDelivery];
    case OrderStatus.preparing:
      return [OrderStatus.outForDelivery];
    case OrderStatus.outForDelivery:
      return [OrderStatus.delivered];
    case OrderStatus.delivered:
    case OrderStatus.cancelled:
      return [];
  }
}
