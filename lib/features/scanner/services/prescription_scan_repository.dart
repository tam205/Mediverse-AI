import 'package:firebase_database/firebase_database.dart';

import '../../auth/services/auth_service.dart';
import '../models/prescription_scan.dart';

class PrescriptionScanRepository {
  const PrescriptionScanRepository();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<void> saveScan({
    required String prescriptionText,
    required List<String> detectedMedicines,
  }) async {
    final cleanMedicines = detectedMedicines
        .map((medicine) => medicine.trim())
        .where((medicine) => medicine.isNotEmpty)
        .toList();

    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    final ref = _db.child('users/${AuthService.currentUserId}/scans').push();
    await ref.set({
      'prescriptionText': prescriptionText.trim(),
      'detectedMedicines': cleanMedicines,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<List<PrescriptionScan>> getScans() async {
    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return [
        PrescriptionScan(
          id: 'sample-scan',
          prescriptionText: PrescriptionScan.sampleText,
          detectedMedicines: PrescriptionScan.sampleMedicines,
          createdAt: DateTime.now(),
        ),
      ];
    }

    final snapshot = await _db
        .child('users/${AuthService.currentUserId}/scans')
        .orderByChild('createdAt')
        .limitToLast(30)
        .get();

    if (!snapshot.exists || snapshot.value is! Map) return const [];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final scans = data.entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) => PrescriptionScan.fromMap(
            entry.key,
            Map<String, dynamic>.from(entry.value as Map),
          ),
        )
        .toList();
    return scans.reversed.toList();
  }
}
