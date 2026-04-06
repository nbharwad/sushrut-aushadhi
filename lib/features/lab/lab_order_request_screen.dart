import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../cart/widgets/delivery_details_sheet.dart';
import '../../models/lab_order_model.dart';
import '../../models/lab_package_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lab_providers.dart';
import '../../services/delivery_details_service.dart';
import 'widgets/booking/booking_widgets.dart';

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
  ConsumerState<LabOrderRequestScreen> createState() =>
      _LabOrderRequestScreenState();
}

class _LabOrderRequestScreenState extends ConsumerState<LabOrderRequestScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPackageBooking = false;

  SelectionMode _selectionMode = SelectionMode.packages;
  LabPackageModel? _selectedPackage;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _mobileNumber;

  final Map<String, bool> _selectedTests = {};

  bool _showAddressError = false;
  bool _showSlotError = false;

  @override
  void initState() {
    super.initState();
    _isPackageBooking =
        widget.packageId != null && widget.preselectedTestIds.isNotEmpty;

    if (_isPackageBooking) {
      _selectionMode = SelectionMode.packages;
      for (final testId in widget.preselectedTestIds) {
        _selectedTests[testId] = true;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillAddressFromProfile();
      _prefillAddressFromDeliveryDetails();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _getTotalAmount(List<LabTestModel> tests) {
    if (_selectionMode == SelectionMode.packages && _selectedPackage != null) {
      return _selectedPackage!.price;
    }
    return tests
        .where((test) => _selectedTests[test.id] == true)
        .fold(0, (sum, test) => sum + test.price);
  }

  List<LabTestItem> _getSelectedTestItems(List<LabTestModel> tests) {
    if (_selectionMode == SelectionMode.packages && _selectedPackage != null) {
      return _selectedPackage!.testIds.asMap().entries.map((entry) {
        final testId = entry.value;
        final matching = tests.where((t) => t.id == testId).toList();
        if (matching.isNotEmpty) {
          final test = matching.first;
          return LabTestItem(
              testId: test.id, testName: test.name, price: test.price);
        }
        return LabTestItem(testId: testId, testName: 'Test', price: 0);
      }).toList();
    }
    return tests
        .where((test) => _selectedTests[test.id] == true)
        .map((test) => LabTestItem(
            testId: test.id, testName: test.name, price: test.price))
        .toList();
  }

  void _prefillAddressFromProfile() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _addressController.text.trim().isNotEmpty) return;

    if (user.address.isNotEmpty) {
      _addressController.text = user.address;
    } else if (user.deliveryAddress.line1.isNotEmpty) {
      _addressController.text = user.deliveryAddress.toDisplayString();
    }
  }

  Future<void> _prefillAddressFromDeliveryDetails() async {
    final details = await DeliveryDetailsService.getDetails();
    if (!mounted || details.address.trim().isEmpty) return;
    setState(() {
      _addressController.text = details.address.trim();
      _mobileNumber = details.phone;
    });
  }

  void _showDeliveryDetailsSheet({
    required List<LabTestModel> tests,
    required UserModel user,
    required DeliveryDetails existingDetails,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryDetailsSheet(
        existingDetails: existingDetails,
        onSaved: (details) async {
          setState(() {
            _addressController.text = details.address;
            _mobileNumber = details.phone;
          });
          await _createLabOrder(tests, user, details);
        },
      ),
    );
  }

  Future<void> _submitOrder(List<LabTestModel> tests, UserModel? user) async {
    final selectedItems = _getSelectedTestItems(tests);
    final totalAmount = _getTotalAmount(tests);

    final isPackageMode = _selectionMode == SelectionMode.packages;
    final hasSelection = isPackageMode
        ? (_selectedPackage != null || _selectedTests.isNotEmpty)
        : selectedItems.isNotEmpty;

    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isPackageMode
                    ? 'Please select a package'
                    : 'Please select at least one test',
                style: GoogleFonts.sora())),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load your profile. Please try again.',
              style: GoogleFonts.sora()),
        ),
      );
      return;
    }

    if (user.name.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add your name to your profile before booking.',
            style: GoogleFonts.sora(),
          ),
          action: SnackBarAction(
            label: 'Edit Profile',
            onPressed: () => context.push('/profile'),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (_selectionMode == SelectionMode.packages &&
        (_selectedPackage == null || _selectedPackage!.price <= 0)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Package price is unavailable. Please try again.',
            style: GoogleFonts.sora(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _showAddressError = _addressController.text.trim().isEmpty;
    });

    if (_addressController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final details = await DeliveryDetailsService.getDetails();

      if (!mounted) return;

      if (!details.isComplete) {
        setState(() => _isSubmitting = false);
        _showDeliveryDetailsSheet(
          tests: tests,
          user: user,
          existingDetails: details,
        );
        return;
      }

      _addressController.text = details.address;
      setState(() => _mobileNumber = details.phone);
      await _createLabOrder(tests, user, details);
    } catch (e, stack) {
      if (!mounted) return;
      if (_isSubmitting) {
        setState(() => _isSubmitting = false);
      }
      debugPrint('[LabBooking] Error: $e');
      debugPrint('[LabBooking] Stack: $stack');
      final raw = e.toString();
      final message = raw.contains('Missing mobile number')
          ? 'Please complete your mobile number in delivery details before booking a lab test.'
          : raw.contains('Missing required user')
              ? 'Please complete your profile before booking.'
              : raw.contains('Invalid test count')
                  ? 'Please select at least one test.'
                  : raw.contains('Invalid total amount')
                      ? 'Total amount is invalid. Please try again.'
                      : raw.contains('permission-denied')
                          ? 'Booking failed due to a permissions error. Please contact support.'
                          : 'Failed to book lab test. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: GoogleFonts.sora())),
      );
    }
  }

  Future<void> _createLabOrder(
    List<LabTestModel> tests,
    UserModel user,
    DeliveryDetails details,
  ) async {
    setState(() => _isSubmitting = true);

    try {
      final selectedItems = _getSelectedTestItems(tests);
      final totalAmount = _getTotalAmount(tests);

      String? notesText = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      if (_selectionMode == SelectionMode.packages &&
          _selectedPackage != null) {
        final packageNote = 'Package: ${_selectedPackage!.name}';
        notesText =
            notesText != null ? '$packageNote | $notesText' : packageNote;
      }

      if (_selectedDate != null && _selectedTimeSlot != null) {
        final dateStr =
            '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
        final slotNote = 'Slot: $dateStr $_selectedTimeSlot';
        notesText = notesText != null ? '$notesText | $slotNote' : slotNote;
      }

      final order = LabOrderModel(
        orderId: '',
        userId: user.uid,
        userPhone: details.phone,
        userName: user.name,
        homeCollectionAddress: details.address,
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
          content:
              Text('Lab order placed successfully!', style: GoogleFonts.sora()),
          backgroundColor: AppColors.labPrimary,
        ),
      );

      context.pushReplacement('/lab-order/$orderId');
    } catch (e, stack) {
      if (!mounted) return;
      debugPrint('[LabBooking] Error: $e');
      debugPrint('[LabBooking] Stack: $stack');
      final raw = e.toString();
      final message = raw.contains('Missing mobile number')
          ? 'Please complete your mobile number in delivery details before booking a lab test.'
          : raw.contains('Missing required user')
              ? 'Please complete your profile before booking.'
              : raw.contains('Invalid test count')
                  ? 'Please select at least one test.'
                  : raw.contains('Invalid total amount')
                      ? 'Total amount is invalid. Please try again.'
                      : raw.contains('permission-denied')
                          ? 'Booking failed due to a permissions error. Please contact support.'
                          : 'Failed to book lab test. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: GoogleFonts.sora())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null;
      _showSlotError = false;
    });
  }

  void _onTimeSlotSelected(String slot) {
    setState(() {
      _selectedTimeSlot = slot;
      _showSlotError = false;
    });
  }

  void _onEditAddress() async {
    final details = await DeliveryDetailsService.getDetails();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryDetailsSheet(
        existingDetails: details,
        onSaved: (newDetails) async {
          setState(() {
            _addressController.text = newDetails.address;
            _mobileNumber = newDetails.phone;
            _showAddressError = false;
          });
        },
      ),
    );
  }

  String? get _formattedDate {
    if (_selectedDate == null) return null;
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
    return '${weekdays[_selectedDate!.weekday - 1]}, ${months[_selectedDate!.month - 1]} ${_selectedDate!.day}';
  }

  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(labTestsProvider);
    final packagesAsync = ref.watch(labPackagesProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final tests = testsAsync.valueOrNull ?? [];
    final packages = packagesAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookingHeader(
                      title: _selectionMode == SelectionMode.packages &&
                              _selectedPackage != null
                          ? 'Confirm Booking'
                          : 'Book Lab Tests',
                      subtitle: _selectionMode == SelectionMode.packages &&
                              _selectedPackage != null
                          ? 'Review and confirm your package booking'
                          : 'Review your details before booking',
                      isPackageBooking:
                          _selectionMode == SelectionMode.packages,
                    ),
                    const SizedBox(height: 20),
                    testsAsync.when(
                      data: (testList) => packagesAsync.when(
                        data: (packageList) => TestSelector(
                          tests: testList,
                          packages: packageList,
                          initialMode: _selectionMode,
                          onModeChanged: (mode) {
                            setState(() {
                              _selectionMode = mode;
                            });
                          },
                          onPackageSelected: (package) {
                            setState(() {
                              _selectedPackage = package;
                            });
                          },
                          onTestsSelected: (selected) {
                            setState(() {
                              _selectedTests.clear();
                              _selectedTests.addAll(selected);
                            });
                          },
                          selectedPackage: _selectedPackage,
                          selectedTests: _selectedTests,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                    const SizedBox(height: 16),
                    AddressCard(
                      address: _addressController.text,
                      mobileNumber: _mobileNumber,
                      onEdit: _onEditAddress,
                      hasError: _showAddressError,
                    ),
                    const SizedBox(height: 16),
                    SlotSelector(
                      selectedDate: _selectedDate,
                      selectedTimeSlot: _selectedTimeSlot,
                      onDateSelected: _onDateSelected,
                      onTimeSlotSelected: _onTimeSlotSelected,
                      hasError: _showSlotError,
                    ),
                    const SizedBox(height: 16),
                    PaymentSummary(
                      testCount: _selectionMode == SelectionMode.packages &&
                              _selectedPackage != null
                          ? _selectedPackage!.testCount
                          : _getSelectedTestItems(tests).length,
                      totalAmount: _getTotalAmount(tests),
                      scheduledDate: _formattedDate,
                      scheduledTime: _selectedTimeSlot,
                    ),
                    const SizedBox(height: 16),
                    _buildNotesSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            ConfirmButton(
              isLoading: _isSubmitting,
              isEnabled: (_selectionMode == SelectionMode.packages &&
                      (_selectedPackage != null ||
                          _selectedTests.isNotEmpty)) ||
                  (_selectionMode == SelectionMode.individualTests &&
                      _selectedTests.values.any((v) => v)),
              onPressed: () => _submitOrder(tests, user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.note_rounded,
                    color: Color(0xFFFB8C00),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Additional Notes',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'Optional',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Any special instructions (e.g., I am diabetic)...',
                hintStyle: GoogleFonts.sora(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8ECE7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8ECE7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.labPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              style: GoogleFonts.sora(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
