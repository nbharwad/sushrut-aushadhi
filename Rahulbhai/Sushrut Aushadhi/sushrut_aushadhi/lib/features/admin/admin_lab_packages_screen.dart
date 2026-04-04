import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../models/lab_package_model.dart';
import '../../providers/lab_providers.dart';

class AdminLabPackagesScreen extends ConsumerStatefulWidget {
  const AdminLabPackagesScreen({super.key});

  @override
  ConsumerState<AdminLabPackagesScreen> createState() => _AdminLabPackagesScreenState();
}

class _AdminLabPackagesScreenState extends ConsumerState<AdminLabPackagesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(allLabPackagesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPackageForm(context, null),
        backgroundColor: AppColors.labPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Package', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildSearchBar(),
            Expanded(
              child: packagesAsync.when(
                data: (packages) {
                  final filtered = _searchQuery.isEmpty
                      ? packages
                      : packages.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text('No packages found', style: GoogleFonts.sora(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _AdminPackageTile(
                      package: filtered[index],
                      onEdit: () => _showPackageForm(context, filtered[index]),
                      onDelete: () => _deletePackage(filtered[index]),
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
            'Manage Lab Packages',
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
          hintText: 'Search packages...',
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
      await ref.read(labServiceProvider).toggleLabPackageActive(id, active);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.sora())),
        );
      }
    }
  }

  Future<void> _deletePackage(LabPackageModel package) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Package', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${package.name}"? This cannot be undone.',
          style: GoogleFonts.sora(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.sora()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.sora(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(labServiceProvider).deleteLabPackage(package.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Package deleted', style: GoogleFonts.sora()),
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
      }
    }
  }

  void _showPackageForm(BuildContext context, LabPackageModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackageFormSheet(
        existing: existing,
        ref: ref,
      ),
    );
  }
}

