import 'package:firebase_database/firebase_database.dart';

import '../../auth/services/auth_service.dart';
import '../models/medication_reminder.dart';

class ReminderRepository {
  const ReminderRepository();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<List<MedicationReminder>> getReminders() async {
    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return MedicationReminder.demo;
    }

    final snapshot = await _db
        .child('users/${AuthService.currentUserId}/reminders')
        .orderByChild('time')
        .get();

    if (!snapshot.exists || snapshot.value is! Map) {
      return MedicationReminder.demo;
    }
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final reminders = data.entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) => MedicationReminder.fromMap(
            entry.key,
            Map<String, dynamic>.from(entry.value as Map),
          ),
        )
        .toList();
    if (reminders.isEmpty) return MedicationReminder.demo;
    reminders.sort((a, b) => a.time.compareTo(b.time));
    return reminders;
  }

  Future<void> saveReminder(MedicationReminder reminder) async {
    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    await _db
        .child('users/${AuthService.currentUserId}/reminders/${reminder.id}')
        .update(reminder.toMap());
  }
}
