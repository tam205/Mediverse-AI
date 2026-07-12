import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 110),
          children: const [
            Text(
              'Medical Learning',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
            ),
            SizedBox(height: 6),
            Text(
              'Short lessons for safer health decisions.',
              style: TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: 20),
            _CategoryScroller(),
            SizedBox(height: 18),
            _CourseCard(
              title: 'Basics of Cardiology',
              progress: .30,
              icon: Icons.monitor_heart_outlined,
              color: AppColors.amber,
            ),
            _CourseCard(
              title: 'Understanding Antibiotics',
              progress: .62,
              icon: Icons.science_outlined,
              color: AppColors.ocean,
            ),
            _CourseCard(
              title: 'Medication Safety',
              progress: .45,
              icon: Icons.verified_user_outlined,
              color: AppColors.sky,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.title,
    required this.progress,
    required this.icon,
    required this.color,
  });

  final String title;
  final double progress;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    color: color,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                IconButton(
                  tooltip: 'Bookmark',
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller();

  @override
  Widget build(BuildContext context) {
    final categories = [
      (Icons.medication_outlined, 'Medication'),
      (Icons.monitor_heart_outlined, 'Cardiology'),
      (Icons.science_outlined, 'Antibiotics'),
      (Icons.health_and_safety_outlined, 'Safety'),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = categories[index];
          return Container(
            width: 112,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$1, color: AppColors.ocean),
                const Spacer(),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