class _AdminPackageTile extends StatelessWidget {
  final LabPackageModel package;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _AdminPackageTile({
    required this.package,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECE7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(package.name, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              Switch(
                value: package.active,
                onChanged: onToggle,
                activeColor: AppColors.labPrimary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge(package.category, AppColors.labPrimaryLight, AppColors.labPrimary),
              _badge('${package.testCount} tests', const Color(0xFFE8F5E9), const Color(0xFF388E3C)),
              _badge(package.tatDisplay, const Color(0xFFFFF3E0), const Color(0xFFF57F17)),
              _badge('\u20B9${package.price.toStringAsFixed(0)}', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: Text('Edit', style: GoogleFonts.sora(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppColors.labPrimary),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text('Delete', style: GoogleFonts.sora(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.sora(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _PackageFormSheet extends ConsumerStatefulWidget {
  final LabPackageModel? existing;
  final WidgetRef ref;

  const _PackageFormSheet({this.existing, required this.ref});

  @override
  ConsumerState<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends ConsumerState<_PackageFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _originalPriceCtrl;
  late final TextEditingController _tatCtrl;
  late final TextEditingController _sampleTypeCtrl;
  late final TextEditingController _sortOrderCtrl;

  String _category = 'popular';
  bool _fastingRequired = false;
  int _fastingHours = 10;
  bool _active = true;
  bool _popular = false;
  bool _isSubmitting = false;
  final List<String> _prepSteps = [];
  final TextEditingController _prepStepCtrl = TextEditingController();
  final Set<String> _selectedTestIds = {};

  static const _categories = [
    'popular', 'blood', 'diabetes', 'thyroid', 'vitamins', 'heart', 'women', 'other'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.shortDescription ?? '');
    _priceCtrl = TextEditingController(text: e?.price.toStringAsFixed(0) ?? '');
    _originalPriceCtrl = TextEditingController(text: e?.originalPrice.toStringAsFixed(0) ?? '');
    _tatCtrl = TextEditingController(text: e?.tatHours.toString() ?? '24');
    _sampleTypeCtrl = TextEditingController(text: e?.sampleType ?? 'Blood');
    _sortOrderCtrl = TextEditingController(text: e?.sortOrder.toString() ?? '99');
    _category = e?.category ?? 'popular';
    _fastingRequired = e?.fastingRequired ?? false;
    _fastingHours = e?.fastingHours ?? 10;
    _active = e?.active ?? true;
    _popular = e?.popular ?? false;
    if (e != null) {
      _prepSteps.addAll(e.preparationSteps);
      _selectedTestIds.addAll(e.testIds);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _tatCtrl.dispose();
    _sampleTypeCtrl.dispose();
    _sortOrderCtrl.dispose();
    _prepStepCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one test', style: GoogleFonts.sora())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final allTests = ref.read(allLabTestsStreamProvider).valueOrNull ?? [];
      final selectedTests = allTests.where((t) => _selectedTestIds.contains(t.id)).toList();

      final package = LabPackageModel(
        id: widget.existing?.id ?? '',
        name: _nameCtrl.text.trim(),
        shortDescription: _descCtrl.text.trim(),
        category: _category,
        sampleType: _sampleTypeCtrl.text.trim().isEmpty ? 'Blood' : _sampleTypeCtrl.text.trim(),
        iconName: 'biotech',
        price: double.tryParse(_priceCtrl.text) ?? 0,
        originalPrice: double.tryParse(_originalPriceCtrl.text) ?? 0,
        tatHours: int.tryParse(_tatCtrl.text) ?? 24,
        fastingHours: _fastingRequired ? _fastingHours : 0,
        sortOrder: int.tryParse(_sortOrderCtrl.text) ?? 99,
        testCount: selectedTests.length,
        fastingRequired: _fastingRequired,
        active: _active,
        popular: _popular,
        testIds: selectedTests.map((t) => t.id).toList(),
        testNames: selectedTests.map((t) => t.name).toList(),
        preparationSteps: List.from(_prepSteps),
        parameters: [],
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final svc = ref.read(labServiceProvider);
      if (widget.existing == null) {
        await svc.createLabPackage(package);
      } else {
        await svc.updateLabPackage(package.id, package.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null ? 'Package created' : 'Package updated',
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
    final testsAsync = ref.watch(allLabTestsStreamProvider);
    final allTests = testsAsync.valueOrNull ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
                  widget.existing == null ? 'Add Lab Package' : 'Edit Lab Package',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Package Name', _nameCtrl, required: true),
                    const SizedBox(height: 12),
                    _field('Short Description', _descCtrl),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('Price (₹)', _priceCtrl, required: true, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Original Price (₹)', _originalPriceCtrl, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('TAT (hours)', _tatCtrl, required: true, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Sample Type', _sampleTypeCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('Sort Order', _sortOrderCtrl, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: _inputDecoration('Category'),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.sora()))).toList(),
                            onChanged: (v) => setState(() => _category = v!),
                            style: GoogleFonts.sora(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _fastingRequired,
                          onChanged: (v) => setState(() => _fastingRequired = v!),
                          activeColor: AppColors.labPrimary,
                        ),
                        Text('Fasting Required', style: GoogleFonts.sora()),
                        if (_fastingRequired) ...[
                          const Spacer(),
                          Text('Hours:', style: GoogleFonts.sora()),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: _fastingHours.toString(),
                              onChanged: (v) => _fastingHours = int.tryParse(v) ?? 10,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(''),
                              style: GoogleFonts.sora(),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _active,
                          onChanged: (v) => setState(() => _active = v!),
                          activeColor: AppColors.labPrimary,
                        ),
                        Text('Active', style: GoogleFonts.sora()),
                        const SizedBox(width: 16),
                        Checkbox(
                          value: _popular,
                          onChanged: (v) => setState(() => _popular = v!),
                          activeColor: AppColors.labPrimary,
                        ),
                        Text('Popular', style: GoogleFonts.sora()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionHeader('Select Tests'),
                    const SizedBox(height: 8),
                    if (testsAsync.isLoading)
                      const Center(child: CircularProgressIndicator(color: AppColors.labPrimary))
                    else if (allTests.isEmpty)
                      Text('No tests available. Add tests first.', style: GoogleFonts.sora(color: AppColors.textSecondary))
                    else
                      ...allTests.map((test) {
                        final isSelected = _selectedTestIds.contains(test.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedTestIds.add(test.id);
                            } else {
                              _selectedTestIds.remove(test.id);
                            }
                          }),
                          title: Text(test.name, style: GoogleFonts.sora(fontSize: 13)),
                          subtitle: Text('\u20B9${test.price.toStringAsFixed(0)} • ${test.sampleType}', style: GoogleFonts.sora(fontSize: 11)),
                          activeColor: AppColors.labPrimary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                    const SizedBox(height: 16),
                    _sectionHeader('Preparation Steps'),
                    const SizedBox(height: 8),
                    ..._prepSteps.asMap().entries.map((entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text('${entry.key + 1}.', style: GoogleFonts.sora()),
                      title: Text(entry.value, style: GoogleFonts.sora(fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                        onPressed: () => setState(() => _prepSteps.removeAt(entry.key)),
                      ),
                    )),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _prepStepCtrl,
                            decoration: _inputDecoration('Add preparation step...'),
                            style: GoogleFonts.sora(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final step = _prepStepCtrl.text.trim();
                            if (step.isNotEmpty) {
                              setState(() => _prepSteps.add(step));
                              _prepStepCtrl.clear();
                            }
                          },
                          icon: const Icon(Icons.add_circle, color: AppColors.labPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                                widget.existing == null ? 'Create Package' : 'Update Package',
                                style: GoogleFonts.sora(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool required = false, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
      decoration: _inputDecoration(label),
      style: GoogleFonts.sora(),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.sora(color: AppColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.labPrimary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold));
  }
}
