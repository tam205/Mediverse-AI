import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/section_header.dart';
import '../history/services/history_repository.dart';
import '../profile/models/health_profile.dart';
import '../profile/services/health_profile_repository.dart';
import '../shared/interaction_list.dart';
import 'interaction_result.dart';
import 'medicine_details_screen.dart';
import 'models/medicine.dart';
import 'result_screen.dart';
import 'services/interaction_engine.dart';
import 'services/medicine_repository.dart';

class DrugCheckerScreen extends StatefulWidget {
  const DrugCheckerScreen({super.key});

  @override
  State<DrugCheckerScreen> createState() => _DrugCheckerScreenState();
}

class _DrugCheckerScreenState extends State<DrugCheckerScreen> {
  final _repository = const MedicineRepository();
  final _profileRepository = const HealthProfileRepository();
  final _historyRepository = const HistoryRepository();
  final _engine = const InteractionEngine();
  final _searchController = TextEditingController();
  final List<Medicine> _selectedMedicines = [];
  late Future<List<Medicine>> _suggestionsFuture;
  late Future<HealthProfile> _profileFuture;
  bool _checking = false;
  bool _profileUnavailable = false;

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = _repository.searchMedicines('');
    _profileFuture = _profileRepository.getProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    setState(() => _suggestionsFuture = _repository.searchMedicines(value));
  }

  void _addMedicine(Medicine medicine) {
    final exists = _selectedMedicines.any((item) => item.id == medicine.id);
    if (exists) return;

    setState(() {
      _selectedMedicines.add(medicine);
      _searchController.clear();
      _suggestionsFuture = _repository.searchMedicines('');
    });
  }

  void _removeMedicine(String id) {
    setState(
      () => _selectedMedicines.removeWhere((medicine) => medicine.id == id),
    );
  }

  Future<void> _addCurrentMedicines(HealthProfile profile) async {
    final medicineNames = profile.currentMedicineEntries.isNotEmpty
        ? profile.currentMedicineEntries.map(
            (medicine) => medicine.normalizedName ?? medicine.name,
          )
        : profile.currentMedicines;

    for (final medicine in medicineNames) {
      final resolved = await _repository.getMedicine(medicine);
      if (resolved.approved) _addMedicine(resolved);
    }
  }

  Future<void> _checkInteraction(HealthProfile profile) async {
    final medicines = _selectedMedicines;
    final savedMedicines = _profileUnavailable
        ? const <String>[]
        : profile.currentMedicines;
    final combinedMedicineCount = {
      ...medicines.map((medicine) => medicine.id),
      ...savedMedicines.map(Medicine.normalizeId),
    }.length;

    if (combinedMedicineCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least two different medicines, or add current medicines to your health profile.',
          ),
        ),
      );
      return;
    }

    setState(() => _checking = true);
    try {
      final result = await _engine.check(
        medicines,
        profile: _profileUnavailable ? null : profile,
      );
      if (!mounted) return;
      await _saveHistory(result, !_profileUnavailable);
      if (!mounted) return;
      context.pushScreen(ResultScreen(result: result, savedToHistory: true));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not complete the safety check. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _saveHistory(
    InteractionResultCopy result,
    bool profileIncluded,
  ) async {
    try {
      await _historyRepository.saveInteraction(
        result,
        medicines: _selectedMedicines
            .map((medicine) => medicine.genericName)
            .toList(),
        profileIncluded: profileIncluded,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The check completed, but history was not saved.'),
        ),
      );
    }
  }

  void _retryProfile() {
    setState(() {
      _profileUnavailable = false;
      _profileFuture = _profileRepository.getProfile();
    });
  }

  void _showHowItWorks() {
    showDialog<void>(
      context: context,
      builder: (_) => const _HowItWorksDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Medicine Safety Check'),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            tooltip: 'How it works',
            icon: const Icon(Icons.help_outline),
            onPressed: _showHowItWorks,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF7F5), Color(0xFFF7FBFA), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ScreenPadding(
          child: FutureBuilder<HealthProfile>(
            future: _profileFuture,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DrugCheckerHero(medicineCount: 0, profileReady: false),
                    SizedBox(height: 14),
                    _LoadingProfileCard(),
                  ],
                );
              }

              final hasProfileError = profileSnapshot.hasError;
              final profile = hasProfileError
                  ? HealthProfile.empty
                  : profileSnapshot.data ?? HealthProfile.empty;
              _profileUnavailable = hasProfileError;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DrugCheckerHero(
                    medicineCount: _selectedMedicines.length,
                    profileReady: !hasProfileError,
                  ),
                  const SizedBox(height: 14),
                  if (hasProfileError)
                    _ProfileErrorCard(onRetry: _retryProfile)
                  else
                    _ProfileSafetyCard(
                      profile: profile,
                      onAddCurrentMedicines: () =>
                          _addCurrentMedicines(profile),
                    ),
                  const SizedBox(height: 18),
                  _MedicineSearchSection(
                    controller: _searchController,
                    suggestionsFuture: _suggestionsFuture,
                    onSearch: _search,
                    onAddMedicine: _addMedicine,
                  ),
                  const SizedBox(height: 18),
                  _CompareMedicinesSection(
                    medicines: _selectedMedicines,
                    selectedCount: _selectedMedicines.length,
                    onRemove: _removeMedicine,
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: _checking
                        ? 'Checking safety...'
                        : 'Check for safety concerns',
                    onPressed: _checking
                        ? null
                        : () => _checkInteraction(profile),
                  ),
                  const SizedBox(height: 14),
                  const _MedicalDisclaimerNote(),
                  const SizedBox(height: 14),
                  const _PrivacyNote(),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    title: 'Recent safety checks',
                    action: 'View all',
                  ),
                  const SizedBox(height: 12),
                  const InteractionList(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DrugCheckerHero extends StatelessWidget {
  const _DrugCheckerHero({
    required this.medicineCount,
    required this.profileReady,
  });

  final int medicineCount;
  final bool profileReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepNavy, AppColors.deepTeal, AppColors.ocean],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.ocean.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check medicine safety',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compare medicines and identify possible safety concerns based on your health profile.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(
                icon: Icons.medication_liquid_outlined,
                label: '$medicineCount selected',
              ),
              _HeroMetric(
                icon: profileReady
                    ? Icons.verified_user_outlined
                    : Icons.info_outline,
                label: profileReady
                    ? 'Health profile included'
                    : 'Health profile not included',
              ),
              const _HeroMetric(
                icon: Icons.security_outlined,
                label: 'Private and secure',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.aqua, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksDialog extends StatelessWidget {
  const _HowItWorksDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How it works'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepRow(
            number: '1',
            title: 'Choose medicines',
            body: 'Search or type the medicines you want to compare.',
          ),
          _StepRow(
            number: '2',
            title: 'Use your health profile',
            body:
                'Saved allergies, conditions, and treatments improve safety context.',
          ),
          _StepRow(
            number: '3',
            title: 'Read clear guidance',
            body:
                'See no known concern found, caution advised, or high-risk warning with practical next steps.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.ocean,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingProfileCard extends StatelessWidget {
  const _LoadingProfileCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading your health profile so saved allergies, conditions, and treatments can be included.',
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  const _ProfileErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health profile not included',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'We could not load your health profile. You can continue with a general medicine check or try again.',
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSafetyCard extends StatelessWidget {
  const _ProfileSafetyCard({
    required this.profile,
    required this.onAddCurrentMedicines,
  });

  final HealthProfile profile;
  final Future<void> Function() onAddCurrentMedicines;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalized safety check enabled',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your saved allergies, conditions, and treatments will be considered during this check.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SafetyPill(
                icon: Icons.warning_amber_outlined,
                label: 'Allergies: ${profile.allergies.length}',
                color: AppColors.amber,
              ),
              _SafetyPill(
                icon: Icons.medication_outlined,
                label: 'Treatments: ${profile.currentMedicines.length}',
                color: AppColors.ocean,
              ),
              _SafetyPill(
                icon: Icons.monitor_heart_outlined,
                label: 'Conditions: ${profile.chronicDiseases.length}',
                color: AppColors.sky,
              ),
            ],
          ),
          if (profile.currentMedicines.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAddCurrentMedicines,
              icon: const Icon(Icons.add),
              label: const Text('Include my saved medicines'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicineSearchSection extends StatelessWidget {
  const _MedicineSearchSection({
    required this.controller,
    required this.suggestionsFuture,
    required this.onSearch,
    required this.onAddMedicine,
  });

  final TextEditingController controller;
  final Future<List<Medicine>> suggestionsFuture;
  final ValueChanged<String> onSearch;
  final ValueChanged<Medicine> onAddMedicine;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find a medicine',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search by generic or brand name.',
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 14),
          MediverseTextField(
            hint: 'Search by medicine name',
            controller: controller,
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: onSearch,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Medicine>>(
            future: suggestionsFuture,
            builder: (context, snapshot) {
              final medicines = snapshot.data ?? Medicine.demo;
              return Column(
                children: medicines.take(6).map((medicine) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MedicineSuggestionChip(
                      medicine: medicine,
                      onView: () => context.pushScreen(
                        MedicineDetailsScreen(name: medicine.name),
                      ),
                      onAdd: () => onAddMedicine(medicine),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MedicineSuggestionChip extends StatelessWidget {
  const MedicineSuggestionChip({
    super.key,
    required this.medicine,
    required this.onView,
    required this.onAdd,
  });

  final Medicine medicine;
  final VoidCallback onView;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 360;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: medicine.color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 12,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: isSmallScreen ? 22 : 24,
                  color: medicine.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (medicine.brandNames.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Brands: ${medicine.brandNames.join(', ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: isSmallScreen ? 11 : 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        [
                          medicine.activeIngredient,
                          medicine.dosageForm,
                        ].where((value) => value.isNotEmpty).join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: isSmallScreen ? 11 : 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Add medicine',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareMedicinesSection extends StatelessWidget {
  const _CompareMedicinesSection({
    required this.medicines,
    required this.selectedCount,
    required this.onRemove,
  });

  final List<Medicine> medicines;
  final int selectedCount;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Selected medicines',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ocean.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$selectedCount selected',
                  style: const TextStyle(
                    color: AppColors.ocean,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose reviewed medicines from search suggestions. This keeps the check tied to stable medicine IDs instead of uncontrolled text.',
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (medicines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.ocean.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.ocean.withValues(alpha: .14),
                ),
              ),
              child: const Text(
                'No medicines selected yet. Use the search suggestions above to add medicines.',
                style: TextStyle(color: AppColors.muted, height: 1.35),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medicines
                  .map(
                    (medicine) => InputChip(
                      avatar: Icon(
                        Icons.medication_outlined,
                        color: medicine.color,
                        size: 18,
                      ),
                      label: Text(medicine.genericName),
                      tooltip: medicine.suggestionSubtitle,
                      onDeleted: () => onRemove(medicine.id),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SafetyPill extends StatelessWidget {
  const _SafetyPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalDisclaimerNote extends StatelessWidget {
  const _MedicalDisclaimerNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withValues(alpha: .24)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.amber, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This tool provides general medicine-safety information. It does not replace advice from a doctor or pharmacist. Do not start, stop, or change a medicine without professional guidance.',
              style: TextStyle(
                color: AppColors.ink,
                height: 1.35,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ocean.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ocean.withValues(alpha: .18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: AppColors.ocean, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your medicine checks are stored securely in your private account.',
              style: TextStyle(
                color: AppColors.ocean,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
