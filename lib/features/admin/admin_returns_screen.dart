import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/service_providers.dart';
import '../../models/return_request_model.dart';
import '../../providers/return_provider.dart';

class AdminReturnsScreen extends ConsumerWidget {
  const AdminReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(adminReturnRequestsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Return Requests',
          style: GoogleFonts.sora(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No return requests yet.',
                style: GoogleFonts.sora(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _ReturnCard(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}

class _ReturnCard extends ConsumerWidget {
  final ReturnRequestModel request;
  const _ReturnCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusBg(request.status),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${request.orderId.substring(0, 8)}',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        request.userPhone,
                        style: GoogleFonts.sora(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(request.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.statusDisplayName,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(request.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Reason:', request.reason),
                if (request.description.isNotEmpty)
                  _row('Details:', request.description),
                _row('Items:', request.items.join(', ')),
                _row(
                    'Submitted:',
                    DateFormat('d MMM yyyy, h:mm a')
                        .format(request.createdAt)),
                if (request.adminNote != null)
                  _row('Admin Note:', request.adminNote!),
                if (request.status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(
                              context, ref, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            foregroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Reject',
                              style: GoogleFonts.sora(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(
                              context, ref, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Approve',
                              style: GoogleFonts.sora(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  GoogleFonts.sora(fontSize: 11, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String status) async {
    String? note;
    if (status == 'rejected') {
      final ctrl = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Rejection Note', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Reason for rejection...'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('Submit')),
          ],
        ),
      );
      if (note == null) return;
    }

    await ref.read(firestoreServiceProvider).updateReturnStatus(
          requestId: request.id,
          status: status,
          adminNote: note,
        );

    // Notify user
    await ref.read(firestoreServiceProvider).saveNotificationToFirestore(
          userId: request.userId,
          title: 'Return Request ${status == 'approved' ? 'Approved' : 'Rejected'}',
          body: status == 'approved'
              ? 'Your return request has been approved. Refund will be processed.'
              : 'Your return request was not approved. ${note ?? ''}',
          type: 'return_status',
          orderId: request.orderId,
        );
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'approved':
        return AppColors.primaryLight;
      case 'rejected':
        return const Color(0xFFFFEBEE);
      case 'completed':
        return const Color(0xFFE8F5E9);
      default:
        return AppColors.backgroundAlt;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.primary;
      case 'rejected':
        return AppColors.error;
      case 'completed':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.accent;
    }
  }
}
