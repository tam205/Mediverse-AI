import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/utils/firebase_error_messages.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import 'models/health_profile.dart';
import 'services/health_profile_repository.dart';

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final _repository = const HealthProfileRepository();
  late Future<HealthProfile> _profileFuture;

  HealthProfile? _profile;
  List<Allergy> _allergies = const [];
  bool _noKnownAllergies = false;
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
    _allergies = _initialAllergies(profile);
    _noKnownAllergies = profile.allergiesReviewed && _allergies.isEmpty;
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

    if (!_noKnownAllergies && _allergies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add an allergy or choose no known allergies.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final savedAllergies = _noKnownAllergies ? <Allergy>[] : _allergies;
      await _repository.saveProfile(
        profile.copyWith(
          allergyEntries: savedAllergies,
          medicineAllergies: savedAllergies
              .map((allergy) => allergy.substance.trim())
              .where((substance) => substance.isNotEmpty)
              .toList(),
          allergiesReviewed: true,
          lastUpdated: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _profile = profile.copyWith(
          allergyEntries: savedAllergies,
          medicineAllergies: savedAllergies
              .map((allergy) => allergy.substance.trim())
              .toList(),
          allergiesReviewed: true,
          lastUpdated: DateTime.now(),
        );
        _allergies = savedAllergies;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allergies updated successfully.')),
      );
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Allergy save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyDatabaseMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addAllergy() async {
    final allergy = await showDialog<Allergy>(
      context: context,
      builder: (_) => const _AllergyDialog(),
    );
    if (!mounted || allergy == null) return;
    if (_containsAllergy(allergy.substance)) {
      _showDuplicateMessage();
      return;
    }
    setState(() {
      _allergies = [..._allergies, allergy];
      _noKnownAllergies = false;
      _dirty = true;
    });
  }

  Future<void> _editAllergy(int index) async {
    final allergy = await showDialog<Allergy>(
      context: context,
      builder: (_) => _AllergyDialog(initialAllergy: _allergies[index]),
    );
    if (!mounted || allergy == null) return;
    if (_containsAllergy(allergy.substance, excludingIndex: index)) {
      _showDuplicateMessage();
      return;
    }
    setState(() {
      _allergies = [..._allergies]..[index] = allergy;
      _dirty = true;
    });
  }

  Future<void> _removeAllergy(int index) async {
    final allergy = _allergies[index];
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove allergy?'),
        content: Text(
          '${allergy.substance} will be removed from your profile.',
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
      _allergies = [..._allergies]..removeAt(index);
      _dirty = true;
    });
  }

  void _toggleNoKnownAllergies(bool value) {
    setState(() {
      _noKnownAllergies = value;
      if (value) _allergies = const [];
      _dirty = true;
    });
  }

  bool _containsAllergy(String substance, {int? excludingIndex}) {
    final normalized = substance.trim().toLowerCase();
    return _allergies.asMap().entries.any((entry) {
      if (entry.key == excludingIndex) return false;
      return entry.value.substance.trim().toLowerCase() == normalized;
    });
  }

  void _showDuplicateMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This allergy is already recorded.')),
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
        appBar: const MediverseAppBar(title: 'Allergies'),
        body: FutureBuilder<HealthProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _AllergiesErrorState(
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
                      Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.ocean,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Record allergies that may affect medicine safety checks.',
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
                    value: _noKnownAllergies,
                    onChanged: _saving ? null : _toggleNoKnownAllergies,
                    title: const Text(
                      'I have no known medicine allergies',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Choose this only after reviewing your allergies.',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_allergies.isEmpty)
                  _AllergyEmptyState(
                    noKnownAllergies: _noKnownAllergies,
                    onAdd: _saving ? null : _addAllergy,
                  )
                else
                  ..._allergies.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AllergyCard(
                        allergy: entry.value,
                        onEdit: _saving ? null : () => _editAllergy(entry.key),
                        onRemove: _saving
                            ? null
                            : () => _removeAllergy(entry.key),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _addAllergy,
                  icon: const Icon(Icons.add),
                  label: const Text('Add allergy'),
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

  static List<Allergy> _initialAllergies(HealthProfile profile) {
    if (profile.allergyEntries.isNotEmpty) return [...profile.allergyEntries];
    return profile.medicineAllergies
        .map(
          (substance) => Allergy(
            id: _newAllergyId(),
            substance: substance,
            reaction: profile.allergyReaction,
            severity: AllergySeverity.fromStoredValue(profile.allergySeverity),
          ),
        )
        .where((allergy) => allergy.substance.trim().isNotEmpty)
        .toList();
  }
}

class _AllergyCard extends StatelessWidget {
  const _AllergyCard({
    required this.allergy,
    required this.onEdit,
    required this.onRemove,
  });

  final Allergy allergy;
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
              const Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.ocean,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allergy.substance,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      allergy.reaction,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Severity: ${allergy.severity.label}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

class _AllergyEmptyState extends StatelessWidget {
  const _AllergyEmptyState({
    required this.noKnownAllergies,
    required this.onAdd,
  });

  final bool noKnownAllergies;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (noKnownAllergies) {
      return const AppCard(
        child: Text(
          'No known medicine allergies saved.',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No allergies added',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add known medicine or food allergies to improve safety checks.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add allergy'),
          ),
        ],
      ),
    );
  }
}

class _AllergyDialog extends StatefulWidget {
  const _AllergyDialog({this.initialAllergy});

  final Allergy? initialAllergy;

  @override
  State<_AllergyDialog> createState() => _AllergyDialogState();
}

class _AllergyDialogState extends State<_AllergyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _substanceController;
  late final TextEditingController _reactionController;
  late AllergySeverity _severity;

  @override
  void initState() {
    super.initState();
    final allergy = widget.initialAllergy;
    _substanceController = TextEditingController(text: allergy?.substance);
    _reactionController = TextEditingController(text: allergy?.reaction);
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
              FieldLabel('Substance'),
              MediverseTextField(
                hint: 'For example, penicillin',
                controller: _substanceController,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the medicine or substance.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              FieldLabel('Reaction'),
              MediverseTextField(
                hint: 'For example, skin rash',
                controller: _reactionController,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Describe the reaction.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AllergySeverity>(
                initialValue: _severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: AllergySeverity.values
                    .map(
                      (severity) => DropdownMenuItem(
                        value: severity,
                        child: Text(severity.label),
                      ),
                    )
                    .toList(),
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

class _AllergiesErrorState extends StatelessWidget {
  const _AllergiesErrorState({required this.message, required this.onRetry});

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
              'Could not load allergies',
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

String _newAllergyId() => DateTime.now().microsecondsSinceEpoch.toString();
