import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/form_fields.dart';
import '../drug_checker/models/medicine.dart';
import '../profile/models/health_profile.dart';
import '../profile/services/health_profile_repository.dart';

class FirstTimeOnboardingScreen extends StatefulWidget {
  const FirstTimeOnboardingScreen({super.key});

  @override
  State<FirstTimeOnboardingScreen> createState() =>
      _FirstTimeOnboardingScreenState();
}

class _FirstTimeOnboardingScreenState extends State<FirstTimeOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileRepository = const HealthProfileRepository();
  final _userService = const UserService();

  final _ageController = TextEditingController();
  final _countryController = TextEditingController();
  final _allergyController = TextEditingController();
  final _medicineController = TextEditingController();
  final _conditionController = TextEditingController();

  final _allergies = <String>[];
  final _currentMedicines = <String>[];
  final _otherConditions = <String>[];

  bool _hasDiabetes = false;
  bool _hasHypertension = false;
  bool _hasAsthma = false;
  bool _consent = false;
  bool _saving = false;

  @override
  void dispose() {
    _ageController.dispose();
    _countryController.dispose();
    _allergyController.dispose();
    _medicineController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _addItem({
    required TextEditingController controller,
    required List<String> target,
  }) {
    final value = controller.text.trim();
    if (value.isEmpty) return;

    final exists = target.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (!exists) {
      setState(() => target.add(value));
    }
    controller.clear();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the medical safety consent to continue.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final allergies = _allergies
          .map(
            (substance) => Allergy(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              substance: substance,
              reaction: 'Not specified',
              severity: AllergySeverity.unknown,
            ),
          )
          .toList();

      final profile = HealthProfile.empty.copyWith(
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        country: _countryController.text.trim(),
        allergyEntries: allergies,
        medicineAllergies: _allergies,
        currentMedicineEntries: _currentMedicines
            .map(
              (name) => CurrentMedicine(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: name,
                normalizedName: Medicine.normalizeId(name),
              ),
            )
            .toList(),
        currentMedicines: _currentMedicines,
        hasDiabetes: _hasDiabetes,
        hasHypertension: _hasHypertension,
        hasAsthma: _hasAsthma,
        otherChronicDiseases: _otherConditions,
        allergiesReviewed: true,
        medicinesReviewed: true,
        conditionsReviewed: true,
        dataConsent: _consent,
        lastUpdated: DateTime.now(),
      );

      await _profileRepository.saveProfile(profile);
      await _userService.markProfileCompleted();
    } catch (error, stackTrace) {
      debugPrint('Onboarding save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not save your profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
            children: [
              const Text(
                'Complete your safety profile',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These details help Mediverse AI personalize medicine safety checks.',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 22),
              _OnboardingSection(
                title: 'Basic information',
                icon: Icons.person_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel('Age'),
                    MediverseTextField(
                      hint: 'For example, 34',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final age = int.tryParse(value?.trim() ?? '');
                        if (age == null || age < 1 || age > 120) {
                          return 'Enter a valid age.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    FieldLabel('Country'),
                    MediverseTextField(
                      hint: 'Where you live',
                      controller: _countryController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter your country.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _OnboardingSection(
                title: 'Allergies',
                icon: Icons.warning_amber_rounded,
                child: _ChipEntryField(
                  hint: 'Add an allergy',
                  controller: _allergyController,
                  values: _allergies,
                  onAdd: () => _addItem(
                    controller: _allergyController,
                    target: _allergies,
                  ),
                  onRemove: (index) =>
                      setState(() => _allergies.removeAt(index)),
                  emptyText: 'No allergies added.',
                ),
              ),
              const SizedBox(height: 16),
              _OnboardingSection(
                title: 'Current medicines',
                icon: Icons.medication_outlined,
                child: _ChipEntryField(
                  hint: 'Add a medicine',
                  controller: _medicineController,
                  values: _currentMedicines,
                  onAdd: () => _addItem(
                    controller: _medicineController,
                    target: _currentMedicines,
                  ),
                  onRemove: (index) =>
                      setState(() => _currentMedicines.removeAt(index)),
                  emptyText: 'No medicines added.',
                ),
              ),
              const SizedBox(height: 16),
              _OnboardingSection(
                title: 'Chronic conditions',
                icon: Icons.monitor_heart_outlined,
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _hasDiabetes,
                      onChanged: (value) =>
                          setState(() => _hasDiabetes = value ?? false),
                      title: const Text('Diabetes'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: _hasHypertension,
                      onChanged: (value) =>
                          setState(() => _hasHypertension = value ?? false),
                      title: const Text('Hypertension'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: _hasAsthma,
                      onChanged: (value) =>
                          setState(() => _hasAsthma = value ?? false),
                      title: const Text('Asthma'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    _ChipEntryField(
                      hint: 'Add another condition',
                      controller: _conditionController,
                      values: _otherConditions,
                      onAdd: () => _addItem(
                        controller: _conditionController,
                        target: _otherConditions,
                      ),
                      onRemove: (index) =>
                          setState(() => _otherConditions.removeAt(index)),
                      emptyText: 'No other conditions added.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _OnboardingSection(
                title: 'Consent',
                icon: Icons.verified_user_outlined,
                child: CheckboxListTile(
                  value: _consent,
                  onChanged: (value) =>
                      setState(() => _consent = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use my profile for safety checks'),
                  subtitle: const Text(
                    'Mediverse AI provides educational information and does not replace advice from a doctor or pharmacist.',
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _saving ? null : _completeOnboarding,
                child: Text(_saving ? 'Saving...' : 'Continue to Mediverse AI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSection extends StatelessWidget {
  const _OnboardingSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.ocean),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChipEntryField extends StatelessWidget {
  const _ChipEntryField({
    required this.hint,
    required this.controller,
    required this.values,
    required this.onAdd,
    required this.onRemove,
    required this.emptyText,
  });

  final String hint;
  final TextEditingController controller;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: MediverseTextField(
                hint: hint,
                controller: controller,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Add',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (values.isEmpty)
          Text(emptyText, style: const TextStyle(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.asMap().entries.map((entry) {
              return InputChip(
                label: Text(entry.value),
                onDeleted: () => onRemove(entry.key),
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
              );
            }).toList(),
          ),
      ],
    );
  }
}
