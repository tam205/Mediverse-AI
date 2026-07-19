import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/utils/firebase_error_messages.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../auth/login_screen.dart';
import '../auth/services/auth_service.dart';
import '../professional/help_emergency_screen.dart';
import '../professional/privacy_security_screen.dart';
import '../professional/settings_screen.dart';
import 'allergies_screen.dart';
import 'current_medicines_screen.dart';
import 'edit_health_profile_screen.dart';
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
  bool _savingRole = false;

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

  Future<void> _selectRole(HealthProfile profile) async {
    final selectedRole = await showModalBottomSheet<UserRole>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _RoleSelectionSheet(selectedRole: profile.primaryRole),
    );
    if (selectedRole == null || selectedRole == profile.primaryRole) return;

    setState(() => _savingRole = true);
    try {
      await _repository.saveProfile(
        profile.copyWith(
          primaryRole: selectedRole,
          lastUpdated: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Use type updated.')));
    } catch (error, stackTrace) {
      debugPrint('Role update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not update your use type. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingRole = false);
    }
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
                  savingRole: _savingRole,
                  onComplete: () => _editProfile(profile),
                  onChangeRole: () => _selectRole(profile),
                ),
                const SizedBox(height: 14),
                _CompletionCard(profile: profile),
                const SizedBox(height: 20),
                _ProfileSectionGroup(
                  title: 'Account information',
                  children: [
                    _ProfileMenuTile(
                      icon: Icons.person_outline,
                      title: 'Personal details',
                      subtitle: _personalDetailsSummary(profile),
                      onTap: () => context.pushScreen(
                        ProfileDetailScreen(
                          title: 'Personal details',
                          icon: Icons.person_outline,
                          items: [
                            ('Full name', _valueOrNotAdded(profile.name)),
                            ('Email', _valueOrNotAdded(profile.email)),
                            (
                              'Age',
                              profile.age > 0
                                  ? '${profile.age}'
                                  : 'Not added yet',
                            ),
                            ('Country', _valueOrNotAdded(profile.country)),
                            (
                              'Blood group',
                              _valueOrNotAdded(profile.bloodGroup),
                            ),
                            ('Language', _valueOrNotAdded(profile.language)),
                          ],
                        ),
                      ),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.badge_outlined,
                      title: 'Use type',
                      subtitle:
                          '${_roleLabel(profile.primaryRole)}. You can change this later.',
                      trailingText: _savingRole ? 'Saving...' : null,
                      onTap: _savingRole ? null : () => _selectRole(profile),
                    ),
                  ],
                ),
                _RoleInformationGroup(
                  profile: profile,
                  onEditHealthProfile: () => _editProfile(profile),
                ),
                _ProfileSectionGroup(
                  title: 'Health and medicine',
                  children: [
                    _ProfileMenuTile(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Allergies',
                      subtitle: _allergiesOverviewSummary(profile),
                      onTap: () => context.pushScreen(const AllergiesScreen()),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.medication_outlined,
                      title: 'Current medicines',
                      subtitle: _currentMedicinesOverviewSummary(profile),
                      onTap: () =>
                          context.pushScreen(const CurrentMedicinesScreen()),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.favorite_border,
                      title: 'Health conditions',
                      subtitle: _conditionsSummary(profile),
                      onTap: () =>
                          context.pushScreen(const HealthProfileScreen()),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.contact_emergency_outlined,
                      title: 'Emergency information',
                      subtitle: profile.hasEmergencyContact
                          ? '${profile.emergencyRelationship}: ${profile.emergencyName}'
                          : 'Optional. Not added yet',
                      onTap: () => context.pushScreen(
                        ProfileDetailScreen(
                          title: 'Emergency information',
                          icon: Icons.contact_emergency_outlined,
                          items: [
                            (
                              'Emergency contact',
                              _valueOrNotAdded(profile.emergencyName),
                            ),
                            (
                              'Relationship',
                              _valueOrNotAdded(profile.emergencyRelationship),
                            ),
                            (
                              'Phone number',
                              profile.hasEmergencyContact
                                  ? '${profile.emergencyCountryCode} ${profile.emergencyPhone}'
                                  : 'Not added yet',
                            ),
                            ('Last updated', profile.lastUpdatedLabel),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                _ProfileSectionGroup(
                  title: 'Preferences',
                  children: [
                    _ProfileMenuTile(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: _valueOrNotAdded(profile.language),
                      onTap: () => context.pushScreen(const LanguageScreen()),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Medicine reminders enabled',
                      onTap: () => context.pushScreen(const SettingsScreen()),
                    ),
                  ],
                ),
                _ProfileSectionGroup(
                  title: 'Account',
                  children: [
                    _ProfileMenuTile(
                      icon: Icons.lock_outline,
                      title: 'Account and security',
                      subtitle: 'Password, email, and sign out',
                      onTap: () =>
                          context.pushScreen(const PrivacySecurityScreen()),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy and consent',
                      subtitle: profile.dataConsent
                          ? 'Health-data consent saved'
                          : 'Review health-data consent',
                      statusColor: profile.dataConsent
                          ? AppColors.emerald
                          : AppColors.amber,
                      onTap: () =>
                          context.pushScreen(const PrivacySecurityScreen()),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.help_outline,
                      title: 'Help and emergency',
                      subtitle: 'Support and urgent-care guidance',
                      onTap: () =>
                          context.pushScreen(const HelpEmergencyScreen()),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.logout,
                      title: 'Sign out',
                      subtitle: 'Leave this device safely',
                      showChevron: false,
                      onTap: () async {
                        await AuthService.signOut();
                        if (context.mounted) {
                          context.replaceWith(const LoginScreen());
                        }
                      },
                    ),
                  ],
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
      appBar: const MediverseAppBar(title: 'Profile'),
      body: body,
    );
  }

  static String _personalDetailsSummary(HealthProfile profile) {
    final details = <String>[];
    if (profile.age > 0) details.add('Age ${profile.age}');
    if (profile.country.trim().isNotEmpty) details.add(profile.country);
    if (profile.bloodGroup.trim().isNotEmpty) details.add(profile.bloodGroup);
    return details.isEmpty ? 'Name, country, blood group' : details.join(', ');
  }

  static String _conditionsSummary(HealthProfile profile) {
    final conditions = profile.chronicDiseases;
    if (conditions.isEmpty) return 'Not added yet';
    if (conditions.length == 1) return conditions.first;
    return '${conditions.length} conditions recorded';
  }

  static String _allergiesOverviewSummary(HealthProfile profile) {
    if (!profile.allergiesReviewed) return 'Review allergies';
    if (profile.allergies.isEmpty) return 'No known allergies';
    return _countSummary(
      profile.allergies.length,
      singular: 'allergy recorded',
      plural: 'allergies recorded',
    );
  }

  static String _currentMedicinesOverviewSummary(HealthProfile profile) {
    if (!profile.medicinesReviewed) return 'Review medicines';
    if (profile.currentMedicines.isEmpty) return 'No current medicines';
    return _countSummary(
      profile.currentMedicines.length,
      singular: 'medicine recorded',
      plural: 'medicines recorded',
    );
  }

  static String _countSummary(
    int count, {
    required String singular,
    required String plural,
  }) {
    if (count == 0) return 'Not added yet';
    return '$count ${count == 1 ? singular : plural}';
  }

  static String _valueOrNotAdded(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Not added yet' : trimmed;
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
  const _ProfileHeader({
    required this.profile,
    required this.savingRole,
    required this.onComplete,
    required this.onChangeRole,
  });

  final HealthProfile profile;
  final bool savingRole;
  final VoidCallback onComplete;
  final VoidCallback onChangeRole;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.name.trim().isEmpty
        ? AuthService.currentUserName
        : profile.name.trim();
    final firstName = displayName.trim().split(RegExp(r'\s+')).first;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Hello, $firstName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusBadge(label: _roleLabel(profile.primaryRole)),
                        if (_isProfessional(profile.primaryRole))
                          const _StatusBadge(
                            label: 'Verification not submitted',
                            color: AppColors.amber,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your profile is ${profile.completionPercent}% complete.',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            '${profile.missingGuidance} You can complete this later.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Complete profile'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Change use type',
                onPressed: savingRole ? null : onChangeRole,
                icon: const Icon(Icons.swap_horiz),
              ),
            ],
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
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppColors.ocean),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profile ${profile.completionPercent}% complete',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.missingGuidance,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
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

class _RoleInformationGroup extends StatelessWidget {
  const _RoleInformationGroup({
    required this.profile,
    required this.onEditHealthProfile,
  });

  final HealthProfile profile;
  final VoidCallback onEditHealthProfile;

  @override
  Widget build(BuildContext context) {
    switch (profile.primaryRole) {
      case UserRole.student:
        return _ProfileSectionGroup(
          title: 'Role information',
          children: [
            _ProfileMenuTile(
              icon: Icons.school_outlined,
              title: 'Learning profile',
              subtitle: 'Study level, difficulty, and learning goals',
              onTap: () => context.pushScreen(
                const ProfileDetailScreen(
                  title: 'Learning profile',
                  icon: Icons.school_outlined,
                  items: [
                    ('Study level', 'Not added yet'),
                    ('Area of study', 'Not added yet'),
                    ('Learning goals', 'Not added yet'),
                  ],
                ),
              ),
            ),
            _ProfileMenuTile(
              icon: Icons.bookmark_border,
              title: 'Learning interests',
              subtitle: 'Pharmacology, interactions, cases, and calculations',
              onTap: () => context.pushScreen(
                const ProfileDetailScreen(
                  title: 'Learning interests',
                  icon: Icons.bookmark_border,
                  items: [
                    ('Saved interests', 'Not added yet'),
                    ('Quiz progress', 'Not added yet'),
                    ('Recent learning activity', 'Not added yet'),
                  ],
                ),
              ),
            ),
          ],
        );
      case UserRole.healthcareProfessional:
        return _ProfileSectionGroup(
          title: 'Role information',
          children: [
            _ProfileMenuTile(
              icon: Icons.medical_services_outlined,
              title: 'Professional profile',
              subtitle: 'Profession, specialty, licence, and institution',
              onTap: () => context.pushScreen(
                const ProfileDetailScreen(
                  title: 'Professional profile',
                  icon: Icons.medical_services_outlined,
                  items: [
                    ('Professional name', 'Not added yet'),
                    ('Profession', 'Not added yet'),
                    ('Specialty', 'Not added yet'),
                    ('Country of practice', 'Not added yet'),
                    ('Registration or licence number', 'Not added yet'),
                  ],
                ),
              ),
            ),
            _ProfileMenuTile(
              icon: Icons.verified_user_outlined,
              title: 'Verification status',
              subtitle: 'Not submitted. Verification is reviewed separately.',
              statusColor: AppColors.amber,
              onTap: () => context.pushScreen(
                const ProfileDetailScreen(
                  title: 'Verification status',
                  icon: Icons.verified_user_outlined,
                  items: [
                    ('Status', 'Not submitted'),
                    ('Verified badge', 'Not shown'),
                    (
                      'Important',
                      'Selecting healthcare professional does not verify this account.',
                    ),
                  ],
                ),
              ),
            ),
            _ProfileMenuTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Personal health profile',
              subtitle: 'Optional health details for your own medicine checks',
              onTap: onEditHealthProfile,
            ),
          ],
        );
      case UserRole.patient:
        return _ProfileSectionGroup(
          title: 'Role information',
          children: [
            _ProfileMenuTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Personal health profile',
              subtitle: 'Health details used for medicine safety checks',
              onTap: onEditHealthProfile,
            ),
          ],
        );
    }
  }
}

class _ProfileSectionGroup extends StatelessWidget {
  const _ProfileSectionGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 9),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: _withDividers(children)),
          ),
        ],
      ),
    );
  }

  static List<Widget> _withDividers(List<Widget> children) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i += 1) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(const Divider(height: 1, indent: 58));
      }
    }
    return result;
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
    this.statusColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? trailingText;
  final Color? statusColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: AppColors.ocean),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: statusColor ?? AppColors.muted,
          height: 1.35,
          fontWeight: statusColor == null ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      trailing: trailingText != null
          ? Text(
              trailingText!,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            )
          : showChevron
          ? const Icon(Icons.chevron_right, color: AppColors.muted)
          : null,
      onTap: onTap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, this.color = AppColors.ocean});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RoleSelectionSheet extends StatelessWidget {
  const _RoleSelectionSheet({required this.selectedRole});

  final UserRole selectedRole;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How will you mainly use Mediverse AI?',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can change this later. Professional verification is reviewed separately.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            _RoleOption(
              value: UserRole.patient,
              selectedRole: selectedRole,
              title: 'Patient or caregiver',
              description:
                  'Check medicine information, manage health details, and keep track of medicines.',
            ),
            _RoleOption(
              value: UserRole.student,
              selectedRole: selectedRole,
              title: 'Medical or pharmacy student',
              description:
                  'Study medicines, interactions, precautions, and clinical concepts.',
            ),
            _RoleOption(
              value: UserRole.healthcareProfessional,
              selectedRole: selectedRole,
              title: 'Healthcare professional',
              description:
                  'Access clinical reference tools and manage professional information.',
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.value,
    required this.selectedRole,
    required this.title,
    required this.description,
  });

  final UserRole value;
  final UserRole selectedRole;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedRole;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.ocean : AppColors.muted,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(
        description,
        style: const TextStyle(color: AppColors.muted, height: 1.35),
      ),
      onTap: () => Navigator.pop(context, value),
    );
  }
}

String _roleLabel(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Student';
    case UserRole.healthcareProfessional:
      return 'Healthcare professional';
    case UserRole.patient:
      return 'Patient';
  }
}

bool _isProfessional(UserRole role) => role == UserRole.healthcareProfessional;
