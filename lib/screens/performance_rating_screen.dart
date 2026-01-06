import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class PerformanceRatingScreen extends StatelessWidget {
  const PerformanceRatingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
        title: const Text('Performance Rating'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with overall rating
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '4.8',
                    style: AppTextStyles.headline(context).copyWith(
                      fontSize: 64,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < 4 ? Icons.star : Icons.star_half,
                        color: AppColors.gold,
                        size: 32,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Based on 127 reviews',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Rating breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating Breakdown',
                    style: AppTextStyles.title(context).copyWith(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRatingBar(context, 'Quality of Work', 4.9),
                  _buildRatingBar(context, 'Punctuality', 4.7),
                  _buildRatingBar(context, 'Professionalism', 4.8),
                  _buildRatingBar(context, 'Customer Service', 4.6),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Recent feedback
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Feedback',
                    style: AppTextStyles.title(context).copyWith(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeedbackCard(
                    context,
                    'Great service! Very professional.',
                    5,
                    '2 days ago',
                  ),
                  _buildFeedbackCard(
                    context,
                    'Car looks amazing. Will definitely book again.',
                    5,
                    '5 days ago',
                  ),
                  _buildFeedbackCard(
                    context,
                    'Good work, arrived on time.',
                    4,
                    '1 week ago',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context, String label, double rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.darkNavy,
                ),
              ),
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rating / 5,
              backgroundColor: AppColors.veryLightGray,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(
    BuildContext context,
    String feedback,
    int rating,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.veryLightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: AppColors.gold,
                  size: 16,
                );
              }),
              const Spacer(),
              Text(
                time,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.lightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}
