class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      text: map['text'] as String? ?? '',
      isUser: map['isUser'] as bool? ?? false,
      createdAt: _dateFrom(map['createdAt']),
    );
  }
}

class ChatConversationSummary {
  const ChatConversationSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime createdAt;

  factory ChatConversationSummary.fromMap(String id, Map<String, dynamic> map) {
    return ChatConversationSummary(
      id: id,
      title: map['title'] as String? ?? 'AI health chat',
      preview: map['preview'] as String? ?? '',
      createdAt: _dateFrom(map['createdAt']),
    );
  }

  String get dateLabel {
    final now = DateTime.now();
    if (createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day) {
      return 'Today';
    }
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

DateTime _dateFrom(Object? value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
