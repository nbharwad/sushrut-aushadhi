import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../models/lab_order_model.dart';
import '../../providers/lab_providers.dart';

class AdminLabTestsScreen extends ConsumerStatefulWidget {
  const AdminLabTestsScreen({super.key});

  @override
  ConsumerState<AdminLabTestsScreen> createState() => _AdminLabTestsScreenState();
}

class _AdminLabTestsScreenState extends ConsumerState<AdminLabTestsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(allLabTestsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTestForm(context, null),
        backgroundColor: AppColors.labPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Test', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildSearchBar(),
            Expanded(
              child: testsAsync.when(
                data: (tests) {
                  final filtered = _searchQuery.isEmpty
                      ? tests
                      : tests.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.science_outlined, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text('No tests found', style: GoogleFonts.sora(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _AdminTestTile(
                      test: filtered[index],
                      onEdit: () => _showTestForm(context, filtered[index]),
                      onToggle: (val) => _toggleActive(filtered[index].id, val),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.labPrimary)),
                error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.sora())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
              if (context.canPop()) context.pop();
              else context.go('/admin');
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            'Manage Lab Tests',
            style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search tests...',
          hintStyle: GoogleFonts.sora(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: AppColors.labPrimary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.sora(),
      ),
    );
  }

  Future<void> _toggleActive(String id, bool active) async {
    try {
      await ref.read(labServiceProvider).toggleLabTestActive(id, active);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.sora())),
        );
      }
    }
  }

  void _showTestForm(BuildContext context, LabTestModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TestFormSheet(existing: existing, ref: ref),
    );
  }
}

class _AdminTestTile extends StatelessWidget {
  final LabTestModel test;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _AdminTestTile({required this.test, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.labPrimaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.science_outlined, color: AppColors.labPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.name, style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _badge(test.category),
                    const SizedBox(width: 6),
                    Text(
                      '\u20B9${test.price.toStringAsFixed(0)} • ${test.tatHours}h',
                      style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: test.active,
                onChanged: onToggle,
                activeColor: AppColors.labPrimary,
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(foregroundColor: AppColors.labPrimary, padding: EdgeInsets.zero),
                child: Text('Edit', style: GoogleFonts.sora(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.labPrimaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.sora(fontSize: 10, color: AppColors.labPrimary, fontWeight: FontWeight.w600)),
    );
  }
}

class _TestFormSheet extends ConsumerStatefulWidget {
  final LabTestModel? existing;
  final WidgetRef ref;

  const _TestFormSheet({this.existing, required this.ref});

  @override
  ConsumerState<_TestFormSheet> createState() => _TestFormSheetState();
}

class _TestFormSheetState extends ConsumerState<_TestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _tatCtrl;
  late final TextEditingController _sampleTypeCtrl;
  bool _active = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _priceCtrl = TextEditingController(text: e?.price.toStringAsFixed(0) ?? '');
    _tatCtrl = TextEditingController(text: e?.tatHours.toString() ?? '24');
    _sampleTypeCtrl = TextEditingController(text: e?.sampleType ?? 'Blood');
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _tatCtrl.dispose();
    _sampleTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final test = LabTestModel(
        id: widget.existing?.id ?? '',
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? 0,
        tatHours: int.tryParse(_tatCtrl.text) ?? 24,
        sampleType: _sampleTypeCtrl.text.trim().isEmpty ? 'Blood' : _sampleTypeCtrl.text.trim(),
        active: _active,
      );

      final svc = ref.read(labServiceProvider);
      if (widget.existing == null) {
        await svc.createLabTest(test);
      } else {
        await svc.updateLabTest(test.id, test.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null ? 'Test created' : 'Test updated',
              style: GoogleFonts.sora(),
            ),
            backgroundColor: AppColors.labPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.sora())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.labPrimary, AppColors.labSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.existing == null ? 'Add Lab Test' : 'Edit Lab Test',
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field('Test Name', _nameCtrl, required: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('Category', _categoryCtrl, required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Sample Type', _sampleTypeCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('Price (₹)', _priceCtrl, required: true, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('TAT (hours)', _tatCtrl, required: true, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _active,
                          onChanged: (v) => setState(() => _active = v!),
                          activeColor: AppColors.labPrimary,
                        ),
                        Text('Active', style: GoogleFonts.sora()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.labPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                widget.existing == null ? 'Create Test' : 'Update Test',
                                style: GoogleFonts.sora(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool required = false, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.sora(color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.labPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: GoogleFonts.sora(),
    );
  }
}
