import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../history/history_screen.dart';
import '../history/services/history_repository.dart';
import 'interaction_result.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    this.status = InteractionStatus.safe,
    this.result,
    this.savedToHistory = false,
  });

  final InteractionStatus status;
  final InteractionResultCopy? result;
  final bool savedToHistory;

  Future<void> _save(BuildContext context, InteractionResultCopy result) async {
    await const HistoryRepository().saveInteraction(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interaction saved to history.')),
    );
    context.pushScreen(const HistoryScreen());
  }

  @override
  Widget build(BuildContext context) {
    final result = this.result ?? InteractionResultCopy.fromStatus(status);

    final isHighRisk = result.risk == 'High-risk warning';

    return Scaffold(
      appBar: const MediverseAppBar(title: 'Safety Check Result'),
      body: ScreenPadding(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
              decoration: BoxDecoration(
                color: result.color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: result.color.withValues(alpha: .18)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: result.color.withValues(alpha: .16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(result.icon, color: result.color, size: 54),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    result.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: result.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.subtitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _ResultRow(
                    label: 'Safety finding',
                    value: result.risk,
                    color: result.color,
                  ),
                  _ResultRow(
                    label: 'Severity',
                    value: result.severity,
                    color: result.color,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.details,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  if (result.profileNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _GuidanceBlock(
                      title: 'Health profile notes',
                      body: result.profileNotes,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _GuidanceBlock(
                    title: 'Why it is risky',
                    body: result.whyRisky,
                  ),
                  _GuidanceBlock(
                    title: 'What you should do',
                    body: result.userAction,
                  ),
                  _GuidanceBlock(
                    title: 'Doctor/pharmacist advice',
                    body: result.professionalAdvice,
                  ),
                  const SizedBox(height: 18),
                  _NoticeBox(
                    icon: isHighRisk
                        ? Icons.emergency_outlined
                        : Icons.info_outline,
                    text: isHighRisk
                        ? 'Seek urgent medical help if you have difficulty breathing, swelling, fainting, severe bleeding, or another serious reaction.'
                        : 'This result is general information. Always follow advice from your doctor or pharmacist.',
                    color: result.color,
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: savedToHistory ? 'View History' : 'Save to History',
                    color: result.color,
                    onPressed: savedToHistory
                        ? () => context.pushScreen(const HistoryScreen())
                        : () => _save(context, result),
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

class _GuidanceBlock extends StatelessWidget {
  const _GuidanceBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
