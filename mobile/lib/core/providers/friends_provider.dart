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

// Default pre-populated chats matching Telegram screenshot (Image 1)
final List<FriendItem> defaultTelegramChats = [
  FriendItem(
    friendshipId: 'chat_devops',
    friendId: 'user_devops',
    displayName: 'September 23rd Devops wit...',
    state: 'India',
    lastMessage: 'About Me – DevOps & AWS Engi...',
    customDate: 'Feb 7, 2025',
    isPinned: true,
    localAssetImage: 'assets/telegram/devops.png',
  ),
  FriendItem(
    friendshipId: 'chat_python_batch',
    friendId: 'user_python_batch',
    displayName: 'Nov 1 Python Batch Python...',
    state: 'India',
    lastMessage: 'Bonus Courses: 50+ IT Full Cours...',
    customDate: 'Jan 2, 2025',
    isPinned: true,
    localAssetImage: 'assets/telegram/python_batch.png',
  ),
  FriendItem(
    friendshipId: 'chat_hi',
    friendId: 'user_hi',
    displayName: 'hi',
    state: 'India',
    lastMessage: 'You: ALLOWED_FILE_EXTENSIO...',
    customDate: 'Tue',
    isOutgoingSent: true,
    isPinned: true,
    localAssetImage: 'assets/telegram/hi.png',
  ),
  FriendItem(
    friendshipId: 'chat_freshershunt',
    friendId: 'user_freshershunt',
    displayName: 'Freshershunt - Off Campu...',
    state: 'India',
    lastMessage: '📕 INFOSYS MEGA OFF CAM...',
    customDate: '11:05 AM',
    isMuted: true,
    badgeText: '12.6K',
    localAssetImage: 'assets/telegram/freshershunt.png',
  ),
  FriendItem(
    friendshipId: 'chat_technical_hub',
    friendId: 'user_technical_hub',
    displayName: 'Technical Hub 📈',
    state: 'India',
    lastMessage: '🧔 GeeksforGeeks x OpenAI pr...',
    customDate: '08:20 AM',
    badgeText: '82',
    localAssetImage: 'assets/telegram/technical_hub.png',
  ),
  FriendItem(
    friendshipId: 'chat_walkin_drives',
    friendId: 'user_walkin_drives',
    displayName: 'Walkin_drives',
    state: 'India',
    lastMessage: '🚀 MEGA FRESHERS WALK-IN ...',
    customDate: 'Thu',
    badgeText: '46',
    localAssetImage: 'assets/telegram/walkin_drives.png',
  ),
  FriendItem(
    friendshipId: 'chat_pythonlife_jobs',
    friendId: 'user_pythonlife_jobs',
    displayName: 'PythonLife Jobs 📢',
    state: 'India',
    lastMessage: 'PythonLife – Full Stack Pyt...',
    customDate: 'Thu',
    isMuted: true,
    badgeText: '2.4K',
    localAssetImage: 'assets/telegram/pythonlife_jobs.png',
  ),
  FriendItem(
    friendshipId: 'chat_pythonlife_community',
    friendId: 'user_pythonlife_community',
    displayName: 'PythonLife Community 📢',
    state: 'India',
    lastMessage: 'PYTHONLIFE: 🚀 Dear Group ...',
    customDate: 'Wed',
    isMuted: true,
    badgeText: '4.3K',
    localAssetImage: 'assets/telegram/pythonlife_community.png',
  ),
  FriendItem(
    friendshipId: '33333333-3333-3333-3333-333333333333',
    friendId: '33333333-3333-3333-3333-333333333333',
    displayName: 'Anand Kumar',
    state: 'Telangana',
    city: 'Hyderabad',
    age: 24,
    gender: 'Male',
    lastMessage: 'Anand Kumar joined Telegram',
    customDate: 'Tue',
    statusText: 'last seen 41 minutes ago',
    localAssetImage: 'assets/telegram/anand_kumar.png',
    images: const [
      'assets/telegram/anand_kumar.png',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
    ],
  ),
  FriendItem(
    friendshipId: 'chat_python',
    friendId: 'user_python',
    displayName: 'Python 📢',
    state: 'India',
    lastMessage: 'Doragonkiraa: Check out @Pyt...',
    customDate: 'Tue',
    isMuted: true,
    badgeText: '3.2K',
    localAssetImage: 'assets/telegram/python.png',
  ),
  FriendItem(
    friendshipId: '44444444-4444-4444-4444-444444444444',
    friendId: '44444444-4444-4444-4444-444444444444',
    displayName: 'Ananya Iyer',
    state: 'Tamil Nadu',
    city: 'Chennai',
    age: 23,
    gender: 'Female',
    lastMessage: 'Do you listen to fusion jazz? 🎶',
    customDate: '10:14 AM',
    badgeText: '2',
    statusText: 'online',
    images: const [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    ],
  ),
  FriendItem(
    friendshipId: '77777777-7777-7777-7777-777777777777',
    friendId: '77777777-7777-7777-7777-777777777777',
    displayName: 'Sneha Reddy',
    state: 'Karnataka',
    city: 'Bengaluru',
    age: 23,
    gender: 'Female',
    lastMessage: 'Filter coffee in Bengaluru is undefeated 😉',
    customDate: '09:30 AM',
    badgeText: '1',
    statusText: 'last seen 2 hours ago',
    images: const [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
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
