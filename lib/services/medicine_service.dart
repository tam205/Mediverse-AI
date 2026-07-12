import 'package:firebase_database/firebase_database.dart';

class MedicineService {
  const MedicineService();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<Map<String, dynamic>> getAllMedicines() async {
    final snapshot = await _db.child('medicines').get();
    if (!snapshot.exists || snapshot.value is! Map) return const {};
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future<Map<String, dynamic>?> searchMedicine(String medicineKey) async {
    final snapshot = await _db.child('medicines/$medicineKey').get();
    if (!snapshot.exists || snapshot.value is! Map) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future<void> seedDemoMedicines(
    List<MapEntry<String, Map<String, dynamic>>> medicines,
  ) async {
    final updates = <String, Object?>{};
    for (final medicine in medicines) {
      updates['medicines/${medicine.key}'] = medicine.value;
    }
    await _db.update(updates);
  }
}
