import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/utils/firebase_error_messages.dart';
import 'models/health_profile.dart';
import 'services/health_profile_repository.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final _repository = const HealthProfileRepository();
  late Future<HealthProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repository.getProfile();
  }

  Future<void> _save(HealthProfile profile) async {
    await _repository.saveProfile(profile);
    if (!mounted) return;
    setState(() => _profileFuture = _repository.getProfile());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health profile saved securely.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MediverseAppBar(title: 'Health Profile'),
      body: ScreenPadding(
        child: FutureBuilder<HealthProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _HealthProfileErrorState(
                message: friendlyDatabaseMessage(snapshot.error!),
                onRetry: () {
                  setState(() => _profileFuture = _repository.getProfile());
                },
              );
            }

            final profile = snapshot.data ?? HealthProfile.empty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompletionHeader(profile: profile),
                const SizedBox(height: 12),
                _SafetySummary(profile: profile),
                const SizedBox(height: 12),
                _SectionStatusCard(profile: profile),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  status: _status(
                    profile.phone.isNotEmpty && profile.country.isNotEmpty,
                  ),
                  lastUpdated: profile.lastUpdatedLabel,
                  rows: [
                    ('Name', profile.name),
                    ('Email', profile.email),
                    ('Phone', profile.phone),
                    ('Date of birth', profile.dateOfBirth),
                    ('Gender', profile.gender),
                    ('Country', profile.country),
                    ('Language', profile.language),
                  ],
                ),
                _ProfileSection(
                  title: 'Medical Profile',
                  icon: Icons.medical_information_outlined,
                  status: _status(
                    profile.age > 0 && profile.currentMedicines.isNotEmpty,
                  ),
                  lastUpdated: profile.lastUpdatedLabel,
                  rows: [
                    ('Age', '${profile.age}'),
                    ('Weight', '${profile.weightKg.toStringAsFixed(0)} kg'),
                    ('Height', '${profile.heightCm.toStringAsFixed(0)} cm'),
                    ('Blood group', profile.bloodGroup),
                    ('Chronic diseases', _listOrNone(profile.chronicDiseases)),
                    ('Pregnancy/breastfeeding', profile.pregnancyBreastfeeding),
                  ],
                ),
                _ProfileSection(
                  title: 'Allergies',
                  icon: Icons.warning_amber_outlined,
                  status: profile.allergies.isEmpty ? 'Not added' : 'Added',
                  lastUpdated: profile.lastUpdatedLabel,
                  rows: [
                    (
                      'Medicine allergies',
                      _listOrNone(profile.medicineAllergies),
                    ),
                    ('Food allergies', _listOrNone(profile.foodAllergies)),
                    ('Reaction type', profile.allergyReaction),
                    ('Severity', profile.allergySeverity),
                  ],
                ),
                _ProfileSection(
                  title: 'Current Medicines',
                  icon: Icons.medication_outlined,
                  status: profile.currentMedicines.isEmpty
                      ? 'Not added'
                      : 'Added',
                  lastUpdated: profile.lastUpdatedLabel,
                  rows: [
                    ('Medicines', _listOrNone(profile.currentMedicines)),
                    ('Safety use', 'Used later for interaction checks'),
                  ],
                ),
                _ProfileSection(
                  title: 'Emergency Contact',
                  icon: Icons.contact_emergency_outlined,
                  status: profile.hasEmergencyContact ? 'Added' : 'Not added',
                  lastUpdated: profile.lastUpdatedLabel,
                  rows: [
                    ('Name', profile.emergencyName),
                    ('Relationship', profile.emergencyRelationship),
                    ('Country code', profile.emergencyCountryCode),
                    ('Phone number', profile.emergencyPhone),
                  ],
                ),
                _ProfileSection(
                  title: 'Privacy & Security',
                  icon: Icons.privacy_tip_outlined,
                  status: profile.dataConsent
                      ? 'Consent saved'
                      : 'Consent needed',
                  lastUpdated: profile.lastUpdatedLabel,
                  rows: [
                    ('Change password', 'Available from Privacy & Security'),
                    ('Export data', 'Profile, reminders, scans, history'),
                    ('Delete account', 'Requires confirmation'),
                    (
                      'Data consent',
                      profile.dataConsent ? 'Allowed' : 'Not allowed',
                    ),
                  ],
                ),
                const _MedicalDisclaimerCard(),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save Health Profile',
                  onPressed: () => _save(profile),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _status(bool complete) => complete ? 'Added' : 'Incomplete';

  static String _listOrNone(List<String> values) {
    if (values.isEmpty) return 'Not added';
    return values.join(', ');
  }
}

class _HealthProfileErrorState extends StatelessWidget {
  const _HealthProfileErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: AppColors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load your health profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
      ),
    );
  }
}

class _CompletionHeader extends StatelessWidget {
  const _CompletionHeader({required this.profile});

  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.ocean.withValues(alpha: .12),
            child: Text(
              '${profile.completionPercent}%',
              style: const TextStyle(
                color: AppColors.ocean,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile ${profile.completionPercent}% complete',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.missingGuidance,
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: profile.completionPercent / 100,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetySummary extends StatelessWidget {
  const _SafetySummary({required this.profile});

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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(
                label: 'Known allergies',
                value: '${profile.allergies.length}',
                icon: Icons.warning_amber_outlined,
              ),
              _SummaryPill(
                label: 'Current medicines',
                value: '${profile.currentMedicines.length}',
                icon: Icons.medication_outlined,
              ),
              _SummaryPill(
                label: 'Conditions',
                value: '${profile.chronicDiseases.length}',
                icon: Icons.monitor_heart_outlined,
              ),
              _SummaryPill(
                label: 'Emergency contact',
                value: profile.hasEmergencyContact ? 'Added' : 'Missing',
                icon: Icons.contact_phone_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Last updated: ${profile.lastUpdatedLabel}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.ocean, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionStatusCard extends StatelessWidget {
  const _SectionStatusCard({required this.profile});

  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _StatusRow(
            label: 'Medical Profile',
            status: profile.currentMedicines.isEmpty ? 'Incomplete' : 'Added',
          ),
          _StatusRow(
            label: 'Allergies',
            status: profile.allergies.isEmpty ? 'Not added' : 'Added',
          ),
          _StatusRow(
            label: 'Emergency Contact',
            status: profile.hasEmergencyContact ? 'Added' : 'Not added',
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final ok = status == 'Added' || status == 'Consent saved';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: ok ? AppColors.emerald : AppColors.amber,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.status,
    required this.lastUpdated,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final String status;
  final String lastUpdated;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.ocean),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$title - $status',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: $lastUpdated',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const Divider(height: 22),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        row.$2,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalDisclaimerCard extends StatelessWidget {
  const _MedicalDisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.medical_information_outlined, color: AppColors.ocean),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Medical disclaimer: Mediverse AI helps you learn and check medicine safety, but it does not replace doctors, pharmacists, diagnosis, or emergency care.',
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
