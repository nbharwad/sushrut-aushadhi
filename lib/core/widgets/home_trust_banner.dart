import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class HomeTrustBanner extends StatelessWidget {
  const HomeTrustBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.08),
              AppColors.primaryLight.withOpacity(0.6),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border(
            bottom: BorderSide(color: AppColors.primary.withOpacity(0.12), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _TrustBadge(
                icon: Icons.verified_rounded,
                label: 'Licensed',
                color: AppColors.primary,
              ),
              _buildDivider(),
              _TrustBadge(
                icon: Icons.medical_services_rounded,
                label: 'Pharmacist',
                color: AppColors.primary,
              ),
              _buildDivider(),
              _TrustBadge(
                icon: Icons.local_shipping_rounded,
                label: '2Hr Delivery',
                color: AppColors.primary,
              ),
              _buildDivider(),
              _TrustBadge(
                icon: Icons.inventory_2_rounded,
                label: '19K+ Meds',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primary.withOpacity(0.3),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, size: 14, color: color),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class StoreClosedBanner extends StatelessWidget {
  final String storeOpenTime;

  const StoreClosedBanner({
    super.key,
    required this.storeOpenTime,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          border: Border(
            bottom: BorderSide(color: Colors.red.withOpacity(0.15), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.access_time, color: Colors.red, size: 15),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Store is currently closed. Opens at $storeOpenTime. You can still browse!',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
