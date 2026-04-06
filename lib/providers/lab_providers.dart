import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/lab_service.dart';
import '../models/lab_order_model.dart';
import '../models/lab_package_model.dart';
import 'auth_provider.dart';
import 'firebase_providers.dart';

final labServiceProvider = Provider<LabService>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  return LabService(firestore: firestore);
});

final userLabOrdersProvider = StreamProvider<List<LabOrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final labService = ref.watch(labServiceProvider);

  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value([]);
  }

  return labService.getUserLabOrders(user.uid);
});

final allLabOrdersProvider = StreamProvider<List<LabOrderModel>>((ref) async* {
  final labService = ref.watch(labServiceProvider);
  final roleAsync = ref.watch(roleProvider);
  
  if (roleAsync.valueOrNull != 'admin') {
    yield [];
    return;
  }
  
  yield* labService.getAllLabOrders();
});

final labOrderProvider = StreamProvider.family<LabOrderModel?, String>((ref, orderId) {
  final labService = ref.watch(labServiceProvider);
  return labService.getLabOrderStream(orderId);
});

final labTestsProvider = FutureProvider<List<LabTestModel>>((ref) {
  print("=== LAB PROVIDER: Creating new provider instance ===");
  final labService = ref.watch(labServiceProvider);
  final future = labService.getLabTests();
  print("=== LAB PROVIDER: got future: $future ===");
  return future.then((tests) {
    print("=== LAB PROVIDER: Resolved with ${tests.length} tests ===");
    return tests;
  });
});

final todayLabSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final labService = ref.watch(labServiceProvider);
  return labService.getTodayLabSummary();
});

// Lab Packages — user-facing (active only, real-time)
final labPackagesProvider = StreamProvider<List<LabPackageModel>>((ref) {
  final labService = ref.watch(labServiceProvider);
  return labService.getLabPackages();
});

// Lab Packages — admin (all including inactive, real-time)
final allLabPackagesProvider = StreamProvider<List<LabPackageModel>>((ref) {
  final labService = ref.watch(labServiceProvider);
  return labService.getAllLabPackages();
});

// Single package by ID — real-time
final labPackageProvider = StreamProvider.family<LabPackageModel?, String>((ref, packageId) {
  final labService = ref.watch(labServiceProvider);
  return labService.getLabPackageStream(packageId);
});

// All individual tests as stream — for admin management screen
final allLabTestsStreamProvider = StreamProvider<List<LabTestModel>>((ref) {
  final labService = ref.watch(labServiceProvider);
  return labService.getAllLabTestsStream();
});