import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

class FriendItem {
  final String friendshipId;
  final String friendId;
  final String displayName;
  final String state;
  final String? city;
  final int unreadCount;
  final String? lastMessage;
  final String? lastMessageTime;
  final int age;
  final String? gender;
  final List<String> images;
  final bool isPinned;
  final bool isMuted;
  final String? badgeText;
  final String? statusText;
  final String? localAssetImage;
  final bool isOutgoingSent;
  final String? customDate;
  final String? bio;
  final String? lookingFor;
  final dynamic languages;
  final String? avatarUrl;

  FriendItem({
    required this.friendshipId,
    required this.friendId,
    required this.displayName,
    required this.state,
    this.city,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageTime,
    this.age = 18,
    this.gender,
    this.images = const [],
    this.isPinned = false,
    this.isMuted = false,
    this.badgeText,
    this.statusText,
    this.localAssetImage,
    this.isOutgoingSent = false,
    this.customDate,
    this.bio,
    this.lookingFor,
    this.languages,
    this.avatarUrl,
  });

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    final name = json['display_name'] ?? 'Friend';
    final isAnand = name.toString().toLowerCase().contains('anand');
    return FriendItem(
      friendshipId: json['friendship_id'] ?? '',
      friendId: json['friend_id'] ?? '',
      displayName: name,
      state: json['state_or_union_territory'] ?? 'India',
      city: json['city'],
      unreadCount: json['unread_count'] ?? 0,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
      age: json['age'] ?? 18,
      gender: json['gender'],
      images: List<String>.from(json['images'] ?? []),
      bio: json['bio'],
      lookingFor: json['looking_for'],
      languages: json['languages'],
      avatarUrl: json['avatar_url'],
      statusText: isAnand ? 'last seen 41 minutes ago' : 'online',
      localAssetImage: isAnand ? 'assets/telegram/anand_kumar.png' : null,
      customDate: isAnand ? 'Tue' : null,
    );
  }
}

