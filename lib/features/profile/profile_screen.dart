import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/utils/firebase_error_messages.dart';
import '../auth/login_screen.dart';
import '../auth/services/auth_service.dart';
import 'edit_health_profile_screen.dart';
import '../professional/help_emergency_screen.dart';
import '../professional/privacy_security_screen.dart';
import '../professional/settings_screen.dart';
import 'health_profile_screen.dart';
import 'models/health_profile.dart';
import 'profile_detail_screen.dart';
import 'services/health_profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.inShell = false});

  final bool inShell;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repository = const HealthProfileRepository();
  late Stream<HealthProfile> _profileStream;

  @override
  void initState() {
    super.initState();
    _profileStream = _repository.watchProfile();
  }

  void _reloadProfile() {
    setState(() => _profileStream = _repository.watchProfile());
  }

  Future<void> _editProfile(HealthProfile profile) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditHealthProfileScreen(initialProfile: profile),
      ),
    );
    if (updated == true) _reloadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: StreamBuilder<HealthProfile>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ProfileErrorState(
              title: 'Could not load your profile',
              message: friendlyDatabaseMessage(snapshot.error!),
              onRetry: _reloadProfile,
            );
          }

          final profile = snapshot.data ?? HealthProfile.empty;
          return RefreshIndicator(
            onRefresh: () async {
              _reloadProfile();
              await _profileStream.first;
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                widget.inShell ? 110 : 28,
              ),
              children: [
                _ProfileHeader(
                  profile: profile,
                  onEdit: () => _editProfile(profile),
                ),
                const SizedBox(height: 12),
                _CompletionCard(profile: profile),
                const SizedBox(height: 12),
                _SafetySummaryCard(profile: profile),
                const SizedBox(height: 18),
                _ProfileTile(
                  icon: Icons.person_outline,
                  label: 'Personal Information',
                  status: _status(profile.phone.isNotEmpty),
                  onTap: () => context.pushScreen(
                    ProfileDetailScreen(
                      title: 'Personal Information',
                      icon: Icons.person_outline,
                      items: [
                        ('Name', profile.name),
                        ('Email', profile.email),
                        ('Phone', profile.phone),
                        ('Date of birth', profile.dateOfBirth),
                        ('Gender', profile.gender),
                        ('Country', profile.country),
                        ('Language', profile.language),
                        ('Last updated', profile.lastUpdatedLabel),
                      ],
                    ),
                  ),
                ),
                _ProfileTile(
                  icon: Icons.medical_information_outlined,
                  label: 'Medical Profile',
                  status: profile.currentMedicines.isEmpty
                      ? 'Incomplete'
                      : 'Added',
                  onTap: () => context.pushScreen(const HealthProfileScreen()),
                ),
                _ProfileTile(
                  icon: Icons.warning_amber_outlined,
                  label: 'Allergies',
                  status: profile.allergies.isEmpty ? 'Not added' : 'Added',
                  onTap: () => context.pushScreen(
                    ProfileDetailScreen(
                      title: 'Allergies',
                      icon: Icons.warning_amber_outlined,
                      items: [
                        ('Recorded allergies', _allergySummary(profile)),
                        ('Last updated', profile.lastUpdatedLabel),
                      ],
                    ),
                  ),
                ),
                _ProfileTile(
                  icon: Icons.medication_outlined,
                  label: 'Current Medicines',
                  status: profile.currentMedicines.isEmpty
                      ? 'Not added'
                      : 'Added',
                  onTap: () => context.pushScreen(
                    ProfileDetailScreen(
                      title: 'Current Medicines',
                      icon: Icons.medication_outlined,
                      items: [
                        ('Medicines', _listOrNone(profile.currentMedicines)),
                        ('Used for', 'Future interaction and safety checks'),
                        ('Last updated', profile.lastUpdatedLabel),
                      ],
                    ),
                  ),
                ),
                _ProfileTile(
                  icon: Icons.contact_emergency_outlined,
                  label: 'Emergency Contact',
                  status: profile.hasEmergencyContact ? 'Added' : 'Not added',
                  onTap: () => context.pushScreen(
                    ProfileDetailScreen(
                      title: 'Emergency Contact',
                      icon: Icons.contact_emergency_outlined,
                      items: [
                        ('Name', profile.emergencyName),
                        ('Relationship', profile.emergencyRelationship),
                        ('Country code', profile.emergencyCountryCode),
                        ('Phone', profile.emergencyPhone),
                        ('Last updated', profile.lastUpdatedLabel),
                      ],
                    ),
                  ),
                ),
                _ProfileTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy & Security',
                  status: profile.dataConsent ? 'Consent saved' : 'Review',
                  onTap: () =>
                      context.pushScreen(const PrivacySecurityScreen()),
                ),
                _ProfileTile(
                  icon: Icons.medical_information_outlined,
                  label: 'Medical Disclaimer',
                  status: 'Visible',
                  onTap: () =>
                      context.pushScreen(ProfessionalPages.disclaimer()),
                ),
                _ProfileTile(
                  icon: Icons.help_outline,
                  label: 'Help & Emergency',
                  status: 'Support',
                  onTap: () => context.pushScreen(const HelpEmergencyScreen()),
                ),
                _ProfileTile(
                  icon: Icons.info_outline,
                  label: 'About Mediverse AI',
                  status: 'App info',
                  onTap: () => context.pushScreen(ProfessionalPages.about()),
                ),
                _ProfileTile(
                  icon: Icons.logout,
                  label: 'Log Out',
                  status: '',
                  onTap: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      context.replaceWith(const LoginScreen());
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );

    if (widget.inShell) {
      return Scaffold(backgroundColor: AppColors.canvas, body: body);
    }
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MediverseAppBar(
        title: 'Profile',
        actions: [
          StreamBuilder<HealthProfile>(
            stream: _profileStream,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              return IconButton(
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined),
                onPressed: profile == null ? null : () => _editProfile(profile),
              );
            },
          ),
        ],
      ),
      body: body,
    );
  }

  static String _status(bool complete) => complete ? 'Added' : 'Incomplete';

  static String _listOrNone(List<String> values) {
    if (values.isEmpty) return 'Not added';
    return values.join(', ');
  }

  static String _allergySummary(HealthProfile profile) {
    if (profile.allergyEntries.isNotEmpty) {
      return profile.allergyEntries
          .map(
            (allergy) =>
                '${allergy.substance}: ${allergy.reaction} (${allergy.severity})',
          )
          .join('\n');
    }
    return _listOrNone(profile.allergies);
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 140),
      children: [
        Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: AppColors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final HealthProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: AppColors.ocean.withValues(alpha: .14),
            child: Text(
              AuthService.currentUserInitials,
              style: const TextStyle(
                color: AppColors.ocean,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.email,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${profile.lastUpdatedLabel}',
                  style: const TextStyle(
                    color: AppColors.softMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.profile});

  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile ${profile.completionPercent}% complete',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            profile.missingGuidance,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: profile.completionPercent / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }
}

class _SafetySummaryCard extends StatelessWidget {
  const _SafetySummaryCard({required this.profile});

  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health safety summary',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Allergies',
                  value: '${profile.allergies.length}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Medicines',
                  value: '${profile.currentMedicines.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Conditions',
                  value: '${profile.chronicDiseases.length}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Emergency',
                  value: profile.hasEmergencyContact ? 'Added' : 'Missing',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.status,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mutedStatus = status.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (!mutedStatus) ...[
              Text(
                status,
                style: TextStyle(
                  color: status == 'Added' || status == 'Consent saved'
                      ? AppColors.emerald
                      : AppColors.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
