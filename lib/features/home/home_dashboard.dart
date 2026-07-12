import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';
import '../auth/services/auth_service.dart';
import '../chat/chat_screen.dart';
import '../drug_checker/drug_checker_screen.dart';
import '../history/history_screen.dart';
import '../professional/notifications_screen.dart';
import '../reminders/reminders_screen.dart';
import '../scanner/prescription_scanner_screen.dart';
import '../shared/interaction_list.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureItem(
        'Drug Checker',
        'Check safety',
        Icons.medication_liquid,
        AppColors.ocean,
        () => context.pushScreen(const DrugCheckerScreen()),
      ),
      _FeatureItem(
        'Prescription Scan',
        'Read medicine',
        Icons.document_scanner_outlined,
        AppColors.sky,
        () => context.pushScreen(const PrescriptionScannerScreen()),
      ),
      _FeatureItem(
        'AI Assistant',
        'Ask questions',
        Icons.support_agent,
        AppColors.violet,
        () => context.pushScreen(const ChatScreen()),
      ),
      _FeatureItem(
        'Reminders',
        'Track doses',
        Icons.alarm_on_outlined,
        AppColors.emerald,
        () => context.pushScreen(const RemindersScreen()),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              Future<void>.delayed(const Duration(milliseconds: 500)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${AuthService.currentUserName}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'What would you like to check today?',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () =>
                        context.pushScreen(const NotificationsScreen()),
                    icon: const Icon(Icons.notifications_none),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _SafetySummaryCard(),
              const SizedBox(height: 14),
              const _HealthTipCard(),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.18,
                ),
                itemBuilder: (_, index) => _FeatureTile(item: features[index]),
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Continue Learning',
                action: 'View all',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              const _LearningProgressCard(),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Recent Checks',
                action: 'History',
                onTap: () => context.pushScreen(const HistoryScreen()),
              ),
              const SizedBox(height: 12),
              const InteractionList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  const _HealthTipCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily health tip',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Take medicines with water unless your doctor or pharmacist gives different instructions.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetySummaryCard extends StatelessWidget {
  const _SafetySummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepTeal, AppColors.ocean],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_outlined, color: Colors.white, size: 40),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medication safety workspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Scan, compare, and save checks before adding ML-powered insights.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});

  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: item.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LearningProgressCard extends StatelessWidget {
  const _LearningProgressCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basics of Cardiology',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  '5 mins - Beginner',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: .30,
                  minHeight: 6,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Text('30%', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
