import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/health_record_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_records_provider.dart';
import '../../services/health_records_service.dart';
import 'upload_health_record_sheet.dart';

class HealthRecordsScreen extends ConsumerWidget {
  const HealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(healthRecordsProvider);

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
          'Health Records',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded,
                color: AppColors.primary, size: 24),
            onPressed: () => _openUploadSheet(context),
          ),
        ],
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    'No Health Records',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload lab reports, X-rays, and more.',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _openUploadSheet(context),
                    icon: const Icon(Icons.upload_outlined),
                    label: Text('Upload Record',
                        style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _RecordCard(
                record: records[index],
                onTap: () => _openRecord(context, records[index]),
                onDelete: () => _deleteRecord(context, ref, records[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUploadSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UploadHealthRecordSheet(),
    );
  }

  void _openRecord(BuildContext context, HealthRecordModel record) {
    if (record.fileType == 'image') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(record.title,
                style: GoogleFonts.sora(color: Colors.white, fontSize: 14)),
          ),
          body: PhotoView(imageProvider: NetworkImage(record.fileUrl)),
        ),
      ));
    } else {
      launchUrl(Uri.parse(record.fileUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteRecord(
      BuildContext context, WidgetRef ref, HealthRecordModel record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Record', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
        content: Text('Delete "${record.title}"?', style: GoogleFonts.sora()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.sora())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: GoogleFonts.sora(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    await HealthRecordsService().deleteRecord(
      userId: uid,
      recordId: record.id,
      fileUrl: record.fileUrl,
    );
  }
}

class _RecordCard extends StatelessWidget {
  final HealthRecordModel record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecordCard(
      {required this.record, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _typeBg(record.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(record.type),
                  color: _typeColor(record.type), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${record.typeDisplayName} • ${DateFormat('d MMM yyyy').format(record.date)}',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (record.notes != null && record.notes!.isNotEmpty)
                    Text(
                      record.notes!,
                      style: GoogleFonts.sora(
                          fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'lab_report':
        return const Color(0xFFE3F2FD);
      case 'xray':
        return const Color(0xFFF3E5F5);
      case 'discharge':
        return const Color(0xFFFFF8E1);
      default:
        return AppColors.backgroundAlt;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'lab_report':
        return const Color(0xFF1E88E5);
      case 'xray':
        return const Color(0xFF8E24AA);
      case 'discharge':
        return const Color(0xFFFFB300);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'lab_report':
        return Icons.science_outlined;
      case 'xray':
        return Icons.image_outlined;
      case 'discharge':
        return Icons.local_hospital_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}
