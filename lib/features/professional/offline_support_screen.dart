import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';

class OfflineSupportScreen extends StatelessWidget {
  const OfflineSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MediverseAppBar(title: 'Offline Support'),
      body: ScreenPadding(
        child: Column(
          children: [
            _OfflineTile(
              icon: Icons.medication_outlined,
              title: 'Saved medicines',
              subtitle: 'Paracetamol, Ibuprofen, Amoxicillin',
            ),
            _OfflineTile(
              icon: Icons.alarm_on_outlined,
              title: 'Saved reminders',
              subtitle: 'Morning, afternoon, evening, and night schedules',
            ),
            _OfflineTile(
              icon: Icons.school_outlined,
              title: 'Saved learning topics',
              subtitle: 'Medication safety and antibiotic basics',
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineTile extends StatelessWidget {
  const _OfflineTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, color: AppColors.ocean, size: 30),
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
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.offline_pin_outlined, color: AppColors.emerald),
          ],
        ),
      ),
    );
  }
}
