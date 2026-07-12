import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  const UserService();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<void> createUserProfile({
    required User user,
    required String name,
  }) async {
    await _db.child('users/${user.uid}').update({
      'name': name.trim(),
      'email': user.email ?? '',
      'role': 'user',
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await _db.child('users/$uid').get();
    if (!snapshot.exists || snapshot.value is! Map) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }
}
