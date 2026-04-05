import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/lab_order_model.dart';
import '../../../models/lab_package_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/lab_providers.dart';

const _kCategories = [
  ('all', 'All'),
  ('blood', 'Blood Tests'),
  ('diabetes', 'Diabetes'),
  ('thyroid', 'Thyroid'),
  ('vitamins', 'Vitamins'),
  ('heart', 'Heart'),
  ('women', 'Women'),
];

class LabHomeWidget extends ConsumerStatefulWidget {
  const LabHomeWidget({super.key});

  @override
  ConsumerState<LabHomeWidget> createState() => _LabHomeWidgetState();
}

class _LabHomeWidgetState extends ConsumerState<LabHomeWidget> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(),
        _buildPrescriptionCard(),
        _buildCategoryChips(),
        _buildPackagesSection(),
        _buildIndividualTestsSection(),
        _buildMyOrdersButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.labPrimary, AppColors.labSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Lab Tests\nat Home',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sample collection from your doorstep',
                  style: GoogleFonts.sora(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/lab/book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.labPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Book Now',
                    style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.biotech, color: Colors.white, size: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return GestureDetector(
      onTap: () => context.push('/prescription?type=lab'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.labPrimaryLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.labPrimary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.labPrimaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.upload_file, color: AppColors.labPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Prescription',
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'We\'ll book the recommended tests for you',
                    style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse by Category',
            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kCategories.map((cat) {
                final isSelected = _selectedCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.labPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.labPrimary : const Color(0xFFE8ECE7),
                        ),
                      ),
                      child: Text(
                        cat.$2,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesSection() {
    final packagesAsync = ref.watch(labPackagesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Packages',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedCategory = 'all'),
                  child: Text(
                    'See All',
                    style: GoogleFonts.sora(color: AppColors.labPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          packagesAsync.when(
            data: (packages) {
              final filtered = _selectedCategory == 'all'
                  ? packages
                  : packages.where((p) => p.category == _selectedCategory).toList();

              if (filtered.isEmpty) {
                return Container(
                  height: 160,
                  alignment: Alignment.center,
                  child: Text(
                    'No packages in this category',
                    style: GoogleFonts.sora(color: AppColors.textSecondary),
                  ),
                );
              }

              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  padding: const EdgeInsets.only(right: 16),
                  itemBuilder: (context, index) => _LabPackageCard(package: filtered[index]),
                ),
              );
            },
            loading: () => SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                padding: const EdgeInsets.only(right: 16),
                itemBuilder: (context, index) => _PackageCardShimmer(),
              ),
            ),
            error: (e, _) => Container(
              height: 80,
              alignment: Alignment.center,
              child: Text(
                'Could not load packages',
                style: GoogleFonts.sora(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualTestsSection() {
    final testsAsync = ref.watch(labTestsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Individual Tests',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/lab/book'),
                child: Text(
                  'Book Tests',
                  style: GoogleFonts.sora(color: AppColors.labPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          testsAsync.when(
            data: (tests) {
              if (tests.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECE7)),
                  ),
                  child: Center(
                    child: Text('No tests available', style: GoogleFonts.sora(color: AppColors.textSecondary)),
                  ),
                );
              }
              // Show first 5 tests
              final displayed = tests.take(5).toList();
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8ECE7)),
                ),
                child: Column(
                  children: [
                    ...displayed.asMap().entries.map((entry) {
                      final isLast = entry.key == displayed.length - 1;
                      return _IndividualTestTile(test: entry.value, isLast: isLast);
                    }),
                    if (tests.length > 5)
                      InkWell(
                        onTap: () => context.push('/lab/book'),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View all ${tests.length} tests',
                                style: GoogleFonts.sora(
                                  color: AppColors.labPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.labPrimary, size: 18),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => Container(
              height: 60,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.labPrimary),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyOrdersButton() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/lab/orders'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECE7)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.labPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.labPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Lab Orders',
                      style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'View your test bookings and results',
                      style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabPackageCard extends StatelessWidget {
  final LabPackageModel package;

  const _LabPackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/lab/package/${package.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECE7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  child: const Icon(Icons.biotech, color: AppColors.labPrimary, size: 20),
                ),
                const Spacer(),
                if (package.hasDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.discountRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${package.discountPercent.toStringAsFixed(0)}% OFF',
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        color: AppColors.discountRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              package.name,
              style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${package.testCount} tests',
                  style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  package.tatDisplay,
                  style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Spacer(),
            if (package.hasDiscount)
              Text(
                '\u20B9${package.originalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            Row(
              children: [
                Text(
                  '\u20B9${package.price.toStringAsFixed(0)}',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.labPrimary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.labPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Book',
                    style: GoogleFonts.sora(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 10),
          Container(height: 14, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(width: 80, height: 12, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(4))),
          const Spacer(),
          Container(height: 20, width: 70, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}

class _IndividualTestTile extends StatelessWidget {
  final LabTestModel test;
  final bool isLast;

  const _IndividualTestTile({required this.test, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE8ECE7))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.labPrimaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.science_outlined, color: AppColors.labPrimary, size: 18),
        ),
        title: Text(test.name, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${test.sampleType} • ${test.tatHours}h report',
          style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\u20B9${test.price.toStringAsFixed(0)}',
              style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.labPrimary),
            ),
          ],
        ),
        onTap: () => context.push('/lab/book'),
      ),
    );
  }
}
