import 'package:firebase_database/firebase_database.dart';

import 'package:mediverse_ai/features/auth/services/auth_service.dart';
import 'package:mediverse_ai/features/drug_checker/models/medicine.dart';

class MedicineRepository {
  const MedicineRepository();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<List<Medicine>> searchMedicines(String query) async {
    final normalized = query.trim().toLowerCase();

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

      if (medicines.isEmpty) return _filterDemo(normalized);
      if (normalized.isEmpty) return medicines;
      return medicines
          .where((medicine) => medicine.name.toLowerCase().contains(normalized))
          .toList();
    } catch (_) {
      return _filterDemo(normalized);
    }
  }

  Future<Medicine> getMedicine(String name) async {
    final id = _idFor(name);

    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _demoById(id) ?? Medicine.fallback(name);
    }

    try {
      final snapshot = await _db.child('medicines/$id').get();
      if (snapshot.exists && snapshot.value is Map) {
        return Medicine.fromMap(
          id,
          Map<String, dynamic>.from(snapshot.value as Map),
        );
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
    await _db.update(updates);
  }

  List<Medicine> _filterDemo(String normalized) {
    if (normalized.isEmpty) return Medicine.demo;
    return Medicine.demo
        .where((medicine) => medicine.name.toLowerCase().contains(normalized))
        .toList();
  }

  Medicine? _demoById(String id) {
    for (final medicine in Medicine.demo) {
      if (medicine.id == id) return medicine;
    }
    return null;
  }

  String _idFor(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }
}
