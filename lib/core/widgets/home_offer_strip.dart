import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeOfferStrip extends StatelessWidget {
  const HomeOfferStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 14 : 18,
                vertical: isCompact ? 14 : 16,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF6E0), Color(0xFFFFF0C5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE8A020).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8A020).withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circle
                  Positioned(
                    right: -10,
                    top: -20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE8A020).withOpacity(0.08),
                      ),
                    ),
                  ),
                  isCompact ? _buildCompactLayout() : _buildNormalLayout(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIconBadge(isCompact: true),
            const SizedBox(width: 10),
            Expanded(child: _buildOfferText(isCompact: true)),
          ],
        ),
        const SizedBox(height: 12),
        _buildOfferCode(isCompact: true),
      ],
    );
  }

  Widget _buildNormalLayout() {
    return Row(
      children: [
        _buildIconBadge(),
        const SizedBox(width: 14),
        Expanded(child: _buildOfferText()),
        const SizedBox(width: 14),
        _buildOfferCode(),
      ],
    );
  }

  Widget _buildIconBadge({bool isCompact = false}) {
    return Container(
      width: isCompact ? 36 : 42,
      height: isCompact ? 36 : 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A00).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.local_offer_rounded,
          size: isCompact ? 20 : 22,
          color: const Color(0xFFFF8A00),
        ),
      ),
    );
  }

  Widget _buildOfferText({bool isCompact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '20% off on your first order!',
          style: GoogleFonts.sora(
            color: const Color(0xFF9A5400),
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Apply the code at checkout for instant savings.',
          style: GoogleFonts.sora(
            color: const Color(0xFFB87820),
            fontSize: isCompact ? 10 : 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCode({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFFFB020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        'SUSHRUT20',
        style: GoogleFonts.sora(
          color: Colors.white,
          fontSize: isCompact ? 10 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
