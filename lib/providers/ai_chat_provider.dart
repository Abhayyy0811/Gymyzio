import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_chat_service.dart';

enum ChatSender { user, ai }

class ChatMessage {
  final String id;
  final String text;
  final ChatSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool hasUnread;

  AiChatState({
    required this.messages,
    this.isLoading = false,
    this.hasUnread = false,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? hasUnread,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasUnread: hasUnread ?? this.hasUnread,
    );
  }
}

final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService();
});

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiChatService _chatService;

  AiChatNotifier(this._chatService)
      : super(
          AiChatState(
            messages: [
              ChatMessage(
                id: 'welcome_msg',
                text:
                    "Hi! I'm FitGenie AI 💪 Ask me about exercise form, workout tips, or motivation!",
                sender: ChatSender.ai,
                timestamp: DateTime.now(),
              ),
            ],
            isLoading: false,
            hasUnread: false,
          ),
        );

  void markAsRead() {
    if (state.hasUnread) {
      state = state.copyWith(hasUnread: false);
    }
  }

  Future<void> sendMessage(String text, {bool isPanelOpen = true}) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmedText,
      sender: ChatSender.user,
      timestamp: DateTime.now(),
    );

    // Optimistically add user message and set loading
    final updatedMessages = [...state.messages, userMsg];
    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
    );

    // Prepare message history for Groq API
    final apiHistory = updatedMessages.map((msg) {
      return AiChatMessage(
        role: msg.sender == ChatSender.user ? 'user' : 'assistant',
        content: msg.text,
      );
    }).toList();

    // Get response from Groq AI Service
    final aiResponseText = await _chatService.sendMessage(apiHistory);

    final aiMsg = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: aiResponseText,
      sender: ChatSender.ai,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
      hasUnread: !isPanelOpen,
    );
  }

  void clearChat() {
    state = AiChatState(
      messages: [
        ChatMessage(
          id: 'welcome_msg_${DateTime.now().millisecondsSinceEpoch}',
          text:
              "Hi! I'm FitGenie AI 💪 Ask me about exercise form, workout tips, or motivation!",
          sender: ChatSender.ai,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
      hasUnread: false,
    );
  }
}

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final service = ref.watch(aiChatServiceProvider);
  return AiChatNotifier(service);
});
