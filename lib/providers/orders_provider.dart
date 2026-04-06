import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/service_providers.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final ordersProvider = StreamProvider<List<OrderModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;

  if (uid == null) {
    return Stream.value([]);
  }

  return firestoreService.getUserOrders(uid);
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final roleAsync = ref.watch(roleProvider);

  if (roleAsync.valueOrNull != 'admin') {
    yield [];
    return;
  }

  yield* firestoreService.getAllOrders();
});

final orderByStatusProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, status) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getOrdersByStatus(status);
});

final orderByIdProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getOrderById(orderId);
});

final selectedStatusProvider = StateProvider<String?>((ref) => null);

enum PageErrorType {
  none,
  permissionDenied,
  queryPrecondition,
  network,
  authResolution,
  unknown,
}

class AdminOrdersPageState {
  static const Object _unset = Object();

  final List<OrderModel> orders;
  final DocumentSnapshot? lastDoc;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool hasLoadedOnce;
  final AdminAuthStatus? authStatus;
  final PageErrorType errorType;
  final String? errorMessage;
  final PageErrorType paginationError;
  final String? paginationErrorMessage;

  const AdminOrdersPageState({
    this.orders = const [],
    this.lastDoc,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isInitialLoading = true,
    this.isRefreshing = false,
    this.hasLoadedOnce = false,
    this.authStatus,
    this.errorType = PageErrorType.none,
    this.errorMessage,
    this.paginationError = PageErrorType.none,
    this.paginationErrorMessage,
  });

  AdminOrdersPageState copyWith({
    List<OrderModel>? orders,
    Object? lastDoc = _unset,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? hasLoadedOnce,
    Object? authStatus = _unset,
    PageErrorType? errorType,
    Object? errorMessage = _unset,
    PageErrorType? paginationError,
    Object? paginationErrorMessage = _unset,
  }) {
    return AdminOrdersPageState(
      orders: orders ?? this.orders,
      lastDoc: identical(lastDoc, _unset)
          ? this.lastDoc
          : lastDoc as DocumentSnapshot?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      authStatus: identical(authStatus, _unset)
          ? this.authStatus
          : authStatus as AdminAuthStatus?,
      errorType: errorType ?? this.errorType,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      paginationError: paginationError ?? this.paginationError,
      paginationErrorMessage: identical(paginationErrorMessage, _unset)
          ? this.paginationErrorMessage
          : paginationErrorMessage as String?,
    );
  }
}

class AdminOrdersPageNotifier extends StateNotifier<AdminOrdersPageState> {
  final FirestoreService _firestoreService;
  static const int _pageSize = 20;
  int _loadId = 0;

  bool get hasLoadedOrders => state.hasLoadedOnce;

  AdminOrdersPageNotifier(this._firestoreService)
      : super(const AdminOrdersPageState());

  Future<void> loadFirstPage({bool preserveExisting = false}) async {
    final id = ++_loadId;
    final currentAuthStatus = state.authStatus ?? AdminAuthStatus.admin;
    final canPreserveUi = preserveExisting && state.hasLoadedOnce;

    state = canPreserveUi
        ? state.copyWith(
            authStatus: currentAuthStatus,
            isInitialLoading: false,
            isRefreshing: true,
            isLoadingMore: false,
            errorType: PageErrorType.none,
            errorMessage: null,
            paginationError: PageErrorType.none,
            paginationErrorMessage: null,
          )
        : AdminOrdersPageState(
            authStatus: currentAuthStatus,
            isInitialLoading: true,
          );

    try {
      final result =
          await _firestoreService.getOrdersPaginated(limit: _pageSize);
      if (_loadId != id) return;

      state = state.copyWith(
        authStatus: AdminAuthStatus.admin,
        isInitialLoading: false,
        isRefreshing: false,
        hasLoadedOnce: true,
        orders: result.orders,
        lastDoc: result.lastDoc,
        hasMore: result.orders.length == _pageSize,
        errorType: PageErrorType.none,
        errorMessage: null,
        paginationError: PageErrorType.none,
        paginationErrorMessage: null,
      );
    } catch (e) {
      if (_loadId != id) return;

      state = state.copyWith(
        authStatus: currentAuthStatus,
        isInitialLoading: false,
        isRefreshing: false,
        errorType: _classifyError(e),
        errorMessage: e.toString(),
      );
    }
  }

