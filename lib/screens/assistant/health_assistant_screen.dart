import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/risk_predictor.dart';
import '../../models/health_assistant_message.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/disclaimer_banner.dart';

class HealthAssistantScreen extends ConsumerStatefulWidget {
  const HealthAssistantScreen({super.key});

  @override
  ConsumerState<HealthAssistantScreen> createState() =>
      _HealthAssistantScreenState();
}

class _HealthAssistantScreenState
    extends ConsumerState<HealthAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _predictor = RiskPredictor();
  final List<HealthAssistantMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestedQuestions = [
    'What is diabetes?',
    'What foods are recommended?',
    'What foods should be limited?',
    'How does exercise affect blood sugar?',
    'What is HbA1c?',
    'What are the symptoms?',
    'How can I prevent diabetes?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(HealthAssistantMessage(
        userId: ref.read(authProvider).user?.id ?? 0,
        message: text.trim(),
        sender: MessageSender.user,
      ));
      _isTyping = true;
    });

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 500), () {
      final response = _predictor.getAnswer(text);
      setState(() {
        _messages.add(HealthAssistantMessage(
          userId: ref.read(authProvider).user?.id ?? 0,
          message: response,
          sender: MessageSender.assistant,
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
      ),
      body: Column(
        children: [
          const DisclaimerBanner(
            text: 'I am an educational AI assistant. I cannot diagnose or '
                'provide medical treatment recommendations. Always consult a '
                'healthcare professional.',
          ),
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : _buildMessages(),
          ),
          if (_messages.isEmpty) _buildSuggestedQuestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask me anything about diabetes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'I can help with diet, exercise, blood sugar management, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                _suggestedQuestions[index],
                style: const TextStyle(fontSize: 13),
              ),
              onPressed: () => _sendMessage(_suggestedQuestions[index]),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              side: BorderSide(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(HealthAssistantMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryColor
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Text(
          message.message,
          style: TextStyle(
            fontSize: 15,
            color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: const TextStyle(fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }
}
