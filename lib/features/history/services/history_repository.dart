import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../auth/services/auth_service.dart';
import '../../drug_checker/interaction_result.dart';
import '../models/history_record.dart';

class HistoryRepository {
  const HistoryRepository();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<List<HistoryRecord>> getHistory() async {
    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return HistoryRecord.demo;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final path = 'users/${user.uid}/history';
    debugPrint('Loading history for ${user.uid}');
    debugPrint('Database path: $path');

    try {
      final snapshot = await _db
          .child(path)
          .orderByChild('createdAt')
          .limitToLast(50)
          .get()
          .timeout(const Duration(seconds: 12));

      debugPrint('History exists: ${snapshot.exists}');
      debugPrint('History value: ${snapshot.value}');

      if (!snapshot.exists || snapshot.value == null) return const [];
      final raw = snapshot.value;
      if (raw is! Map) {
        throw const FormatException('History data has an invalid format.');
      }

      final records = <HistoryRecord>[];
      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        records.add(
          HistoryRecord.fromMap(
            entry.key.toString(),
            Map<String, dynamic>.from(entry.value as Map),
          ),
        );
      }
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (error, stackTrace) {
      debugPrint('getHistory error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> saveInteraction(
    InteractionResultCopy result, {
    List<String>? medicines,
    bool profileIncluded = false,
  }) async {
    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final checkedMedicines =
        medicines?.where((value) => value.trim().isNotEmpty).toList() ??
        result.subtitle.split('+').map((value) => value.trim()).toList();
    try {
      final ref = _db.child('users/${user.uid}/history').push();
      await ref
          .set({
            'title': result.subtitle,
            'medicines': checkedMedicines,
            'drugA': checkedMedicines.isNotEmpty ? checkedMedicines.first : '',
            'drugB': checkedMedicines.length > 1 ? checkedMedicines[1] : '',
            'status': result.risk,
            'result': result.risk.toLowerCase(),
            'severity': result.severity,
            'riskLevel': result.risk.toLowerCase(),
            'summary': result.details,
            'message': result.details,
            'evidenceSource': result.evidenceSource,
            'profileIncluded': profileIncluded,
            'profileNotes': result.profileNotes,
            'type': 'interaction',
            'createdAt': ServerValue.timestamp,
          })
          .timeout(const Duration(seconds: 12));
    } catch (error, stackTrace) {
      debugPrint('saveInteraction error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
