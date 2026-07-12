import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import 'help_emergency_screen.dart';
import 'info_screen.dart';
import 'offline_support_screen.dart';
import 'privacy_security_screen.dart';
import 'ui_states_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool reminders = true;
  String language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MediverseAppBar(title: 'Settings'),
      body: ScreenPadding(
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Frontend preview toggle',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    value: darkMode,
                    onChanged: (value) => setState(() => darkMode = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Reminder alerts',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    value: reminders,
                    onChanged: (value) => setState(() => reminders = value),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language, color: AppColors.ocean),
                    title: const Text(
                      'Language',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(language),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushScreen(const LanguageScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  _SettingsLink(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy & Security',
                    onTap: () =>
                        context.pushScreen(const PrivacySecurityScreen()),
                  ),
                  _SettingsLink(
                    icon: Icons.offline_pin_outlined,
                    label: 'Offline Support',
                    onTap: () =>
                        context.pushScreen(const OfflineSupportScreen()),
                  ),
                  _SettingsLink(
                    icon: Icons.emergency_outlined,
                    label: 'Help & Emergency',
                    onTap: () =>
                        context.pushScreen(const HelpEmergencyScreen()),
                  ),
                  _SettingsLink(
                    icon: Icons.description_outlined,
                    label: 'Terms of Use',
                    onTap: () => context.pushScreen(ProfessionalPages.terms()),
                  ),
                  _SettingsLink(
                    icon: Icons.medical_information_outlined,
                    label: 'Medical Disclaimer',
                    onTap: () =>
                        context.pushScreen(ProfessionalPages.disclaimer()),
                  ),
                  _SettingsLink(
                    icon: Icons.dashboard_customize_outlined,
                    label: 'UI States',
                    onTap: () => context.pushScreen(const UiStatesScreen()),
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

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MediverseAppBar(title: 'Language'),
      body: ScreenPadding(
        child: AppCard(
          child: Column(
            children: [
              _LanguageTile(label: 'English', selected: true),
              _LanguageTile(label: 'French'),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.ocean : AppColors.muted,
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.ocean)
          : null,
      onTap: () {},
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.ocean),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class ProfessionalPages {
  const ProfessionalPages._();

  static InfoScreen about() => const InfoScreen(
    title: 'About Mediverse AI',
    icon: Icons.info_outline,
    sections: [
      InfoSection(
        'Mission',
        'Mediverse AI is an educational medication-support platform for safer, more informed health decisions.',
      ),
      InfoSection(
        'MVP focus',
        'This frontend prepares drug checks, reminders, scanning, learning, and history for future backend integration.',
      ),
    ],
  );

  static InfoScreen help() => const InfoScreen(
    title: 'Help Center',
    icon: Icons.help_outline,
    sections: [
      InfoSection(
        'Drug checks',
        'Search medicines, review interaction severity, and save important results to your history.',
      ),
      InfoSection(
        'Scanning',
        'Use prescription scanning to review detected medicine names before checking interactions.',
      ),
    ],
  );

  static InfoScreen privacy() => const InfoScreen(
    title: 'Privacy Policy',
    icon: Icons.privacy_tip_outlined,
    sections: [
      InfoSection(
        'Privacy first',
        'The MVP is frontend-only. Future versions should store personal health data securely with clear consent.',
      ),
      InfoSection(
        'Data control',
        'Users should be able to review, export, and delete their health data when backend storage is added.',
      ),
    ],
  );

  static InfoScreen terms() => const InfoScreen(
    title: 'Terms of Use',
    icon: Icons.description_outlined,
    sections: [
      InfoSection(
        'Educational use',
        'Mediverse AI provides educational support and should not be used as a substitute for professional care.',
      ),
      InfoSection(
        'User responsibility',
        'Users should verify medicine guidance with qualified healthcare professionals.',
      ),
    ],
  );

  static InfoScreen disclaimer() => const InfoScreen(
    title: 'Medical Disclaimer',
    icon: Icons.medical_information_outlined,
    sections: [
      InfoSection(
        'Safety first',
        'This app helps you learn and check medicine safety, but it does not replace doctors.',
      ),
      InfoSection(
        'Professional care',
        'Always ask a doctor or pharmacist before changing medicines, especially during pregnancy, breastfeeding, chronic disease, or severe symptoms.',
      ),
    ],
  );
}
