import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../models/lab_package_model.dart';
import '../../providers/lab_providers.dart';

class LabPackageDetailScreen extends ConsumerWidget {
  final String packageId;

  const LabPackageDetailScreen({super.key, required this.packageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageAsync = ref.watch(labPackageProvider(packageId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: packageAsync.when(
        data: (package) {
          if (package == null) return _buildNotFound(context);
          return _buildContent(context, package);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.labPrimary)),
        error: (e, _) => _buildError(context, e.toString()),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.labPrimary,
        foregroundColor: Colors.white,
        title: Text('Package Not Found', style: GoogleFonts.sora()),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Lab package not found', style: GoogleFonts.sora()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.labPrimary,
        foregroundColor: Colors.white,
        title: Text('Error', style: GoogleFonts.sora()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $error', style: GoogleFonts.sora()),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LabPackageModel package) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context, package),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(package),
                      const SizedBox(height: 16),
                      if (package.preparationSteps.isNotEmpty) ...[
                        _buildPreparationCard(package),
                        const SizedBox(height: 16),
                      ],
                      _buildTestsIncludedCard(package),
                      if (package.parameters.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildParametersCard(package),
                      ],
                      const SizedBox(height: 16),
                      _buildInfoCard(package),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BookButton(package: package),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, LabPackageModel package) {
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
              if (context.canPop())
                context.pop();
              else
                context.go('/home');
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              package.name,
              style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(LabPackageModel package) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.labPrimaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.biotech,
                    color: AppColors.labPrimary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: GoogleFonts.sora(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (package.shortDescription.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        package.shortDescription,
                        style: GoogleFonts.sora(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (package.hasDiscount) ...[
                Text(
                  '\u20B9${package.originalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.discountRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${package.discountPercent.toStringAsFixed(0)}% OFF',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.discountRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '\u20B9${package.price.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.labPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoBadge(Icons.science, '${package.testCount} Tests'),
              _infoBadge(Icons.timer, package.tatDisplay),
              _infoBadge(Icons.water_drop, package.sampleType),
              if (package.fastingRequired)
                _infoBadge(Icons.no_food, '${package.fastingHours}h Fasting'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.labPrimaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.labPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.sora(
                fontSize: 12,
                color: AppColors.labPrimary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationCard(LabPackageModel package) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFFF57F17), size: 20),
              const SizedBox(width: 8),
              Text(
                'Before Your Test',
                style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF57F17)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...package.preparationSteps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: Color(0xFFF57F17)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(step,
                          style: GoogleFonts.sora(fontSize: 13, height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTestsIncludedCard(LabPackageModel package) {
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
              const Icon(Icons.list_alt, color: AppColors.labPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tests Included (${package.testCount})',
                style:
                    GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...package.testNames.map((name) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.labPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name, style: GoogleFonts.sora(fontSize: 14)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildParametersCard(LabPackageModel package) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECE7)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading:
              const Icon(Icons.analytics_outlined, color: AppColors.labPrimary),
          title: Text(
            "What's Measured (${package.parameters.length} parameters)",
            style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: package.parameters
                  .map((param) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.labPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(param,
                            style: GoogleFonts.sora(
                                fontSize: 12, color: AppColors.labPrimary)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(LabPackageModel package) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Column(
        children: [
          _infoRow(Icons.home, 'Home Collection',
              'Phlebotomist visits your address'),
          const Divider(height: 24),
          _infoRow(Icons.timer, 'Report in', package.tatDisplay),
          const Divider(height: 24),
          _infoRow(Icons.water_drop, 'Sample Type', package.sampleType),
          const Divider(height: 24),
          _infoRow(Icons.payment, 'Payment', 'Cash on Collection'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.labPrimaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.labPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.sora(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(value,
            style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// Floating book button shown separately (placed in Stack)
class _BookButton extends StatelessWidget {
  final LabPackageModel package;

  const _BookButton({required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.push('/lab/book', extra: {
                'packageId': package.id,
                'testIds': package.testIds,
                'packageName': package.name,
                'packagePrice': package.price,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.labPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Book This Package  \u20B9${package.price.toStringAsFixed(0)}',
              style:
                  GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
