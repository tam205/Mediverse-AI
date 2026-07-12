import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class InteractionService {
  const InteractionService();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  String createInteractionKey(String drugA, String drugB) {
    final drugs = [_normalize(drugA), _normalize(drugB)]..sort();
    return '${drugs[0]}_${drugs[1]}';
  }

  Future<Map<String, dynamic>?> checkInteraction({
    required String drugA,
    required String drugB,
  }) async {
    final key = createInteractionKey(drugA, drugB);
    final snapshot = await _db.child('interactions/$key').get();
    if (!snapshot.exists || snapshot.value is! Map) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future<void> saveCheckHistory({
    required String drugA,
    required String drugB,
    required String result,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _db.child('users/${user.uid}/history').push();
    await ref.set({
      'drugA': drugA.trim(),
      'drugB': drugB.trim(),
      'result': result,
      'message': message,
      'createdAt': ServerValue.timestamp,
    });
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }
}
