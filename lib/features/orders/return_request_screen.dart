import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/service_providers.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/notification_service.dart';

class ReturnRequestScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ReturnRequestScreen({super.key, required this.orderId});

  @override
  ConsumerState<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final _descController = TextEditingController();
  String _reason = 'Damaged product';
  final _reasons = [
    'Damaged product',
    'Wrong item delivered',
    'Quality issue',
    'Expired product',
    'Other',
  ];
  Set<String> _selectedItems = {};
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit(OrderModel order) async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item to return')),
      );
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final requestId = await firestoreService.submitReturnRequest({
        'orderId': widget.orderId,
        'userId': user.uid,
        'userPhone': user.phone,
        'items': _selectedItems.toList(),
        'reason': _reason,
        'description': _descController.text.trim(),
      });

      // Notify admin
      await firestoreService.saveNotificationToFirestore(
        userId: 'admin',
        title: 'New Return Request',
        body: 'Order #${widget.orderId.substring(0, 8)} return requested',
        type: 'return_request',
        orderId: widget.orderId,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Return request submitted! We\'ll review it within 24 hours.',
              style: GoogleFonts.sora(),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.grey.shade200, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Request Return',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Select Items to Return'),
                const SizedBox(height: 8),
                ...order.items.map((item) => CheckboxListTile(
                      value: _selectedItems.contains(item.medicineName),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selectedItems.add(item.medicineName);
                        } else {
                          _selectedItems.remove(item.medicineName);
                        }
                      }),
                      title: Text(
                        item.medicineName,
                        style: GoogleFonts.sora(fontSize: 13),
                      ),
                      subtitle: Text(
                        'Qty: ${item.quantity}',
                        style: GoogleFonts.sora(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    )),
                const SizedBox(height: 16),
                _section('Reason for Return'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: _reasons.map((reason) {
                      final isLast = reason == _reasons.last;
                      return Column(
                        children: [
                          RadioListTile<String>(
                            value: reason,
                            groupValue: _reason,
                            onChanged: (v) => setState(() => _reason = v!),
                            title: Text(reason,
                                style: GoogleFonts.sora(fontSize: 13)),
                            activeColor: AppColors.primary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          if (!isLast) const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _section('Description'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: GoogleFonts.sora(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue...',
                    hintStyle: GoogleFonts.sora(
                        fontSize: 13, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Submit Return Request',
                            style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: GoogleFonts.sora(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
