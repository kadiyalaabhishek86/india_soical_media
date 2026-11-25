import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class RoomItem {
  final String id;
  final String title;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final String roomType; // 'voice' or 'video'
  final String activityType; // 'ludo', 'carrom', 'truth_or_dare', 'voice_mimic', 'voice_lounge', 'video_stage'
  final String language;
  final String accessType;
  final int entryFeeCoins;
  final int maxSeats;
  final int activeCount;
  final String status;

  RoomItem({
    required this.id,
    required this.title,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    required this.roomType,
    required this.activityType,
    required this.language,
    required this.accessType,
    required this.entryFeeCoins,
    required this.maxSeats,
    required this.activeCount,
    this.status = 'active',
  });

  factory RoomItem.fromJson(Map<String, dynamic> json) {
    return RoomItem(
      id: json['id']?.toString() ?? 'room-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Hangout Room',
      hostId: json['host_id']?.toString() ?? 'host-1',
      hostName: json['host_name']?.toString() ?? 'FriendLoop Host',
      hostAvatar: json['host_avatar']?.toString() ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      roomType: json['room_type']?.toString() ?? 'voice',
      activityType: json['activity_type']?.toString() ?? 'voice_lounge',
      language: json['language']?.toString() ?? 'Hindi',
      accessType: json['access_type']?.toString() ?? 'public',
      entryFeeCoins: (json['entry_fee_coins'] is num) ? (json['entry_fee_coins'] as num).toInt() : 0,
      maxSeats: (json['max_seats'] is num) ? (json['max_seats'] as num).toInt() : 12,
      activeCount: (json['active_count'] is num) ? (json['active_count'] as num).toInt() : 1,
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'host_id': hostId,
      'host_name': hostName,
      'host_avatar': hostAvatar,
      'room_type': roomType,
      'activity_type': activityType,
      'language': language,
      'access_type': accessType,
      'entry_fee_coins': entryFeeCoins,
      'max_seats': maxSeats,
      'active_count': activeCount,
      'status': status,
    };
  }
}

class RoomsState {
  final List<RoomItem> rooms;
  final bool isLoading;
  final String? error;
  final String currentFilter; // 'all', 'voice', 'video'

  RoomsState({
    required this.rooms,
    this.isLoading = false,
    this.error,
    this.currentFilter = 'all',
  });

