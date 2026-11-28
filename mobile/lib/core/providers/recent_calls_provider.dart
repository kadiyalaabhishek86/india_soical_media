import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallHistoryItem {
  final String id;
  final String name;
  final String avatar;
  final String type; // 'incoming', 'outgoing', 'missed'
  final String mode; // 'voice', 'video'
  final String time;
  final int coins;
  final bool isSeen;

  const CallHistoryItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.type,
    required this.mode,
    required this.time,
    this.coins = 0,
    this.isSeen = false,
  });

  CallHistoryItem copyWith({
    String? id,
    String? name,
    String? avatar,
    String? type,
    String? mode,
    String? time,
    int? coins,
    bool? isSeen,
  }) {
    return CallHistoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      time: time ?? this.time,
      coins: coins ?? this.coins,
      isSeen: isSeen ?? this.isSeen,
    );
  }
}

class RecentCallsNotifier extends StateNotifier<List<CallHistoryItem>> {
  RecentCallsNotifier() : super(_initialCalls);

  static const List<CallHistoryItem> _initialCalls = [
    CallHistoryItem(
      id: 'call-1',
      name: 'Rohan Verma',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      type: 'outgoing',
      mode: 'voice',
      time: '5 min ago',
      coins: 10,
      isSeen: true,
    ),
    CallHistoryItem(
      id: 'call-2',
      name: 'Priya Sharma',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      type: 'missed',
      mode: 'video',
      time: '32 min ago',
      coins: 0,
      isSeen: false,
    ),
    CallHistoryItem(
      id: 'call-3',
      name: 'Sneha Iyer',
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
      type: 'incoming',
      mode: 'voice',
      time: '1 hr ago',
      coins: 20,
      isSeen: true,
    ),
    CallHistoryItem(
      id: 'call-4',
      name: 'Rahul Varma',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
      type: 'incoming',
      mode: 'voice',
      time: 'Yesterday, 8:40 PM',
      coins: 10,
      isSeen: true,
    ),
  ];

  void addCallRecord(CallHistoryItem item) {
    state = [item, ...state];
  }

  void markMissedCallsSeen() {
    state = state.map((c) => (c.type == 'missed' && !c.isSeen) ? c.copyWith(isSeen: true) : c).toList();
  }
}

final recentCallsProvider = StateNotifierProvider<RecentCallsNotifier, List<CallHistoryItem>>((ref) {
  return RecentCallsNotifier();
});

final unreadMissedCallsCountProvider = Provider<int>((ref) {
  final calls = ref.watch(recentCallsProvider);
  return calls.where((c) => c.type == 'missed' && !c.isSeen).length;
});

