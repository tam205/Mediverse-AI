import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/state_views.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MediverseAppBar(title: 'Notifications'),
      body: ScreenPadding(
        child: Column(
          children: [
            _NotificationTile(
              icon: Icons.alarm_on_outlined,
              title: 'Dose reminder',
              message: 'Ibuprofen 400mg is due at 01:00 PM.',
              color: AppColors.amber,
            ),
            _NotificationTile(
              icon: Icons.verified_user_outlined,
              title: 'Saved interaction',
              message: 'Paracetamol + Ibuprofen was saved to history.',
              color: AppColors.emerald,
            ),
            SizedBox(height: 12),
            EmptyState(
              icon: Icons.notifications_none,
              title: 'You are all caught up',
              message:
                  'New reminders, scan results, and safety updates will appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
