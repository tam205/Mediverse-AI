import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MediverseAppBar(title: 'Privacy & Security'),
      body: ScreenPadding(
        child: Column(
          children: [
            _PrivacyAction(
              icon: Icons.lock_outline,
              title: 'Data protection',
              body:
                  'Health profile, reminders, history, and scans should be protected with secure storage and clear consent when backend is added.',
            ),
            _PrivacyAction(
              icon: Icons.download_outlined,
              title: 'Export data',
              body:
                  'Future backend users should be able to export their health profile, reminders, scans, and interaction history.',
            ),
            _PrivacyAction(
              icon: Icons.delete_outline,
              title: 'Delete account',
              body:
                  'Future backend users should be able to permanently delete their account and personal health data.',
              danger: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyAction extends StatelessWidget {
  const _PrivacyAction({
    required this.icon,
    required this.title,
    required this.body,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.coral : AppColors.ocean;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
