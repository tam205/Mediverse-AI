import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/state_views.dart';

class UiStatesScreen extends StatelessWidget {
  const UiStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MediverseAppBar(title: 'UI States'),
      body: ScreenPadding(
        child: Column(
          children: [
            _CheckingInteractionState(),
            SizedBox(height: 12),
            EmptyState(
              icon: Icons.wifi_off_outlined,
              title: 'No internet',
              message:
                  'Offline mode can still show saved medicines, reminders, and learning topics.',
            ),
            SizedBox(height: 12),
            EmptyState(
              icon: Icons.history_outlined,
              title: 'No history',
              message:
                  'Interaction checks, scans, and AI chats will appear here after the user saves them.',
            ),
            SizedBox(height: 12),
            EmptyState(
              icon: Icons.alarm_off_outlined,
              title: 'No reminders',
              message:
                  'Medication schedules will appear after the user adds morning, afternoon, evening, or night reminders.',
            ),
            SizedBox(height: 12),
            ErrorState(
              message:
                  'Scan failed. Please retake the photo in good light and make sure the prescription is inside the frame.',
            ),
            SizedBox(height: 12),
            _SuccessState(),
          ],
        ),
      ),
    );
  }
}

class _CheckingInteractionState extends StatelessWidget {
  const _CheckingInteractionState();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.ocean),
          SizedBox(height: 16),
          Text(
            'Checking interaction...',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'The future backend will compare medicines, health profile risks, and safety guidance here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.emerald),
          ),
          const SizedBox(height: 12),
          const Text(
            'Saved successfully',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'This success state can be reused after saving reminders, scans, or interaction results.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
