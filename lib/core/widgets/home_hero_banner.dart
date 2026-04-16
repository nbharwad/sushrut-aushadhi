import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

class HomeHeroBanner extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final PageController pageController;
  final int currentBanner;
  final ValueChanged<int> onPageChanged;

  const HomeHeroBanner({
    super.key,
    required this.banners,
    required this.pageController,
    required this.currentBanner,
    required this.onPageChanged,
  });

  @override
  State<HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<HomeHeroBanner> {
  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bannerAspectRatio = constraints.maxWidth < 380
                    ? 1.08
                    : constraints.maxWidth < 600
                        ? 1.6
                        : 2.25;
                return AspectRatio(
                  aspectRatio: bannerAspectRatio,
                  child: PageView.builder(
                    controller: widget.pageController,
                    itemCount: widget.banners.length,
                    onPageChanged: widget.onPageChanged,
                    itemBuilder: (context, index) {
                      final banner = widget.banners[index] as Map<String, dynamic>;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == widget.banners.length - 1 ? 0 : 14,
                        ),
                        child: _BannerCard(
                          banner: banner,
                          isEven: index.isEven,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _buildPageIndicators(),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.banners.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: widget.currentBanner == i ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.currentBanner == i
                ? AppColors.primary
                : AppColors.divider,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final bool isEven;

  const _BannerCard({
    required this.banner,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = banner['imageUrl']?.toString() ?? '';
    final title = banner['title']?.toString() ?? '';
    final subtitle = banner['subtitle']?.toString() ?? '';
    final buttonText = banner['buttonText']?.toString() ?? 'Shop Now';

    final gradientColors = isEven
        ? [const Color(0xFF0A5C45), const Color(0xFF1AAE7A)]
        : [const Color(0xFF0760A8), const Color(0xFF0B9FE0)];

    final buttonColor = isEven ? AppColors.primary : AppColors.labPrimary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background shapes
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 100,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (title.isNotEmpty) ...[
                        Text(
                          title,
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (subtitle.isNotEmpty) ...[
                        Text(
                          subtitle,
                          style: GoogleFonts.sora(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.sora(
                            color: buttonColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (imageUrl.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 82,
                          height: 82,
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.image, color: Colors.white, size: 32),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 82,
                          height: 82,
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.medication_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Icon(Icons.medication_rounded, color: Colors.white, size: 36),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
