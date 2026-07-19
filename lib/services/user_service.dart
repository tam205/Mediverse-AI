import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  const UserService();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<void> createUserProfile({
    required User user,
    required String name,
  }) async {
    await _db.child('users/${user.uid}/account').set({
      'fullName': name.trim(),
      'email': (user.email ?? '').trim().toLowerCase(),
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
      'profileCompleted': false,
    });
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await _db.child('users/$uid').get();
    if (!snapshot.exists || snapshot.value is! Map) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Stream<bool> watchProfileCompleted() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream<bool>.value(false);

    return _db.child('users/$uid/account/profileCompleted').onValue.map((
      event,
    ) {
      return event.snapshot.value == true;
    });
  }

  Future<void> markProfileCompleted() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db.child('users/$uid/account').update({
      'profileCompleted': true,
      'updatedAt': ServerValue.timestamp,
    });
  }
}
