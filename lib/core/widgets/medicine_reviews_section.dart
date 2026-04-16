import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reviews_provider.dart';
import 'write_review_sheet.dart';

class MedicineReviewsSection extends ConsumerStatefulWidget {
  final String medicineId;
  final String? orderId;

  const MedicineReviewsSection({
    super.key,
    required this.medicineId,
    required this.orderId,
  });

  @override
  ConsumerState<MedicineReviewsSection> createState() => _MedicineReviewsSectionState();
}

class _MedicineReviewsSectionState extends ConsumerState<MedicineReviewsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.medicineId.isEmpty) return const SizedBox.shrink();

    final reviewsAsync = ref.watch(medicineReviewsProvider(widget.medicineId));
    final avgRating = ref.watch(averageRatingProvider(widget.medicineId));

    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reviews) {
        final displayed = _expanded ? reviews : reviews.take(3).toList();
        final user = ref.watch(currentUserProvider).valueOrNull;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB300)),
                    const SizedBox(width: 8),
                    Text(
                      'Reviews & Ratings',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (reviews.isNotEmpty)
                      _StarDisplay(rating: avgRating, count: reviews.length),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Column(
                  children: displayed
                      .map((r) => _ReviewTile(review: r))
                      .toList(),
                ),
              if (reviews.length > 3)
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show less' : 'See all ${reviews.length} reviews',
                    style: GoogleFonts.sora(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (user != null && widget.orderId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _openWriteReview(context, user.uid, user.name),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Write a Review',
                        style: GoogleFonts.sora(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openWriteReview(BuildContext context, String userId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WriteReviewSheet(
        medicineId: widget.medicineId,
        orderId: widget.orderId!,
        userId: userId,
        userName: userName,
      ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  final double rating;
  final int count;

  const _StarDisplay({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
        const SizedBox(width: 3),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStars(review.rating),
              const Spacer(),
              if (review.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Verified Purchase',
                    style: GoogleFonts.sora(
                      fontSize: 9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment,
              style: GoogleFonts.sora(fontSize: 12, color: AppColors.textPrimary),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                review.userName,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${DateFormat('d MMM yyyy').format(review.createdAt)}',
                style: GoogleFonts.sora(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: const Color(0xFFFFB300),
        );
      }),
    );
  }
}
