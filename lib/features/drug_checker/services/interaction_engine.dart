import 'package:firebase_database/firebase_database.dart';
import 'package:mediverse_ai/features/auth/services/auth_service.dart';
import 'package:mediverse_ai/features/drug_checker/interaction_result.dart';
import 'package:mediverse_ai/features/drug_checker/models/interaction_rule.dart';
import 'package:mediverse_ai/features/drug_checker/models/medicine.dart';
import 'package:mediverse_ai/features/profile/models/health_profile.dart';

class InteractionEngine {
  const InteractionEngine();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<InteractionResultCopy> check(
    List<Medicine> medicines, {
    HealthProfile? profile,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final selectedIds = medicines
        .map((medicine) => medicine.id)
        .where((medicine) => medicine.isNotEmpty)
        .toSet();
    final savedCurrentMedicines = profile == null
        ? <String>{}
        : _profileMedicineIds(
            profile,
          ).where((medicine) => medicine.isNotEmpty).toSet();
    final medicinesForRisk = {...selectedIds, ...savedCurrentMedicines};
    final title = _titleForMedicines(medicines);
    final profileNotes = _profileNotes(
      selectedIds,
      profile,
      savedCurrentMedicines: savedCurrentMedicines,
    );

    final allergy = _matchingAllergy(medicinesForRisk, profile);
    if (allergy != null) {
      final severe = allergy.severity == AllergySeverity.severe;
      return InteractionResultCopy.fromStatus(
        severe ? InteractionStatus.danger : InteractionStatus.caution,
      ).copyWith(
        subtitle: title,
        details:
            '${allergy.substance} matches an allergy saved in your health profile.',
        whyRisky:
            'Recorded allergies can lead to reactions such as ${allergy.reaction.isEmpty ? 'rash, swelling, breathing difficulty, or emergency symptoms' : allergy.reaction}.',
        userAction:
            'Do not take a medicine that matches a known allergy unless a doctor or pharmacist has reviewed it.',
        professionalAdvice:
            'Contact a doctor or pharmacist before use. Seek urgent care for breathing difficulty, swelling, or severe allergic symptoms.',
        profileNotes: profileNotes,
      );
    }

    final databaseResult = await _checkRealtimeDatabase(medicinesForRisk);
    if (databaseResult != null) {
      return databaseResult.copyWith(
        subtitle: title,
        profileNotes: profileNotes,
      );
    }

    if (medicinesForRisk.contains('warfarin') &&
        medicinesForRisk.contains('aspirin')) {
      return InteractionResultCopy.fromStatus(
        InteractionStatus.danger,
      ).copyWith(subtitle: title, profileNotes: profileNotes);
    }

    if (_hasPregnancyRisk(medicinesForRisk, profile)) {
      return InteractionResultCopy.fromStatus(
        InteractionStatus.caution,
      ).copyWith(
        subtitle: title,
        details:
            'The health profile says pregnancy or breastfeeding may apply. Some selected medicines need clinician review in this situation.',
        whyRisky:
            'Medicine safety can change during pregnancy or breastfeeding, especially for blood thinners and anti-inflammatory pain medicines.',
        userAction:
            'Check with a doctor, midwife, or pharmacist before taking these medicines.',
        professionalAdvice:
            'Review pregnancy/breastfeeding status, dose, timing, and safer alternatives before use.',
        profileNotes: profileNotes,
      );
    }

    if (medicinesForRisk.contains('amlodipine') &&
        medicinesForRisk.contains('ibuprofen')) {
      return InteractionResultCopy.fromStatus(
        InteractionStatus.caution,
      ).copyWith(
        subtitle: title,
        details:
            'Ibuprofen may reduce the effectiveness of Amlodipine or increase kidney and blood-pressure monitoring needs.',
        profileNotes: profileNotes,
      );
    }

    final conditionRisk = _conditionRisk(medicinesForRisk, profile);
    if (conditionRisk != null) {
      return InteractionResultCopy.fromStatus(
        InteractionStatus.caution,
      ).copyWith(
        subtitle: title,
        details: conditionRisk.details,
        whyRisky: conditionRisk.whyRisky,
        userAction:
            'Use only as directed and ask a pharmacist if symptoms worsen or repeated doses are needed.',
        professionalAdvice:
            'Review the patient conditions and current treatment plan before recommending repeated use.',
        profileNotes: profileNotes,
      );
    }

    return InteractionResultCopy.fromStatus(InteractionStatus.safe).copyWith(
      subtitle: title,
      body:
          'No known interaction was found in the current reviewed database. This does not guarantee that the combination is safe for every person.',
      details:
          'No known interaction was found in the current reviewed database. This does not guarantee that the combination is safe for every person.',
      profileNotes: profileNotes,
    );
  }

  Future<InteractionResultCopy?> _checkRealtimeDatabase(
    Set<String> medicines,
  ) async {
    if (medicines.length < 2) return null;
    if (!AuthService.firebaseReady) return _checkDemoRules(medicines);

    final list = medicines.toList();
    InteractionResultCopy? strongest;
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final key = _interactionKey(list[i], list[j]);
        final snapshot = await _loadRuleSnapshot(key);
        if (!snapshot.exists || snapshot.value is! Map) continue;
        final rule = InteractionRule.fromMap(
          key,
          Map<String, dynamic>.from(snapshot.value as Map),
        );
        if (!rule.approved) continue;
        final result = _copyFromRule(rule);
        if (strongest == null || _rank(result.risk) > _rank(strongest.risk)) {
          strongest = result;
        }
      }
    }
    return strongest;
  }

  InteractionResultCopy? _checkDemoRules(Set<String> medicines) {
    InteractionResultCopy? strongest;
    final list = medicines.toList();
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final key = _interactionKey(list[i], list[j]);
        final matchingRules = InteractionRule.demo.where(
          (rule) => rule.id == key && rule.approved,
        );
        for (final rule in matchingRules) {
          final result = _copyFromRule(rule);
          if (strongest == null || _rank(result.risk) > _rank(strongest.risk)) {
            strongest = result;
          }
        }
      }
    }
    return strongest;
  }

  Future<DataSnapshot> _loadRuleSnapshot(String key) async {
    final reviewed = await _db.child('interactionRules/$key').get();
    if (reviewed.exists) return reviewed;
    return _db.child('interactions/$key').get();
  }

  InteractionResultCopy _copyFromRule(InteractionRule rule) {
    final severity = rule.severity.toLowerCase();
    final status = switch (severity) {
      'contraindicated' ||
      'major' ||
      'high' ||
      'danger' ||
      'severe' => InteractionStatus.danger,
      'moderate' ||
      'minor' ||
      'medium' ||
      'caution' => InteractionStatus.caution,
      _ => InteractionStatus.safe,
    };
    final base = InteractionResultCopy.fromStatus(status);

    return base.copyWith(
      subtitle:
          '${_displayName(rule.medicineAId)} + ${_displayName(rule.medicineBId)}',
      body: rule.explanation,
      details: rule.explanation,
      whyRisky: rule.explanation,
      userAction: rule.recommendedAction,
      professionalAdvice:
          'Confirm this result with a doctor or pharmacist, especially if symptoms are severe or either medicine is prescribed.',
      severity: rule.severity,
      evidenceSource: '${rule.evidenceSource} (version ${rule.version})',
    );
  }

  Allergy? _matchingAllergy(Set<String> medicines, HealthProfile? profile) {
    if (profile == null) return null;
    final allergies = profile.allergyEntries.isNotEmpty
        ? profile.allergyEntries
        : profile.allergies
              .map(
                (substance) => Allergy(
                  id: 'legacy-${Medicine.normalizeId(substance)}',
                  substance: substance,
                  reaction: profile.allergyReaction,
                  severity: AllergySeverity.fromStoredValue(
                    profile.allergySeverity,
                  ),
                ),
              )
              .toList();

    for (final allergy in allergies) {
      final allergen = Medicine.normalizeId(allergy.substance);
      if (allergen.isEmpty) continue;
      final matches = medicines.any(
        (medicine) =>
            medicine.contains(allergen) || allergen.contains(medicine),
      );
      if (matches) return allergy;
    }
    return null;
  }

  bool _hasPregnancyRisk(Set<String> medicines, HealthProfile? profile) {
    if (profile == null) return false;
    final status = profile.pregnancyBreastfeeding.toLowerCase();
    final applies =
        !status.contains('not applicable') &&
        !status.contains('none') &&
        !status.contains('no');
    if (!applies) return false;
    return medicines.any(
      (medicine) =>
          medicine.contains('warfarin') ||
          medicine.contains('ibuprofen') ||
          medicine.contains('aspirin'),
    );
  }

  _ProfileConditionRisk? _conditionRisk(
    Set<String> medicines,
    HealthProfile? profile,
  ) {
    if (profile == null) return null;
    if (profile.hasHypertension &&
        _hasAny(medicines, {'ibuprofen', 'aspirin'})) {
      return const _ProfileConditionRisk(
        details:
            'Your profile includes hypertension. Some anti-inflammatory pain medicines may affect blood pressure control or kidney function.',
        whyRisky:
            'Hypertension can make repeated NSAID use less suitable without monitoring.',
      );
    }
    if (profile.hasAsthma && _hasAny(medicines, {'aspirin', 'ibuprofen'})) {
      return const _ProfileConditionRisk(
        details:
            'Your profile includes asthma. Aspirin or anti-inflammatory pain medicines can worsen breathing symptoms for some people.',
        whyRisky:
            'Some people with asthma are sensitive to NSAIDs and may need safer alternatives.',
      );
    }
    if (profile.hasDiabetes &&
        _hasAny(medicines, {'prednisone', 'prednisolone', 'dexamethasone'})) {
      return const _ProfileConditionRisk(
        details:
            'Your profile includes diabetes. Steroid medicines may affect blood sugar control.',
        whyRisky:
            'Diabetes can require closer monitoring when medicines raise blood sugar.',
      );
    }

    final conditions = profile.otherChronicDiseases
        .map((condition) => condition.toLowerCase())
        .join(' ');
    if (conditions.contains('kidney') &&
        _hasAny(medicines, {'ibuprofen', 'aspirin'})) {
      return const _ProfileConditionRisk(
        details:
            'Your profile mentions a kidney condition. Some pain medicines may require extra caution.',
        whyRisky:
            'Kidney disease can increase the risk from repeated NSAID use.',
      );
    }
    if (conditions.contains('liver') && medicines.contains('paracetamol')) {
      return const _ProfileConditionRisk(
        details:
            'Your profile mentions a liver condition. Paracetamol dosing may need professional guidance.',
        whyRisky:
            'Liver disease can change how safely paracetamol is processed.',
      );
    }
    if ((conditions.contains('ulcer') || conditions.contains('bleeding')) &&
        _hasAny(medicines, {'ibuprofen', 'aspirin', 'warfarin'})) {
      return const _ProfileConditionRisk(
        details:
            'Your profile mentions ulcer or bleeding risk. These medicines may increase bleeding concerns.',
        whyRisky:
            'Bleeding history can make blood thinners and some pain medicines higher risk.',
      );
    }
    return null;
  }

  String _profileNotes(
    Set<String> medicines,
    HealthProfile? profile, {
    required Set<String> savedCurrentMedicines,
  }) {
    if (profile == null) {
      return 'No health profile was included in this check.';
    }
    final notes = [
      'Known allergies: ${profile.allergies.length}',
      'Current medicines checked: ${profile.currentMedicines.length}',
      'Conditions: ${profile.chronicDiseases.isEmpty ? 'None recorded' : profile.chronicDiseases.join(', ')}',
    ];
    if (medicines.any(savedCurrentMedicines.contains)) {
      notes.add(
        'Current medicine consideration: ${_profileMedicineNames(profile, savedCurrentMedicines).join(', ')} were included automatically in this safety check.',
      );
    } else if (savedCurrentMedicines.isNotEmpty) {
      notes.add(
        'Saved current medicines were also considered for interaction risks.',
      );
    }
    return notes.join('\n');
  }

  bool _hasAny(Set<String> medicines, Set<String> targets) {
    return targets.any(medicines.contains);
  }

  Iterable<String> _profileMedicineIds(HealthProfile profile) {
    if (profile.currentMedicineEntries.isNotEmpty) {
      return profile.currentMedicineEntries.map(
        (medicine) => medicine.normalized,
      );
    }
    return profile.currentMedicines.map(Medicine.normalizeId);
  }

  List<String> _profileMedicineNames(
    HealthProfile profile,
    Set<String> includedIds,
  ) {
    if (profile.currentMedicineEntries.isNotEmpty) {
      return profile.currentMedicineEntries
          .where((medicine) => includedIds.contains(medicine.normalized))
          .map((medicine) => medicine.name)
          .toList();
    }
    return profile.currentMedicines
        .where((name) => includedIds.contains(Medicine.normalizeId(name)))
        .toList();
  }

  String _interactionKey(String drugA, String drugB) {
    final drugs = [drugA, drugB]..sort();
    return '${drugs[0]}_${drugs[1]}';
  }

  int _rank(String risk) {
    return switch (risk.toLowerCase()) {
      'danger' || 'high-risk warning' => 3,
      'caution' || 'caution advised' => 2,
      _ => 1,
    };
  }

  String _titleForMedicines(List<Medicine> medicines) {
    if (medicines.isEmpty) return 'No medicines selected';
    return medicines.map((medicine) => medicine.genericName).join(' + ');
  }

  String _displayName(String value) {
    if (value.isEmpty) return value;
    return value
        .replaceAll('-', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _ProfileConditionRisk {
  const _ProfileConditionRisk({required this.details, required this.whyRisky});

  final String details;
  final String whyRisky;
}
