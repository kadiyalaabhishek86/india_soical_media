import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

final List<Map<String, dynamic>> defaultSeedReels = [
  {
    'id': '11111111-aaaa-bbbb-cccc-111111111111',
    'user_name': 'Priya Patel',
    'user_avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'thumbnail_url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
    'caption': 'Friendship trips hit different! 💜',
    'likes_count': 3401,
    'comments_count': 287,
    'is_liked': false,
  },
  {
    'id': '22222222-aaaa-bbbb-cccc-222222222222',
    'user_name': 'Rohit Verma',
    'user_avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'thumbnail_url': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80',
    'caption': 'Weekend trek with friends! ⛰️',
    'likes_count': 1820,
    'comments_count': 94,
    'is_liked': false,
  },
  {
    'id': '33333333-aaaa-bbbb-cccc-333333333333',
    'user_name': 'Neha Jain',
    'user_avatar': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    'thumbnail_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
    'caption': 'Chai and long conversations in Bengaluru ☕✨',
    'likes_count': 2950,
    'comments_count': 142,
    'is_liked': false,
  },
  {
    'id': '44444444-aaaa-bbbb-cccc-444444444444',
    'user_name': 'Vikram Rao',
    'user_avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
    'thumbnail_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
    'caption': 'Road trip across the Western Ghats 🚗💨',
    'likes_count': 4120,
    'comments_count': 310,
    'is_liked': false,
  },
  {
    'id': '55555555-aaaa-bbbb-cccc-555555555555',
    'user_name': 'Ananya Reddy',
    'user_avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    'thumbnail_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    'caption': 'Exploring hidden cafes in Hyderabad ☕🥐',
    'likes_count': 3890,
    'comments_count': 245,
    'is_liked': false,
  },
  {
    'id': '66666666-aaaa-bbbb-cccc-666666666666',
    'user_name': 'Arjun Mehta',
    'user_avatar': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=400&q=80',
    'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
    'thumbnail_url': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=800&q=80',
    'caption': 'Next trip, count me in! Sunset vibes 🌅',
    'likes_count': 2150,
    'comments_count': 88,
    'is_liked': false,
  },
];

class ReelsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final ApiClient _client = ApiClient();
  static final List<Map<String, dynamic>> _persistedUploadedReels = [];

  ReelsNotifier() : super([..._persistedUploadedReels, ...defaultSeedReels]) {
    fetchReels();
  }

  /// Adds a newly uploaded reel to the very top (index 0).
  /// Persists across screen reloads, page navigation, and refresh.
  void addUploadedReel(Map<String, dynamic> reel) {
    // Remove if duplicate id exists
    final id = reel['id']?.toString();
    _persistedUploadedReels.removeWhere((r) => r['id']?.toString() == id);
    _persistedUploadedReels.insert(0, Map<String, dynamic>.from(reel));

    final currentOthers = state.where((r) => r['id']?.toString() != id).toList();
    state = [Map<String, dynamic>.from(reel), ...currentOthers];
  }

  /// Fetches reels from backend API, while ensuring user's uploaded reels stay at index 0.
  /// When [shuffle] is true (e.g. reload or pull-to-refresh), feed reels are refreshed and rotated.
  Future<void> fetchReels({String feed = 'discover', bool shuffle = false}) async {
    final bool isFriendsFeed = feed == 'friends' || feed == 'following';
    const friendNames = {'Priya Patel', 'Rohit Verma', 'Neha Jain', 'Ananya Reddy', 'You'};

    List<Map<String, dynamic>> applyFeedOrder(List<Map<String, dynamic>> items) {
      if (!isFriendsFeed) return items;
      final friendReels = items
          .where((r) => friendNames.any((n) => (r['user_name'] ?? '').toString().toLowerCase().contains(n.toLowerCase())))
          .toList();
      return friendReels.isNotEmpty ? friendReels : items;
    }

    try {
      final res = await _client.get('/reels?feed=$feed');
      if (res is List && res.isNotEmpty) {
        var serverList = res.map((r) => Map<String, dynamic>.from(r as Map)).toList();
        if (shuffle) {
          serverList.shuffle();
        }
        final seenIds = <String>{};

        final merged = <Map<String, dynamic>>[];
        // 1. Keep user's uploaded reels at the very top
        for (final r in _persistedUploadedReels) {
          final id = r['id']?.toString() ?? '';
          if (id.isNotEmpty && !seenIds.contains(id)) {
            seenIds.add(id);
            merged.add(r);
          }
        }
        // 2. Add backend server reels
        for (final r in serverList) {
          final id = r['id']?.toString() ?? '';
          if (id.isNotEmpty && !seenIds.contains(id)) {
            seenIds.add(id);
            merged.add(r);
          }
        }
        // 3. Add any remaining seed reels
        final seeds = shuffle
            ? (List<Map<String, dynamic>>.from(defaultSeedReels)..shuffle())
            : defaultSeedReels;
        for (final r in seeds) {
          final id = r['id']?.toString() ?? '';
          if (id.isNotEmpty && !seenIds.contains(id)) {
            seenIds.add(id);
            merged.add(r);
          }
        }

        state = applyFeedOrder(merged);
        return;
      }
    } catch (_) {
      // Fall through to offline / fallback merge below
    }

    // In offline / fallback mode, keep uploaded reels + seed reels
    final seenIds = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final r in _persistedUploadedReels) {
      final id = r['id']?.toString() ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        merged.add(r);
      }
    }
    final seeds = shuffle
        ? (List<Map<String, dynamic>>.from(defaultSeedReels)..shuffle())
        : defaultSeedReels;
    for (final r in seeds) {
      final id = r['id']?.toString() ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        merged.add(r);
      }
    }
    state = applyFeedOrder(merged);
  }

  void removeReel(String reelId) {
    state = state.where((r) => r['id']?.toString() != reelId).toList();
  }

  void incrementCommentCount(String reelId) {
    state = state.map((reel) {
      if (reel['id']?.toString() == reelId) {
        final count = (reel['comments_count'] is num) ? (reel['comments_count'] as num).toInt() : 0;
        return {
          ...reel,
          'comments_count': count + 1,
        };
      }
      return reel;
    }).toList();
  }

  void toggleLike(String reelId) {
    state = state.map((reel) {
      if (reel['id']?.toString() == reelId) {
        final wasLiked = reel['is_liked'] == true;
        final count = (reel['likes_count'] as int?) ?? 0;
        return {
          ...reel,
          'is_liked': !wasLiked,
          'likes_count': wasLiked ? count - 1 : count + 1,
        };
      }
      return reel;
    }).toList();

    if (ApiEndpoints.isValidUuid(reelId)) {
      _client.post('/reels/$reelId/like').catchError((_) => null);
    }
  }
}

final reelsProvider = StateNotifierProvider<ReelsNotifier, List<Map<String, dynamic>>>((ref) {
  return ReelsNotifier();
});
