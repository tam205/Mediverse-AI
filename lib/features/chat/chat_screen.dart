import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/form_fields.dart';
import 'models/chat_message.dart';
import 'services/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repository = const ChatRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[
    ChatMessage(
      id: 'welcome',
      text:
          'Hello! Ask a medicine safety or health learning question. I can help you prepare better questions for a doctor or pharmacist.',
      isUser: false,
      createdAt: DateTime.now(),
    ),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _messageController.text).trim();
    if (text.isEmpty || _sending) return;

    _messageController.clear();
    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
    );
    setState(() {
      _sending = true;
      _messages.add(userMessage);
    });
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 500));
    final reply = _replyFor(text);
    final assistantMessage = ChatMessage(
      id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
      text: reply,
      isUser: false,
      createdAt: DateTime.now(),
    );

    await _repository.saveExchange(userMessage: text, assistantMessage: reply);

    if (!mounted) return;
    setState(() {
      _messages.add(assistantMessage);
      _sending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _replyFor(String question) {
    final lower = question.toLowerCase();
    if (lower.contains('urgent') ||
        lower.contains('emergency') ||
        lower.contains('danger')) {
      return 'Seek urgent medical care for severe breathing problems, chest pain, fainting, heavy bleeding, swelling of the face, or overdose symptoms. This app does not replace emergency care.';
    }
    if (lower.contains('food') || lower.contains('meal')) {
      return 'Some medicines are better with food to reduce stomach irritation, while others need an empty stomach. Check the exact medicine label or ask a pharmacist.';
    }
    if (lower.contains('antibiotic') || lower.contains('vitamin c')) {
      return 'Vitamin C is generally safe with many antibiotics, but the exact antibiotic matters. Share the medicine name so a pharmacist can confirm timing and interactions.';
    }
    if (lower.contains('pharmacist') || lower.contains('doctor')) {
      return 'Good questions include: What is this medicine for? How should I take it? What side effects need help? Can it interact with my current medicines or allergies?';
    }
    return 'I can help with general medicine safety education. Please confirm important decisions with a doctor or pharmacist, especially for pregnancy, children, chronic disease, allergies, or severe symptoms.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediverseAppBar(
        title: 'AI Health Assistant',
        actions: [
          IconButton(
            tooltip: 'Conversation history',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => ConversationHistorySheet(repository: _repository),
            ),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(18),
                children: [
                  SuggestedQuestions(onSelected: _send),
                  const SizedBox(height: 16),
                  const _DisclaimerCard(),
                  const SizedBox(height: 16),
                  ..._messages.map(
                    (message) =>
                        ChatBubble(text: message.text, isUser: message.isUser),
                  ),
                  if (_sending) const _TypingIndicator(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: MediverseTextField(
                      hint: 'Type your message...',
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.ocean,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _sending ? null : () => _send(),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestedQuestions extends StatelessWidget {
  const SuggestedQuestions({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final questions = [
      'Can I take this with food?',
      'What should I ask my pharmacist?',
      'What symptoms need urgent care?',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested questions',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions
                .map(
                  (question) => ActionChip(
                    label: Text(question),
                    onPressed: () => onSelected(question),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class ConversationHistorySheet extends StatelessWidget {
  const ConversationHistorySheet({super.key, required this.repository});

  final ChatRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChatConversationSummary>>(
      future: repository.getHistory(),
      builder: (context, snapshot) {
        final conversations = snapshot.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            const Text(
              'Conversation History',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (conversations == null)
              const Center(child: CircularProgressIndicator())
            else if (conversations.isEmpty)
              const AppCard(
                child: Text(
                  'No AI chat history yet. Ask a question to save your first conversation.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...conversations.map(
                (conversation) => ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(conversation.title),
                  subtitle: Text(
                    '${conversation.preview}\n${conversation.dateLabel}',
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.ocean),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Educational support only. Mediverse AI does not replace doctors, pharmacists, diagnosis, or emergency care.',
              style: TextStyle(
                color: AppColors.muted,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: AppCard(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            'Assistant is preparing a safety answer...',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .76,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.ocean : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.ink,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
