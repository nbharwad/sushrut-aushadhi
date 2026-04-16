import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/service_providers.dart';
import '../models/return_request_model.dart';
import '../providers/auth_provider.dart';

final userReturnRequestsProvider =
    StreamProvider<List<ReturnRequestModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .getUserReturnRequests(uid)
      .map((list) =>
          list.map((m) => ReturnRequestModel.fromMap(m, m['id'] as String)).toList());
});

final adminReturnRequestsProvider =
    StreamProvider.family<List<ReturnRequestModel>, String?>((ref, status) {
  final roleAsync = ref.watch(roleProvider);
  if (roleAsync.valueOrNull != 'admin') return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .getReturnRequests(status: status)
      .map((list) =>
          list.map((m) => ReturnRequestModel.fromMap(m, m['id'] as String)).toList());
});
