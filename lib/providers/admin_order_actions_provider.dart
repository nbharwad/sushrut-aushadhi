import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
    String? statusNote,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      // Force token refresh to get latest custom claims (role: admin)
      await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);

      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('updateOrderStatus').call(<String, dynamic>{
        'orderId': orderId,
        'newStatus': newStatus.name,
        if (statusNote != null && statusNote.trim().isNotEmpty)
          'statusNote': statusNote.trim(),
      });

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Order status updated to ${newStatus.displayName}',
      );

      return true;
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatFunctionsError(e),
      );
      return false;
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

  String _formatFunctionsError(FirebaseFunctionsException error) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied while updating the order';
      case 'not-found':
        return 'Order not found';
      case 'invalid-argument':
        return 'Invalid order status update';
      case 'unauthenticated':
        return 'Please sign in again and retry';
      default:
        return 'Failed to update order (${error.code})';
    }
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
