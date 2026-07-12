import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../auth/services/auth_service.dart';
import '../models/health_profile.dart';

class HealthProfileRepository {
  const HealthProfileRepository();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  DatabaseReference _profileReference() {
    if (!AuthService.firebaseReady) {
      throw StateError('Firebase is not configured.');
    }
    return _db.child('users/${AuthService.currentUserId}/profile/health');
  }

  Future<HealthProfile> getProfile() async {
    final fallback = HealthProfile.demoForUser(
      name: AuthService.currentUserName,
      email: AuthService.currentUserEmail,
    );

    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return fallback;
    }

    final path = 'users/${AuthService.currentUserId}/profile/health';
    debugPrint('Loading health profile...');
    debugPrint('UID: ${AuthService.currentUserId}');
    debugPrint('Database path: $path');

    try {
      final snapshot = await _profileReference().get().timeout(
        const Duration(seconds: 12),
      );

      debugPrint('Profile exists: ${snapshot.exists}');
      debugPrint('Profile value: ${snapshot.value}');

      if (!snapshot.exists || snapshot.value is! Map) {
        return HealthProfile.empty.copyWith(
          name: AuthService.currentUserName,
          email: AuthService.currentUserEmail,
        );
      }

      return HealthProfile.fromMap(
        Map<String, dynamic>.from(snapshot.value as Map),
      ).copyWith(
        name: AuthService.currentUserName,
        email: AuthService.currentUserEmail,
      );
    } catch (error, stackTrace) {
      debugPrint('getProfile error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> saveProfile(HealthProfile profile) async {
    final updatedProfile = profile.copyWith(
      name: AuthService.currentUserName,
      email: AuthService.currentUserEmail,
      lastUpdated: DateTime.now(),
    );

    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return;
    }

    try {
      await _profileReference()
          .set(updatedProfile.toMap())
          .timeout(const Duration(seconds: 12));
    } catch (error, stackTrace) {
      debugPrint('saveProfile error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, Object?> updates) async {
    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return;
    }

    try {
      await _profileReference()
          .update(updates)
          .timeout(const Duration(seconds: 12));
    } catch (error, stackTrace) {
      debugPrint('updateProfile error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<HealthProfile> watchProfile() {
    if (!AuthService.firebaseReady) {
      return Stream<HealthProfile>.value(
        HealthProfile.demoForUser(
          name: AuthService.currentUserName,
          email: AuthService.currentUserEmail,
        ),
      );
    }

    return _profileReference().onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) {
        return HealthProfile.empty.copyWith(
          name: AuthService.currentUserName,
          email: AuthService.currentUserEmail,
        );
      }

      return HealthProfile.fromMap(
        Map<String, dynamic>.from(event.snapshot.value as Map),
      ).copyWith(
        name: AuthService.currentUserName,
        email: AuthService.currentUserEmail,
      );
    });
  }
}
