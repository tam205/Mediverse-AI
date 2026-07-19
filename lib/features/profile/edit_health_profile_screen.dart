import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../drug_checker/models/medicine.dart';
import 'models/health_profile.dart';
import 'services/health_profile_repository.dart';

class EditHealthProfileScreen extends StatefulWidget {
  const EditHealthProfileScreen({super.key, required this.initialProfile});

  final HealthProfile initialProfile;

  @override
  State<EditHealthProfileScreen> createState() =>
      _EditHealthProfileScreenState();
}

class _EditHealthProfileScreenState extends State<EditHealthProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = const HealthProfileRepository();

  late final TextEditingController _ageController;
  late final TextEditingController _countryController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _currentMedicineController;
  late final TextEditingController _conditionController;

  late List<Allergy> _allergies;
  late List<String> _currentMedicines;
  late List<String> _chronicDiseases;
  late bool _hasDiabetes;
  late bool _hasHypertension;
  late bool _hasAsthma;
  late bool _dataConsent;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _ageController = TextEditingController(
      text: profile.age > 0 ? profile.age.toString() : '',
    );
    _countryController = TextEditingController(text: profile.country);
    _bloodGroupController = TextEditingController(text: profile.bloodGroup);
    _currentMedicineController = TextEditingController();
    _conditionController = TextEditingController();
    _allergies = [...profile.allergyEntries];
    if (_allergies.isEmpty) {
      _allergies = profile.medicineAllergies
          .map(
            (substance) => Allergy(
              id: _newAllergyId(),
              substance: substance,
              reaction: profile.allergyReaction,
              severity: AllergySeverity.fromStoredValue(
                profile.allergySeverity,
              ),
            ),
          )
          .toList();
    }
    _currentMedicines = [...profile.currentMedicines];
    _chronicDiseases = [...profile.otherChronicDiseases];
    _hasDiabetes = profile.hasDiabetes;
    _hasHypertension = profile.hasHypertension;
    _hasAsthma = profile.hasAsthma;
    _dataConsent = profile.dataConsent;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _countryController.dispose();
    _bloodGroupController.dispose();
    _currentMedicineController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final allergySubstances = _allergies
          .map((allergy) => allergy.substance.trim())
          .where((substance) => substance.isNotEmpty)
          .toList();
      final profile = widget.initialProfile.copyWith(
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        country: _countryController.text.trim(),
        bloodGroup: _bloodGroupController.text.trim(),
        allergyEntries: _allergies,
        medicineAllergies: allergySubstances,
        foodAllergies: widget.initialProfile.foodAllergies,
        hasDiabetes: _hasDiabetes,
        hasHypertension: _hasHypertension,
        hasAsthma: _hasAsthma,
        otherChronicDiseases: _chronicDiseases,
        allergiesReviewed: true,
        currentMedicineEntries: _currentMedicines
            .map(
              (name) => CurrentMedicine(
                id: _newMedicineId(),
                name: name,
                normalizedName: Medicine.normalizeId(name),
              ),
            )
            .toList(),
        currentMedicines: _currentMedicines,
        medicinesReviewed: true,
        conditionsReviewed: true,
        dataConsent: _dataConsent,
        lastUpdated: DateTime.now(),
      );

      await _repository.saveProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Profile update failed: $error');
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

  void _addTextItem({
    required TextEditingController controller,
    required List<String> target,
    required ValueChanged<List<String>> onChanged,
  }) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    final exists = target.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (exists) {
      controller.clear();
      return;
    }
    onChanged([...target, value]);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MediverseAppBar(title: 'Edit health profile'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _EditorTitle(
                    icon: Icons.person_outline,
                    title: 'Basic information',
                  ),
                  const SizedBox(height: 16),
                  FieldLabel('Age'),
                  MediverseTextField(
                    hint: 'For example, 34',
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final age = int.tryParse(text);
                      if (age == null || age < 0 || age > 120) {
                        return 'Enter a valid age.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  FieldLabel('Country'),
                  MediverseTextField(
                    hint: 'Country',
                    controller: _countryController,
                  ),
                  const SizedBox(height: 14),
                  FieldLabel('Blood group'),
                  MediverseTextField(
                    hint: 'For example, O+',
                    controller: _bloodGroupController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: _AllergyEditor(
                allergies: _allergies,
                onChanged: (value) => setState(() => _allergies = value),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: _StringListEditor(
                title: 'Current medicines',
                hint: 'Add a medicine',
                controller: _currentMedicineController,
                values: _currentMedicines,
                icon: Icons.medication_outlined,
                onAdd: () => _addTextItem(
                  controller: _currentMedicineController,
                  target: _currentMedicines,
                  onChanged: (value) =>
                      setState(() => _currentMedicines = value),
                ),
                onRemove: (index) => setState(
                  () =>
                      _currentMedicines = [..._currentMedicines]
                        ..removeAt(index),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _EditorTitle(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Chronic conditions',
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  _StringListEditor(
                    title: 'Other conditions',
                    hint: 'Add a condition',
                    controller: _conditionController,
                    values: _chronicDiseases,
                    icon: Icons.add_circle_outline,
                    onAdd: _addOtherCondition,
                    onRemove: (index) {
                      setState(
                        () =>
                            _chronicDiseases = [..._chronicDiseases]
                              ..removeAt(index),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _dataConsent,
              onChanged: (value) => setState(() => _dataConsent = value),
              title: const Text('Allow profile data for safety checks'),
              subtitle: const Text(
                'Your saved allergies, conditions, and medicines can be used to personalize safety checks.',
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: _saving ? 'Saving...' : 'Save changes',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  void _addOtherCondition() {
    final value = _conditionController.text.trim();
    if (value.isEmpty) return;

    final reserved = {'diabetes', 'hypertension', 'asthma'};
    if (reserved.contains(value.toLowerCase())) {
      _conditionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use the checkbox for this condition instead.'),
        ),
      );
      return;
    }

    _addTextItem(
      controller: _conditionController,
      target: _chronicDiseases,
      onChanged: (value) => setState(() => _chronicDiseases = value),
    );
  }
}

class _EditorTitle extends StatelessWidget {
  const _EditorTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.ocean),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ),
      ],
    );
  }
}

class _AllergyEditor extends StatelessWidget {
  const _AllergyEditor({required this.allergies, required this.onChanged});

  final List<Allergy> allergies;
  final ValueChanged<List<Allergy>> onChanged;

  Future<void> _addAllergy(BuildContext context) async {
    final allergy = await showDialog<Allergy>(
      context: context,
      builder: (_) => const AddAllergyDialog(),
    );
    if (!context.mounted) return;
    if (allergy == null) return;
    if (_allergyAlreadyExists(allergy.substance)) {
      _showDuplicateAllergyMessage(context);
      return;
    }
    onChanged([...allergies, allergy]);
  }

  Future<void> _editAllergy(BuildContext context, int index) async {
    final allergy = await showDialog<Allergy>(
      context: context,
      builder: (_) => AddAllergyDialog(initialAllergy: allergies[index]),
    );
    if (!context.mounted) return;
    if (allergy == null) return;
    if (_allergyAlreadyExists(allergy.substance, excludingIndex: index)) {
      _showDuplicateAllergyMessage(context);
      return;
    }
    final updated = [...allergies]..[index] = allergy;
    onChanged(updated);
  }

  void _removeAllergy(int index) {
    final updated = [...allergies]..removeAt(index);
    onChanged(updated);
  }

  bool _allergyAlreadyExists(String substance, {int? excludingIndex}) {
    final normalized = substance.trim().toLowerCase();
    return allergies.asMap().entries.any((entry) {
      if (entry.key == excludingIndex) return false;
      return entry.value.substance.trim().toLowerCase() == normalized;
    });
  }

  void _showDuplicateAllergyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This allergy is already recorded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _EditorTitle(
                icon: Icons.warning_amber_outlined,
                title: 'Allergies',
              ),
            ),
            TextButton.icon(
              onPressed: () => _addAllergy(context),
              icon: const Icon(Icons.add),
              label: const Text('Add allergy'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (allergies.isEmpty)
          const Text(
            'No allergies recorded.',
            style: TextStyle(color: AppColors.muted),
          )
        else
          ...allergies.asMap().entries.map((entry) {
            final allergy = entry.value;
            return Card(
              elevation: 0,
              color: AppColors.surfaceTint,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_outlined),
                title: Text(allergy.substance),
                subtitle: Text(
                  '${allergy.reaction} • ${allergy.severity.label}',
                ),
                onTap: () => _editAllergy(context, entry.key),
                trailing: IconButton(
                  tooltip: 'Remove allergy',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeAllergy(entry.key),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class AddAllergyDialog extends StatefulWidget {
  const AddAllergyDialog({super.key, this.initialAllergy});

  final Allergy? initialAllergy;

  @override
  State<AddAllergyDialog> createState() => _AddAllergyDialogState();
}

class _AddAllergyDialogState extends State<AddAllergyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _substanceController;
  late final TextEditingController _reactionController;
  late AllergySeverity _severity;

  @override
  void initState() {
    super.initState();
    final allergy = widget.initialAllergy;
    _substanceController = TextEditingController(
      text: allergy?.substance ?? '',
    );
    _reactionController = TextEditingController(text: allergy?.reaction ?? '');
    _severity = allergy?.severity ?? AllergySeverity.moderate;
  }

  @override
  void dispose() {
    _substanceController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Allergy(
        id: widget.initialAllergy?.id ?? _newAllergyId(),
        substance: _substanceController.text.trim(),
        reaction: _reactionController.text.trim(),
        severity: _severity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialAllergy == null ? 'Add allergy' : 'Edit allergy',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _substanceController,
                decoration: const InputDecoration(
                  labelText: 'Medicine or substance',
                  hintText: 'For example, penicillin',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the medicine or substance.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reactionController,
                decoration: const InputDecoration(
                  labelText: 'Reaction',
                  hintText: 'For example, rash or swelling',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Describe the reaction.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AllergySeverity>(
                initialValue: _severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: const [
                  DropdownMenuItem(
                    value: AllergySeverity.mild,
                    child: Text('Mild'),
                  ),
                  DropdownMenuItem(
                    value: AllergySeverity.moderate,
                    child: Text('Moderate'),
                  ),
                  DropdownMenuItem(
                    value: AllergySeverity.severe,
                    child: Text('Severe'),
                  ),
                  DropdownMenuItem(
                    value: AllergySeverity.unknown,
                    child: Text('Not sure'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _severity = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _StringListEditor extends StatelessWidget {
  const _StringListEditor({
    required this.title,
    required this.hint,
    required this.controller,
    required this.values,
    required this.icon,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String hint;
  final TextEditingController controller;
  final List<String> values;
  final IconData icon;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditorTitle(icon: icon, title: title),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MediverseTextField(
                hint: hint,
                controller: controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Add',
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (values.isEmpty)
          const Text('None recorded.', style: TextStyle(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.asMap().entries.map((entry) {
              return InputChip(
                label: Text(entry.value),
                onDeleted: () => onRemove(entry.key),
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
      ],
    );
  }
}

String _newAllergyId() => DateTime.now().microsecondsSinceEpoch.toString();

String _newMedicineId() => DateTime.now().microsecondsSinceEpoch.toString();
