import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/drug_checker/models/medicine.dart';
import '../../shared/utils/firebase_error_messages.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import 'models/health_profile.dart';
import 'services/health_profile_repository.dart';

class CurrentMedicinesScreen extends StatefulWidget {
  const CurrentMedicinesScreen({super.key});

  @override
  State<CurrentMedicinesScreen> createState() => _CurrentMedicinesScreenState();
}

class _CurrentMedicinesScreenState extends State<CurrentMedicinesScreen> {
  final _repository = const HealthProfileRepository();
  late Future<HealthProfile> _profileFuture;

  HealthProfile? _profile;
  List<CurrentMedicine> _medicines = const [];
  bool _noCurrentMedicines = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<HealthProfile> _loadProfile() async {
    final profile = await _repository.getProfile();
    _profile = profile;
    _medicines = _initialMedicines(profile);
    _noCurrentMedicines = profile.medicinesReviewed && _medicines.isEmpty;
    return profile;
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty || _saving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard your changes?'),
        content: const Text('You have changes that have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) return;

    if (!_noCurrentMedicines && _medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a medicine or choose no current medicines.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final savedMedicines = _noCurrentMedicines
          ? <CurrentMedicine>[]
          : _medicines;
      final updatedProfile = profile.copyWith(
        currentMedicineEntries: savedMedicines,
        currentMedicines: savedMedicines
            .map((medicine) => medicine.name.trim())
            .where((name) => name.isNotEmpty)
            .toList(),
        medicinesReviewed: true,
        lastUpdated: DateTime.now(),
      );

      await _repository.saveProfile(updatedProfile);
      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _medicines = savedMedicines;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current medicines updated successfully.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Current medicines save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyDatabaseMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addMedicine() async {
    final medicine = await showDialog<CurrentMedicine>(
      context: context,
      builder: (_) => const _MedicineDialog(),
    );
    if (!mounted || medicine == null) return;
    if (_containsMedicine(medicine)) {
      _showDuplicateMessage();
      return;
    }
    setState(() {
      _medicines = [..._medicines, medicine];
      _noCurrentMedicines = false;
      _dirty = true;
    });
  }

  Future<void> _editMedicine(int index) async {
    final medicine = await showDialog<CurrentMedicine>(
      context: context,
      builder: (_) => _MedicineDialog(initialMedicine: _medicines[index]),
    );
    if (!mounted || medicine == null) return;
    if (_containsMedicine(medicine, excludingIndex: index)) {
      _showDuplicateMessage();
      return;
    }
    setState(() {
      _medicines = [..._medicines]..[index] = medicine;
      _dirty = true;
    });
  }

  Future<void> _removeMedicine(int index) async {
    final medicine = _medicines[index];
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${medicine.name}?'),
        content: const Text(
          'This medicine will no longer be considered automatically in safety checks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove != true) return;
    setState(() {
      _medicines = [..._medicines]..removeAt(index);
      _dirty = true;
    });
  }

  Future<void> _toggleNoCurrentMedicines(bool value) async {
    if (!value) {
      setState(() {
        _noCurrentMedicines = false;
        _dirty = true;
      });
      return;
    }

    if (_medicines.isNotEmpty) {
      final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear current medicines?'),
          content: const Text(
            'Your saved medicines will be removed and an empty list will be saved intentionally.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        ),
      );
      if (clear != true) return;
    }

    setState(() {
      _noCurrentMedicines = true;
      _medicines = const [];
      _dirty = true;
    });
  }

  bool _containsMedicine(CurrentMedicine candidate, {int? excludingIndex}) {
    final normalized = candidate.normalized;
    if (normalized.isEmpty) return false;
    return _medicines.asMap().entries.any((entry) {
      if (entry.key == excludingIndex) return false;
      return entry.value.normalized == normalized;
    });
  }

  void _showDuplicateMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This medicine is already in your current medicines.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: const MediverseAppBar(title: 'Current medicines'),
        body: FutureBuilder<HealthProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _MedicinesErrorState(
                message: friendlyDatabaseMessage(snapshot.error!),
                onRetry: () {
                  setState(() => _profileFuture = _loadProfile());
                },
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              children: [
                const AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.medication_outlined, color: AppColors.ocean),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add medicines you currently take so safety checks can consider them automatically.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _noCurrentMedicines,
                    onChanged: _saving ? null : _toggleNoCurrentMedicines,
                    title: const Text(
                      'I am not currently taking any medicines',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Choose this only after reviewing your current medicines.',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_medicines.isEmpty)
                  _MedicineEmptyState(
                    reviewed: _profile?.medicinesReviewed ?? false,
                    noCurrentMedicines: _noCurrentMedicines,
                    onAdd: _saving ? null : _addMedicine,
                  )
                else
                  ..._medicines.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CurrentMedicineCard(
                        medicine: entry.value,
                        onEdit: _saving ? null : () => _editMedicine(entry.key),
                        onRemove: _saving
                            ? null
                            : () => _removeMedicine(entry.key),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _addMedicine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add medicine'),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _saving ? 'Saving...' : 'Save changes',
                  onPressed: _saving ? null : _save,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static List<CurrentMedicine> _initialMedicines(HealthProfile profile) {
    if (profile.currentMedicineEntries.isNotEmpty) {
      return [...profile.currentMedicineEntries];
    }
    return profile.currentMedicines
        .map(
          (name) => CurrentMedicine(
            id: _newMedicineId(),
            name: name,
            normalizedName: Medicine.normalizeId(name),
          ),
        )
        .where((medicine) => medicine.name.trim().isNotEmpty)
        .toList();
  }
}

class _CurrentMedicineCard extends StatelessWidget {
  const _CurrentMedicineCard({
    required this.medicine,
    required this.onEdit,
    required this.onRemove,
  });

  final CurrentMedicine medicine;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.medication_outlined, color: AppColors.ocean),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    if (medicine.detailsLine.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        medicine.detailsLine,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                    if (medicine.reason?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 7),
                      Text(
                        medicine.reason!,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      'Safety name: ${medicine.normalized}',
                      style: const TextStyle(
                        color: AppColors.softMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicineEmptyState extends StatelessWidget {
  const _MedicineEmptyState({
    required this.reviewed,
    required this.noCurrentMedicines,
    required this.onAdd,
  });

  final bool reviewed;
  final bool noCurrentMedicines;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (noCurrentMedicines) {
      return const AppCard(
        child: Text(
          'You confirmed that you are not currently taking any medicines.',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reviewed
                ? 'No current medicines added'
                : 'You have not reviewed your current medicines yet',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add medicines you currently take so interaction checks can consider them.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(reviewed ? 'Add medicine' : 'Review medicines'),
          ),
        ],
      ),
    );
  }
}

class _MedicineDialog extends StatefulWidget {
  const _MedicineDialog({this.initialMedicine});

  final CurrentMedicine? initialMedicine;

  @override
  State<_MedicineDialog> createState() => _MedicineDialogState();
}

class _MedicineDialogState extends State<_MedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _strengthController;
  late final TextEditingController _doseController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _reasonController;
  late final TextEditingController _startDateController;

  @override
  void initState() {
    super.initState();
    final medicine = widget.initialMedicine;
    _nameController = TextEditingController(text: medicine?.name);
    _strengthController = TextEditingController(text: medicine?.strength);
    _doseController = TextEditingController(text: medicine?.dose);
    _frequencyController = TextEditingController(text: medicine?.frequency);
    _reasonController = TextEditingController(text: medicine?.reason);
    _startDateController = TextEditingController(
      text: medicine?.startDate == null ? '' : _dateLabel(medicine!.startDate!),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _doseController.dispose();
    _frequencyController.dispose();
    _reasonController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final current = DateTime.tryParse(_startDateController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _startDateController.text = _dateLabel(picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    Navigator.pop(
      context,
      CurrentMedicine(
        id: widget.initialMedicine?.id ?? _newMedicineId(),
        name: name,
        normalizedName: Medicine.normalizeId(name),
        strength: _optionalField(_strengthController),
        dose: _optionalField(_doseController),
        frequency: _optionalField(_frequencyController),
        reason: _optionalField(_reasonController),
        startDate: DateTime.tryParse(_startDateController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialMedicine == null ? 'Add medicine' : 'Edit medicine',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FieldLabel('Medicine name'),
              MediverseTextField(
                hint: 'For example, Panadol',
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the medicine name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              FieldLabel('Strength'),
              MediverseTextField(
                hint: 'For example, 500 mg',
                controller: _strengthController,
              ),
              const SizedBox(height: 14),
              FieldLabel('Dose'),
              MediverseTextField(
                hint: 'For example, 1 tablet',
                controller: _doseController,
              ),
              const SizedBox(height: 14),
              FieldLabel('Frequency'),
              MediverseTextField(
                hint: 'For example, twice daily',
                controller: _frequencyController,
              ),
              const SizedBox(height: 14),
              FieldLabel('Reason for taking it'),
              MediverseTextField(
                hint: 'For example, for diabetes',
                controller: _reasonController,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),
              FieldLabel('Start date'),
              MediverseTextField(
                hint: 'Optional',
                controller: _startDateController,
                suffixIcon: Icons.calendar_today_outlined,
                suffixIconTooltip: 'Choose start date',
                onSuffixIconPressed: _pickStartDate,
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

  static String? _optionalField(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  static String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _MedicinesErrorState extends StatelessWidget {
  const _MedicinesErrorState({required this.message, required this.onRetry});

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
              'Could not load current medicines',
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

String _newMedicineId() => DateTime.now().microsecondsSinceEpoch.toString();
