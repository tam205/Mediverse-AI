import 'package:firebase_database/firebase_database.dart';

import 'package:mediverse_ai/features/auth/services/auth_service.dart';
import 'package:mediverse_ai/features/drug_checker/models/interaction_rule.dart';
import 'package:mediverse_ai/features/drug_checker/models/medicine.dart';

class MedicineRepository {
  const MedicineRepository();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<List<Medicine>> searchMedicines(String query) async {
    final normalized = query.trim().toLowerCase();
    final normalizedId = Medicine.normalizeId(query);

    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return _filterDemo(normalized);
    }

    try {
      final snapshot = await _db.child('medicines').get();
      if (!snapshot.exists || snapshot.value is! Map) {
        return _filterDemo(normalized);
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final medicines = data.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => Medicine.fromMap(
              entry.key,
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .toList();

      final approvedMedicines = medicines
          .where((medicine) => medicine.approved)
          .toList();
      if (approvedMedicines.isEmpty) return _filterDemo(normalized);
      if (normalized.isEmpty) return approvedMedicines;
      return approvedMedicines
          .where(
            (medicine) =>
                medicine.searchableText.contains(normalized) ||
                medicine.id == normalizedId,
          )
          .toList();
    } catch (_) {
      return _filterDemo(normalized);
    }
  }

  Future<Medicine> getMedicine(String name) async {
    final id = Medicine.normalizeId(name);

    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _demoById(id) ?? Medicine.fallback(name);
    }

    try {
      final snapshot = await _db.child('medicines/$id').get();
      if (snapshot.exists && snapshot.value is Map) {
        final medicine = Medicine.fromMap(
          id,
          Map<String, dynamic>.from(snapshot.value as Map),
        );
        if (medicine.approved) return medicine;
      }
      return _demoById(id) ?? Medicine.fallback(name);
    } catch (_) {
      return _demoById(id) ?? Medicine.fallback(name);
    }
  }

  Future<void> seedDemoMedicines() async {
    if (!AuthService.firebaseReady) return;
    final updates = <String, Object?>{};
    for (final medicine in Medicine.demo) {
      updates['medicines/${medicine.id}'] = medicine.toMap();
    }
    for (final rule in InteractionRule.demo) {
      updates['interactionRules/${rule.id}'] = rule.toMap();
    }
    await _db.update(updates);
  }

  List<Medicine> _filterDemo(String normalized) {
    if (normalized.isEmpty) return Medicine.demo;
    final normalizedId = Medicine.normalizeId(normalized);
    return Medicine.demo
        .where(
          (medicine) =>
              medicine.searchableText.contains(normalized) ||
              medicine.id == normalizedId,
        )
        .toList();
  }

  Medicine? _demoById(String id) {
    for (final medicine in Medicine.demo) {
      if (medicine.id == id) return medicine;
    }
    return null;
  }
}