  RoomsState copyWith({
    List<RoomItem>? rooms,
    bool? isLoading,
    String? error,
    String? currentFilter,
  }) {
    return RoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class RoomsNotifier extends StateNotifier<RoomsState> {
  final ApiClient _client = ApiClient();

  static final List<RoomItem> defaultSeedRooms = [
    RoomItem(
      id: '55555555-aaaa-bbbb-cccc-555555555556',
      title: 'Carrom Clash Match #408 🎯',
      hostId: 'host-carrom',
      hostName: 'Rhea Sharma',
      hostAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      roomType: 'voice',
      activityType: 'carrom',
      language: 'Hindi',
      accessType: 'public',
      entryFeeCoins: 10,
      maxSeats: 2,
      activeCount: 2,
    ),
    RoomItem(
      id: '55555555-aaaa-bbbb-cccc-555555555557',
      title: 'Party Room #104 Voice Mimic 🐱',
      hostId: 'host-tom',
      hostName: 'Rohan Verma',
      hostAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      roomType: 'voice',
      activityType: 'voice_mimic',
      language: 'English',
      accessType: 'public',
      entryFeeCoins: 0,
      maxSeats: 10,
      activeCount: 6,
    ),
    RoomItem(
      id: '55555555-aaaa-bbbb-cccc-555555555553',
      title: 'Party #104 Truth or Dare 🍾',
      hostId: 'host-tod',
      hostName: 'Ananya Gupta',
      hostAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
      roomType: 'voice',
      activityType: 'truth_or_dare',
      language: 'Hindi',
      accessType: 'public',
      entryFeeCoins: 0,
      maxSeats: 15,
      activeCount: 8,
    ),
    RoomItem(
      id: '55555555-aaaa-bbbb-cccc-555555555555',
      title: 'TABLE #12 Ludo 2v2 Party 🎲',
      hostId: 'host-ludo',
      hostName: 'Karthik M',
      hostAvatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
      roomType: 'voice',
      activityType: 'ludo',
      language: 'Hindi',
      accessType: 'public',
      entryFeeCoins: 10,
      maxSeats: 4,
      activeCount: 4,
    ),
    RoomItem(
      id: '55555555-aaaa-bbbb-cccc-555555555551',
      title: 'Chai & Conversations ☕',
      hostId: 'host-chai',
      hostName: 'Priya Nair',
      hostAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      roomType: 'voice',
      activityType: 'voice_lounge',
      language: 'Hindi',
      accessType: 'public',
      entryFeeCoins: 0,
      maxSeats: 20,
      activeCount: 18,
    ),
    RoomItem(
      id: '55555555-aaaa-bbbb-cccc-555555555552',
      title: 'Travel Buddies India ✈️',
      hostId: 'host-travel',
      hostName: 'Rahul Singh',
      hostAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      roomType: 'video',
      activityType: 'video_stage',
      language: 'English',
      accessType: 'public',
      entryFeeCoins: 0,
      maxSeats: 24,
      activeCount: 24,
    ),
  ];

  RoomsNotifier() : super(RoomsState(rooms: defaultSeedRooms)) {
    fetchRooms();
  }

  Future<void> fetchRooms({String? filter}) async {
    final activeFilter = filter ?? state.currentFilter;
    state = state.copyWith(isLoading: true, currentFilter: activeFilter);

    try {
      final res = await _client.get('/rooms?type=$activeFilter');
      if (res is List) {
        final List<RoomItem> serverRooms = res.map((r) => RoomItem.fromJson(Map<String, dynamic>.from(r))).toList();

        // Preserve locally created rooms that may not be synced to server yet
        final serverIds = serverRooms.map((r) => r.id).toSet();
        final localCreated = state.rooms.where((r) => !serverIds.contains(r.id) && !defaultSeedRooms.any((d) => d.id == r.id)).toList();

        // Merge: local created rooms first, then server rooms, then default seeds if few
        final merged = [...localCreated, ...serverRooms];
        if (merged.isEmpty) {
          merged.addAll(defaultSeedRooms.where((d) => activeFilter == 'all' || d.roomType == activeFilter));
        }

        state = state.copyWith(rooms: merged, isLoading: false);
        return;
      }
    } catch (e) {
      // Keep existing rooms with fallback seeds so UI is never empty
      final fallback = state.rooms.isNotEmpty
          ? state.rooms
          : defaultSeedRooms.where((d) => activeFilter == 'all' || d.roomType == activeFilter).toList();
      state = state.copyWith(rooms: fallback, isLoading: false, error: e.toString());
    }
  }

  Future<RoomItem> createRoom({
    required String title,
    required String roomType,
    required String activityType,
    required String language,
    required String accessType,
    required int entryFeeCoins,
    required int maxSeats,
  }) async {
    // Generate optimistic room item immediately
    final newId = 'local-room-${DateTime.now().millisecondsSinceEpoch}';
    final localRoom = RoomItem(
      id: newId,
      title: title,
      hostId: 'current-user',
      hostName: 'You (Host)',
      hostAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      roomType: roomType,
      activityType: activityType,
      language: language,
      accessType: accessType,
      entryFeeCoins: entryFeeCoins,
      maxSeats: maxSeats,
      activeCount: 1,
    );

    // Immediately insert at index 0 so rooms menu shows it right away!
    state = state.copyWith(rooms: [localRoom, ...state.rooms]);

    // Attempt to sync with backend
    try {
      final res = await _client.post(
        '/rooms',
        body: {
          'title': title,
          'room_type': roomType,
          'activity_type': activityType,
          'language': language,
          'access_type': accessType,
          'entry_fee_coins': entryFeeCoins,
          'max_seats': maxSeats,
        },
      );
      if (res is Map<String, dynamic>) {
        final serverRoom = RoomItem.fromJson(res);
        // Replace temporary localRoom with server response room
        final updatedList = state.rooms.map((r) => r.id == newId ? serverRoom : r).toList();
        state = state.copyWith(rooms: updatedList);
        return serverRoom;
      }
    } catch (_) {
      // Local room remains in state so user can still enter and use the room!
    }

    return localRoom;
  }
}

final roomsProvider = StateNotifierProvider<RoomsNotifier, RoomsState>((ref) {
  return RoomsNotifier();
});
