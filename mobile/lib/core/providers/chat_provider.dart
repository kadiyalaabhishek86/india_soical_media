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

List<ChatMessage> getInitialStarterMessages(String friendshipId) {
  return [
    ChatMessage(
      id: 'starter-1-$friendshipId',
      friendshipId: friendshipId,
      senderId: 'priya',
      content: 'Hey! Are you free today?',
      status: 'delivered',
      createdAt: '12:18 PM',
    ),
    ChatMessage(
      id: 'starter-2-$friendshipId',
      friendshipId: friendshipId,
      senderId: 'me',
      content: 'Yes! Want to have a quick call?',
      status: 'read',
      createdAt: '12:20 PM',
    ),
    ChatMessage(
      id: 'starter-3-$friendshipId',
      friendshipId: friendshipId,
      senderId: 'priya',
      content: 'Sure! Video call?',
      status: 'delivered',
      createdAt: '12:22 PM',
    ),
  ];
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiClient _client = ApiClient();
  final String friendshipId;
  Timer? _poller;

  ChatNotifier(this.friendshipId)
      : super(ChatState(messages: getInitialStarterMessages(friendshipId))) {
    fetchMessages();
    _startPolling();
  }

  Future<void> fetchMessages() async {
    try {
      final List res = await _client.get(ApiEndpoints.getMessages(friendshipId));
      final msgs = res.map((j) => ChatMessage.fromJson(j)).toList();
      if (msgs.isNotEmpty) {
        final serverIds = msgs.map((m) => m.id).toSet();
        final localOnly = state.messages.where((m) => !serverIds.contains(m.id)).toList();
        state = state.copyWith(messages: [...msgs, ...localOnly], isLoading: false);
      }
    } catch (e) {
      // Don't clear existing messages on error in offline/demo mode
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final localId = "msg-${DateTime.now().millisecondsSinceEpoch}";

    final localMsg = ChatMessage(
      id: localId,
      friendshipId: friendshipId,
      senderId: 'me',
      content: content.trim(),
      status: 'delivered',
      createdAt: timeStr,
    );

    // Instant optimistic update: message is immediately visible in the chat!
    state = state.copyWith(
      messages: [...state.messages, localMsg],
      isSending: false,
    );

    // Sync to backend
    try {
      final res = await _client.post(ApiEndpoints.sendMessage, body: {
        'friendship_id': friendshipId,
        'content': content.trim(),
      });
      if (res != null) {
        final serverMsg = ChatMessage.fromJson(res);
        final updatedList = state.messages.map((m) => m.id == localId ? serverMsg : m).toList();
        state = state.copyWith(messages: updatedList);
      }
    } catch (_) {
      // Keep optimistic message
    }

    // Friendly automated reply after 1.5 seconds so chat feels real & responsive
    Future.delayed(const Duration(milliseconds: 1500), () {
      final replyTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
      final replyContent = _generateFriendlyReply(content);
      final replyMsg = ChatMessage(
        id: "reply-${DateTime.now().millisecondsSinceEpoch}",
        friendshipId: friendshipId,
        senderId: 'priya',
        content: replyContent,
        status: 'read',
        createdAt: replyTime,
      );
      state = state.copyWith(messages: [...state.messages, replyMsg]);
    });
  }

  String _generateFriendlyReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('hi') || lower.contains('hello') || lower.contains('hey')) {
      return "Hey there! How's your day going? 😊";
    } else if (lower.contains('call') || lower.contains('voice') || lower.contains('video')) {
      return "Yes! I'm free, let's connect right now 📞✨";
    } else if (lower.contains('reel') || lower.contains('http')) {
      return "Whoa, this reel looks so awesome! Thanks for sharing! 🎬💜";
    } else if (lower.contains('how are you') || lower.contains('sup')) {
      return "Doing great! Just hanging out on FriendLoop. What about you? 😄";
    } else {
      return "Sounds good! Really happy to chat with you! ✨";
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
