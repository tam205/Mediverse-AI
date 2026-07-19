import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum AuthLanguage { english, french }

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AuthLanguage value;
  final ValueChanged<AuthLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AuthLanguage>(
      initialValue: value,
      tooltip: value == AuthLanguage.english
          ? 'Change language'
          : 'Changer la langue',
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: AuthLanguage.english, child: Text('English')),
        PopupMenuItem(value: AuthLanguage.french, child: Text('Français')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 18,
              color: AppColors.ocean,
            ),
            const SizedBox(width: 7),
            Text(
              value == AuthLanguage.english ? 'English' : 'Français',
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
