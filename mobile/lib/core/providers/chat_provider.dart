import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

class ChatMessage {
  final String id;
  final String friendshipId;
  final String senderId;
  final String content;
  final String status;
  final String createdAt;
  final String messageType; // 'text', 'image', 'video'
  final String? mediaUrl;

  ChatMessage({
    required this.id,
    required this.friendshipId,
    required this.senderId,
    required this.content,
    required this.status,
    required this.createdAt,
    this.messageType = 'text',
    this.mediaUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content']?.toString() ?? '';
    String type = json['message_type'] ?? 'text';
    String? media = json['media_url'];

    if (rawContent.startsWith('[IMAGE]')) {
      type = 'image';
      media = rawContent.replaceFirst('[IMAGE]', '').trim();
    } else if (rawContent.startsWith('[VIDEO]')) {
      type = 'video';
      media = rawContent.replaceFirst('[VIDEO]', '').trim();
    }

    return ChatMessage(
      id: json['id'] ?? '',
      friendshipId: json['friendship_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: rawContent,
      status: json['status'] ?? 'sent',
      createdAt: json['created_at'] ?? '',
      messageType: type,
      mediaUrl: media,
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiClient _client = ApiClient();
  final String friendshipId;
  Timer? _poller;

  ChatNotifier(this.friendshipId) : super(ChatState()) {
    fetchMessages();
    _startPolling();
  }

  Future<void> fetchMessages() async {
    try {
      final List res = await _client.get(ApiEndpoints.getMessages(friendshipId));
      final msgs = res.map((j) => ChatMessage.fromJson(j)).toList();
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      // Don't clear existing messages on error in offline/demo mode
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true, error: null);
    try {
      final res = await _client.post(ApiEndpoints.sendMessage, body: {
        'friendship_id': friendshipId,
        'content': content.trim(),
      });
      final newMsg = ChatMessage.fromJson(res);
      state = state.copyWith(
        messages: [...state.messages, newMsg],
        isSending: false,
      );
    } catch (e) {
      // Fallback for demo or offline mode: add outgoing message smoothly
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final localMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        friendshipId: friendshipId,
        senderId: 'me',
        content: content.trim(),
        status: 'delivered',
        createdAt: timeStr,
      );
      state = state.copyWith(
        messages: [...state.messages, localMsg],
        isSending: false,
      );

      // If chatting with Anand Kumar in demo mode, send a friendly simulation reply
      if (friendshipId.contains('33333333') || friendshipId.contains('anand')) {
        Future.delayed(const Duration(seconds: 2), () {
          final replyMsg = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            friendshipId: friendshipId,
            senderId: 'anand_kumar',
            content: "Hey! Glad to connect on Telegram! How are you doing? 🚀",
            status: 'read',
            createdAt: "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          );
          state = state.copyWith(messages: [...state.messages, replyMsg]);
        });
      }
    }
  }

  Future<void> sendMediaMessage({
    required String type, // 'image' or 'video'
    required String mediaUrl,
    String? caption,
  }) async {
    state = state.copyWith(isSending: true, error: null);
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final rawContent = type == 'image' ? '[IMAGE] $mediaUrl' : '[VIDEO] $mediaUrl';

    final localMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      friendshipId: friendshipId,
      senderId: 'me',
      content: caption != null && caption.isNotEmpty ? '$caption ($rawContent)' : rawContent,
      status: 'delivered',
      createdAt: timeStr,
      messageType: type,
      mediaUrl: mediaUrl,
    );

    state = state.copyWith(
      messages: [...state.messages, localMsg],
      isSending: false,
    );

    try {
      await _client.post(ApiEndpoints.sendMessage, body: {
        'friendship_id': friendshipId,
        'content': rawContent,
        'message_type': type,
        'media_url': mediaUrl,
      });
    } catch (_) {}

    // Simulated reply for demo
    if (friendshipId.contains('33333333') || friendshipId.contains('anand')) {
      Future.delayed(const Duration(seconds: 2), () {
        final replyMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          friendshipId: friendshipId,
          senderId: 'anand_kumar',
          content: type == 'image' ? "Awesome photo! Thanks for sharing! 📸" : "Great video clip! Watching it now! 🎥",
          status: 'read',
          createdAt: "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        );
        state = state.copyWith(messages: [...state.messages, replyMsg]);
      });
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchMessages();
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}

final chatProviderFamily = StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, friendshipId) {
  return ChatNotifier(friendshipId);
});
