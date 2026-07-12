import 'package:firebase_database/firebase_database.dart';

import '../../auth/services/auth_service.dart';
import '../models/chat_message.dart';

class ChatRepository {
  const ChatRepository();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<void> saveExchange({
    required String userMessage,
    required String assistantMessage,
  }) async {
    final question = userMessage.trim();
    final answer = assistantMessage.trim();
    if (question.isEmpty || answer.isEmpty) return;

    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    final ref = _db
        .child('users/${AuthService.currentUserId}/chatHistory')
        .push();
    await ref.set({
      'title': _titleFor(question),
      'preview': answer,
      'userMessage': question,
      'assistantMessage': answer,
      'messages': [
        {'text': question, 'isUser': true},
        {'text': answer, 'isUser': false},
      ],
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<List<ChatConversationSummary>> getHistory() async {
    if (!AuthService.firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return [
        ChatConversationSummary(
          id: 'demo-1',
          title: 'Vitamin C with antibiotics',
          preview:
              'Vitamin C is usually safe, but your exact antibiotic matters.',
          createdAt: DateTime.now(),
        ),
        ChatConversationSummary(
          id: 'demo-2',
          title: 'Ibuprofen after meals',
          preview: 'Taking ibuprofen with food can reduce stomach irritation.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    }

    final snapshot = await _db
        .child('users/${AuthService.currentUserId}/chatHistory')
        .orderByChild('createdAt')
        .limitToLast(30)
        .get();

    if (!snapshot.exists || snapshot.value is! Map) return const [];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final conversations = data.entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) => ChatConversationSummary.fromMap(
            entry.key,
            Map<String, dynamic>.from(entry.value as Map),
          ),
        )
        .toList();
    return conversations.reversed.toList();
  }

  String _titleFor(String question) {
    if (question.length <= 34) return question;
    return '${question.substring(0, 34).trim()}...';
  }
}