  PageErrorType _classifyError(dynamic error) {
    if (error is FirebaseException) {
      final code = error.code;
      final message = error.message?.toLowerCase() ?? '';

      if (code == 'permission-denied') return PageErrorType.permissionDenied;
      if (code == 'failed-precondition') {
        if (message.contains('index') || message.contains('query')) {
          return PageErrorType.queryPrecondition;
        }
        return PageErrorType.queryPrecondition;
      }
      if (code == 'unavailable') return PageErrorType.network;
    }
    return PageErrorType.unknown;
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || state.isRefreshing || !state.hasMore) return;

    final id = _loadId;
    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _firestoreService.getOrdersPaginated(
        lastDoc: state.lastDoc,
        limit: _pageSize,
      );
      if (_loadId != id) return;

      state = state.copyWith(
        isLoadingMore: false,
        orders: [...state.orders, ...result.orders],
        lastDoc: result.lastDoc,
        hasMore: result.orders.length == _pageSize,
        paginationError: PageErrorType.none,
        paginationErrorMessage: null,
      );
    } catch (e) {
      if (_loadId != id) return;

      state = state.copyWith(
        isLoadingMore: false,
        paginationError: _classifyError(e),
        paginationErrorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() => loadFirstPage(preserveExisting: true);

  void setAuthLoading() {
    if (state.hasLoadedOnce) {
      return;
    }

    state = state.copyWith(
      isInitialLoading: true,
      authStatus: AdminAuthStatus.loading,
    );
  }

  void setAdminReady() {
    state = state.copyWith(
      authStatus: AdminAuthStatus.admin,
      isInitialLoading: false,
      isRefreshing: false,
    );
  }

  void setAuthDenied() {
    state = AdminOrdersPageState(
      authStatus: AdminAuthStatus.notAdmin,
      isInitialLoading: false,
      hasLoadedOnce: state.hasLoadedOnce,
      hasMore: false,
    );
  }

  void setAuthError(String? errorMessage) {
    state = AdminOrdersPageState(
      authStatus: AdminAuthStatus.error,
      isInitialLoading: false,
      hasLoadedOnce: state.hasLoadedOnce,
      hasMore: false,
      errorType: PageErrorType.authResolution,
      errorMessage: errorMessage,
    );
  }
}

final adminOrdersPageProvider =
    StateNotifierProvider<AdminOrdersPageNotifier, AdminOrdersPageState>((ref) {
  final notifier = AdminOrdersPageNotifier(ref.watch(firestoreServiceProvider));

  void handleAdminAuthState(
    AsyncValue<AdminAuthState> next, {
    AdminAuthStatus? previousStatus,
  }) {
    final authState = next.valueOrNull;

    if (authState == null || authState.status == AdminAuthStatus.loading) {
      notifier.setAuthLoading();
    } else if (authState.status == AdminAuthStatus.notAdmin) {
      notifier.setAuthDenied();
    } else if (authState.status == AdminAuthStatus.error) {
      notifier.setAuthError(authState.error?.toString());
    } else if (previousStatus == AdminAuthStatus.admin &&
        notifier.hasLoadedOrders) {
      notifier.setAdminReady();
    } else {
      notifier.loadFirstPage();
    }
  }

  handleAdminAuthState(ref.read(adminAuthStateProvider));

  ref.listen<AsyncValue<AdminAuthState>>(adminAuthStateProvider,
      (previous, next) {
    handleAdminAuthState(
      next,
      previousStatus: previous?.valueOrNull?.status,
    );
  });

  return notifier;
});
