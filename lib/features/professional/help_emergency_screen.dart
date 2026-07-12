import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';

class HelpEmergencyScreen extends StatelessWidget {
  const HelpEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MediverseAppBar(title: 'Help & Emergency'),
      body: ScreenPadding(
        child: Column(
          children: [
            _HelpBlock(
              icon: Icons.support_agent,
              title: 'Contact support',
              body:
                  'Send a message to Mediverse AI support for account, app, or safety guidance questions.',
            ),
            _HelpBlock(
              icon: Icons.question_answer_outlined,
              title: 'FAQ',
              body:
                  'Learn how interaction checks, scanner review, reminders, and offline saved content work.',
            ),
            _HelpBlock(
              icon: Icons.emergency_outlined,
              title: 'Emergency advice',
              body:
                  'For severe allergic reaction, trouble breathing, chest pain, heavy bleeding, overdose, or loss of consciousness, seek urgent medical care immediately.',
              urgent: true,
            ),
            _HelpBlock(
              icon: Icons.local_hospital_outlined,
              title: 'Nearby hospital/pharmacy later',
              body:
                  'Future backend versions can show nearby hospitals and pharmacies when location services are enabled.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpBlock extends StatelessWidget {
  const _HelpBlock({
    required this.icon,
    required this.title,
    required this.body,
    this.urgent = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final color = urgent ? AppColors.coral : AppColors.ocean;
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
