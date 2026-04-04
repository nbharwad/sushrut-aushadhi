import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../models/lab_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lab_providers.dart';
import '../../services/lab_service.dart';

class LabOrderRequestScreen extends ConsumerStatefulWidget {
  final String? packageId;
  final List<String> preselectedTestIds;
  final String? packageName;
  final double? packagePrice;

  const LabOrderRequestScreen({
    super.key,
    this.packageId,
    this.preselectedTestIds = const [],
    this.packageName,
    this.packagePrice,
  });

  @override
  ConsumerState<LabOrderRequestScreen> createState() => _LabOrderRequestScreenState();
}

class _LabOrderRequestScreenState extends ConsumerState<LabOrderRequestScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPackageBooking = false;

  final Map<String, bool> _selectedTests = {};

  @override
  void initState() {
    super.initState();
    _isPackageBooking = widget.packageId != null && widget.preselectedTestIds.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && user.address.isNotEmpty) {
        _addressController.text = user.address;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _getTotalAmount(List<LabTestModel> tests) {
    if (_isPackageBooking) return widget.packagePrice ?? 0;
    return tests
        .where((test) => _selectedTests[test.id] == true)
        .fold(0, (sum, test) => sum + test.price);
  }

  List<LabTestItem> _getSelectedTestItems(List<LabTestModel> tests) {
    if (_isPackageBooking) {
      // For package bookings, map preselected test IDs to LabTestItems
      return widget.preselectedTestIds.asMap().entries.map((entry) {
        final testId = entry.value;
        final matching = tests.where((t) => t.id == testId).toList();
        if (matching.isNotEmpty) {
          final test = matching.first;
          return LabTestItem(testId: test.id, testName: test.name, price: test.price);
        }
        return LabTestItem(testId: testId, testName: 'Test', price: 0);
      }).toList();
    }
    return tests
        .where((test) => _selectedTests[test.id] == true)
        .map((test) => LabTestItem(testId: test.id, testName: test.name, price: test.price))
        .toList();
  }

  Future<void> _submitOrder(List<LabTestModel> tests) async {
    final selectedItems = _getSelectedTestItems(tests);
    final totalAmount = _getTotalAmount(tests);

    if (selectedItems.isEmpty && !_isPackageBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one test', style: GoogleFonts.sora())),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your address', style: GoogleFonts.sora())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('User not found');

      String? notesText = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      // Tag package bookings in notes for traceability
      if (_isPackageBooking && widget.packageId != null) {
        final packageNote = 'Package: ${widget.packageName ?? widget.packageId}';
        notesText = notesText != null ? '$packageNote | $notesText' : packageNote;
      }

      final order = LabOrderModel(
        orderId: '',
        userId: user.uid,
        userPhone: user.phone,
        userName: user.name,
        homeCollectionAddress: _addressController.text.trim(),
        tests: selectedItems,
        totalAmount: totalAmount,
        status: LabOrderStatus.pending,
        paymentMethod: 'cod',
        paymentStatus: 'pending',
        notes: notesText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        statusHistory: [
          LabStatusHistoryEntry(
            status: LabOrderStatus.pending.name,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final orderId = await ref.read(labServiceProvider).placeLabOrder(order);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lab order placed successfully!', style: GoogleFonts.sora()),
          backgroundColor: AppColors.labPrimary,
        ),
      );

      // pushReplacement so back from detail goes to orders list, not this form
      context.pushReplacement('/lab-order/$orderId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', style: GoogleFonts.sora())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(labTestsProvider);
    final isCompact = MediaQuery.of(context).size.width < 360;
    final tests = testsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isCompact),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isPackageBooking)
                      _buildPackageSummaryCard()
                    else
                      _buildTestSelection(testsAsync),
                    const SizedBox(height: 20),
                    _buildAddressSection(),
                    const SizedBox(height: 20),
                    _buildNotesSection(),
                    const SizedBox(height: 24),
                    _buildOrderSummary(tests),
                    const SizedBox(height: 24),
                    _buildSubmitButton(tests),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.labPrimary, AppColors.labSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPackageBooking ? 'Confirm Booking' : 'Book Lab Tests',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPackageBooking
                      ? 'Review and confirm your package booking'
                      : 'Select tests and provide address for sample collection',
                  style: GoogleFonts.sora(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSummaryCard() {
    final testsAsync = ref.watch(labTestsProvider);
    final allTests = testsAsync.valueOrNull ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.labPrimaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.labPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2, color: AppColors.labPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.packageName ?? 'Lab Package',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.preselectedTestIds.length} tests included',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (allTests.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'View included tests',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppColors.labPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: widget.preselectedTestIds.map((testId) {
                final matching = allTests.where((t) => t.id == testId).toList();
                final testName = matching.isNotEmpty ? matching.first.name : testId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4, left: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.labPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(testName, style: GoogleFonts.sora(fontSize: 13)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestSelection(AsyncValue<List<LabTestModel>> tests) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: AppColors.labPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Select Tests',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          tests.when(
            data: (testList) {
              if (testList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.science_outlined, size: 64, color: Color(0xFFBDBDBD)),
                        const SizedBox(height: 16),
                        Text(
                          'No tests available',
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lab tests will be available soon',
                          style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(labTestsProvider),
                          icon: const Icon(Icons.refresh),
                          label: Text('Retry', style: GoogleFonts.sora()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.labPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(children: testList.map((test) => _buildTestTile(test)).toList());
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading tests',
                      style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(e.toString(), style: GoogleFonts.sora(fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(labTestsProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text('Retry', style: GoogleFonts.sora()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.labPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTile(LabTestModel test) {
    final isSelected = _selectedTests[test.id] ?? false;

    return InkWell(
      onTap: () => setState(() => _selectedTests[test.id] = !isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.labPrimaryLight : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.labPrimary : const Color(0xFFE8ECE7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.labPrimary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.labPrimary : const Color(0xFFBDBDBD),
                ),
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                test.name,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              '\u20B9${test.price.toStringAsFixed(0)}',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.labPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF1E88E5), size: 20),
              const SizedBox(width: 8),
              Text(
                'Sample Collection Address',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Our phlebotomist will visit this address for sample collection',
            style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your full address...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.labPrimary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: GoogleFonts.sora(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, color: Color(0xFFFB8C00), size: 20),
              const SizedBox(width: 8),
              Text(
                'Additional Notes (Optional)',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any special instructions (e.g., I am diabetic)...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.labPrimary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: GoogleFonts.sora(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(List<LabTestModel> tests) {
    final total = _isPackageBooking ? (widget.packagePrice ?? 0) : _getTotalAmount(tests);
    final count = _isPackageBooking
        ? widget.preselectedTestIds.length
        : _getSelectedTestItems(tests).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.labPrimaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tests', style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary)),
              Text(
                '$count ${count == 1 ? 'test' : 'tests'}',
                style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '\u20B9${total.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.labPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Payment: Cash on Collection',
            style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(List<LabTestModel> tests) {
    final hasTests = _isPackageBooking
        ? widget.preselectedTestIds.isNotEmpty
        : _getSelectedTestItems(tests).isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting || !hasTests ? null : () => _submitOrder(tests),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.labPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: AppColors.labPrimary.withOpacity(0.5),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Confirm Booking',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