// Default pre-populated friends matching FriendLoop mockups (Priya, Rahul, Neha, Vikram, Ananya, Rohan, Sneha, etc.)
final List<FriendItem> defaultTelegramChats = [
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555551',
    friendId: '65555555-5555-5555-5555-555555555551',
    displayName: 'Priya',
    state: 'Tamil Nadu',
    city: 'Chennai',
    age: 25,
    gender: 'Female',
    statusText: 'online',
    lastMessage: 'Hey! Are you free today?',
    images: const [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555552',
    friendId: '65555555-5555-5555-5555-555555555552',
    displayName: 'Rahul',
    state: 'Maharashtra',
    city: 'Mumbai',
    age: 27,
    gender: 'Male',
    statusText: 'online',
    lastMessage: 'Let\'s catch up on a call!',
    images: const [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555553',
    friendId: '65555555-5555-5555-5555-555555555553',
    displayName: 'Neha',
    state: 'Delhi (NCR)',
    city: 'Delhi NCR',
    age: 24,
    gender: 'Female',
    statusText: 'online',
    lastMessage: 'That was fun! 😊',
    images: const [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555554',
    friendId: '65555555-5555-5555-5555-555555555554',
    displayName: 'Vikram',
    state: 'Karnataka',
    city: 'Bengaluru',
    age: 28,
    gender: 'Male',
    statusText: 'online',
    lastMessage: 'Let me know when you are free.',
    images: const [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555555',
    friendId: '65555555-5555-5555-5555-555555555555',
    displayName: 'Ananya Reddy',
    state: 'Telangana',
    city: 'Hyderabad',
    age: 26,
    gender: 'Female',
    statusText: 'online',
    lastMessage: 'Great talking to you! ✨',
    images: const [
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555556',
    friendId: '65555555-5555-5555-5555-555555555556',
    displayName: 'Rohan Verma',
    state: 'Maharashtra',
    city: 'Pune',
    age: 26,
    gender: 'Male',
    statusText: 'online',
    lastMessage: 'Let\'s catch up on a call?',
    images: const [
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555557',
    friendId: '65555555-5555-5555-5555-555555555557',
    displayName: 'Sneha Iyer',
    state: 'Karnataka',
    city: 'Bengaluru',
    age: 24,
    gender: 'Female',
    statusText: 'online',
    lastMessage: 'Filter coffee in Bengaluru is undefeated 😉',
    images: const [
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555558',
    friendId: '65555555-5555-5555-5555-555555555558',
    displayName: 'Aman Gupta',
    state: 'Karnataka',
    city: 'Bengaluru',
    age: 27,
    gender: 'Male',
    statusText: 'online',
    lastMessage: 'Sounds good! See you soon.',
    images: const [
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555559',
    friendId: '65555555-5555-5555-5555-555555555559',
    displayName: 'Kiran Kumar',
    state: 'Telangana',
    city: 'Hyderabad',
    age: 29,
    gender: 'Male',
    statusText: 'online',
    lastMessage: 'Awesome photos from yesterday! 📸',
    images: const [
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '55555555-5555-5555-5555-555555555560',
    friendId: '65555555-5555-5555-5555-555555555560',
    displayName: 'Meghana S',
    state: 'Andhra Pradesh',
    city: 'Visakhapatnam',
    age: 24,
    gender: 'Female',
    statusText: 'online',
    lastMessage: 'Sunset today was incredible 🌅',
    images: const [
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=400&q=80',
    ],
  ),
];

class FriendsState {
  final List<FriendItem> friends;
  final bool isLoading;
  final String? error;
  final bool hasRequestedAddFriend;
  final bool isMutualFriendshipCreated;

  FriendsState({
    this.friends = const [],
    this.isLoading = false,
    this.error,
    this.hasRequestedAddFriend = false,
    this.isMutualFriendshipCreated = false,
  });

  FriendsState copyWith({
    List<FriendItem>? friends,
    bool? isLoading,
    String? error,
    bool? hasRequestedAddFriend,
    bool? isMutualFriendshipCreated,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasRequestedAddFriend: hasRequestedAddFriend ?? this.hasRequestedAddFriend,
      isMutualFriendshipCreated: isMutualFriendshipCreated ?? this.isMutualFriendshipCreated,
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  final ApiClient _client = ApiClient();

  FriendsNotifier() : super(FriendsState(friends: defaultTelegramChats)) {
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final List res = await _client.get(ApiEndpoints.friendshipsList);
      final serverItems = res.map((j) => FriendItem.fromJson(j)).toList();
      
      // Merge server friends into default list so Telegram demo chats are always available
      final Map<String, FriendItem> map = {};
      for (final item in defaultTelegramChats) {
        map[item.friendshipId] = item;
      }
      for (final item in serverItems) {
        map[item.friendshipId] = item;
      }

      state = state.copyWith(friends: map.values.toList(), isLoading: false);
    } catch (e) {
      // Keep existing default list if network or server is unreachable
      state = state.copyWith(
        friends: state.friends.isEmpty ? defaultTelegramChats : state.friends,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> chooseAddFriend({required String callId, required String targetId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(ApiEndpoints.friendChoice, body: {
        'call_id': callId,
        'target_id': targetId,
      });

      final isMutual = res['is_mutual'] == true;
      state = state.copyWith(
        isLoading: false,
        hasRequestedAddFriend: true,
        isMutualFriendshipCreated: isMutual,
      );

      if (isMutual) {
        await fetchFriends();
      }
      return isMutual;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> unfriend(String friendshipId) async {
    try {
      await _client.delete(ApiEndpoints.unfriend(friendshipId));
    } catch (_) {}
    // Remove locally
    final updated = state.friends.where((f) => f.friendshipId != friendshipId).toList();
    state = state.copyWith(friends: updated);
  }

  void resetChoiceState() {
    state = state.copyWith(hasRequestedAddFriend: false, isMutualFriendshipCreated: false);
  }
}

final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier();
});
