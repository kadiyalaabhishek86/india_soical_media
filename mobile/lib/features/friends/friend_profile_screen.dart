import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/friends_provider.dart';

class FriendProfileScreen extends ConsumerStatefulWidget {
  final String friendshipId;
  final FriendItem? initialFriend;

  const FriendProfileScreen({
    super.key,
    required this.friendshipId,
    this.initialFriend,
  });

  @override
  ConsumerState<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  final ApiClient _client = ApiClient();
  bool _isLoading = false;

  String _displayName = 'Ananya Reddy';
  int _age = 26;
  String? _gender = 'Female';
  String? _state = 'Telangana';
  String? _city = 'Hyderabad';
  String? _languages = 'Telugu, English, Hindi';
  String? _bio = 'Techie, foodie and a movie lover. I enjoy meaningful conversations and making new friends.';
  String? _lookingFor = 'Friendly chats, voice hangouts and like-minded friends.';
  List<String> _images = const [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
  ];
  String? _friendId;

  @override
  void initState() {
    super.initState();
    if (widget.initialFriend != null) {
      final f = widget.initialFriend!;
      _displayName = f.displayName;
      _state = f.state;
      _city = f.city ?? _city;
      _age = f.age > 0 ? f.age : 26;
      _gender = f.gender ?? 'Female';
      _friendId = f.friendId;
      _bio = f.bio ?? _bio;
      _lookingFor = f.lookingFor ?? _lookingFor;
      if (f.languages != null) {
        if (f.languages is List) {
          _languages = (f.languages as List).join(', ');
        } else {
          _languages = f.languages.toString();
        }
      }

      if (f.images.isNotEmpty) {
        _images = List<String>.from(f.images);
      } else if (f.avatarUrl != null && f.avatarUrl!.isNotEmpty) {
        _images = [f.avatarUrl!];
      }
    }
    _loadFriendProfile();
  }

  Future<void> _loadFriendProfile() async {
    try {
      final data = await _client.get(ApiEndpoints.friendProfile(widget.friendshipId));
      if (mounted) {
        setState(() {
          _displayName = data['display_name'] ?? _displayName;
          _age = data['age'] ?? _age;
          _gender = data['gender'] ?? _gender;
          _state = data['state_or_union_territory'] ?? _state;
          _city = data['city'] ?? _city;
          _bio = data['bio'] ?? _bio;
          _lookingFor = data['looking_for'] ?? _lookingFor;
          if (data['languages'] != null) {
            if (data['languages'] is List) {
              _languages = (data['languages'] as List).join(', ');
            } else {
              _languages = data['languages'].toString();
            }
          }
          if (data['images'] != null && (data['images'] as List).isNotEmpty) {
            _images = List<String>.from(data['images']);
          }
          _friendId = data['friend_id'] ?? data['id'] ?? _friendId;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmBlock() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Block $_displayName?', style: const TextStyle(color: FriendLoopColors.plum)),
        content: const Text(
          'They will not be able to call you, message you, or see your profile again.',
          style: TextStyle(color: FriendLoopColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: FriendLoopColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              if (_friendId != null) {
                await _client.post(ApiEndpoints.block, body: {'blocked_id': _friendId});
                await ref.read(friendsProvider.notifier).fetchFriends();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$_displayName has been blocked.')),
                  );
                  context.go('/friends');
                }
              }
            },
            child: const Text('Block User', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmUnfriend() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('End Friendship with $_displayName?', style: const TextStyle(color: FriendLoopColors.plum)),
        content: const Text(
          'This will remove them from your friends list.',
          style: TextStyle(color: FriendLoopColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: FriendLoopColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(friendsProvider.notifier).unfriend(widget.friendshipId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Friendship ended with $_displayName.')),
                );
                context.go('/friends');
              }
            },
            child: const Text('End Friendship', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _images.isNotEmpty
        ? _images.first
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80';

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas, // FriendLoop canvas #F4EBFC
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => context.pop(),
        ),
        title: Image.asset(
          'assets/images/friendloop_logo.png',
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.all_inclusive_rounded,
            color: FriendLoopColors.violet,
            size: 28,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: FriendLoopColors.plum),
            onSelected: (val) {
              if (val == 'block') {
                _confirmBlock();
              } else if (val == 'unfriend') {
                _confirmUnfriend();
              } else if (val == 'report') {
                context.push('/report-block');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20, color: FriendLoopColors.plum),
                    SizedBox(width: 10),
                    Text('Report User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unfriend',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_outlined, size: 20, color: FriendLoopColors.plum),
                    SizedBox(width: 10),
                    Text('End Friendship'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: FriendLoopColors.rose),
                    SizedBox(width: 10),
                    Text('Block User', style: TextStyle(color: FriendLoopColors.rose)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isLoading)
                const LinearProgressIndicator(
                  minHeight: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(FriendLoopColors.violet),
                ),

              // "User Profile" Title (matching mockup Screen 1)
              const Text(
                'User Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: FriendLoopColors.plum,
                ),
              ),
              const SizedBox(height: 14),

              // 1. Main Profile Card (Rounded photo, Name, Age/Online, City, Languages)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FriendLoopColors.lavender),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        avatarUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/telegram/wallpaper_sample.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              color: FriendLoopColors.plum,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${_gender == 'Female' ? '♀ ' : '♂ '}$_age • ',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: FriendLoopColors.textSecondary,
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: FriendLoopColors.onlineGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: FriendLoopColors.onlineGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: FriendLoopColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_city ?? 'Hyderabad'}, ${_state ?? 'India'}',
                                  style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.language_outlined, size: 14, color: FriendLoopColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Languages: ${_languages ?? 'Telugu, English, Hindi'}',
                                  style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Bio Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FriendLoopColors.lavender),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: FriendLoopColors.violet),
                        SizedBox(width: 8),
                        Text(
                          'Bio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: FriendLoopColors.plum,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bio ?? 'Techie, foodie and a movie lover. I enjoy meaningful conversations and making new friends.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: FriendLoopColors.plum,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Looking For Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FriendLoopColors.lavender),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.track_changes_outlined, size: 18, color: FriendLoopColors.violet),
                        SizedBox(width: 8),
                        Text(
                          'Looking for',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: FriendLoopColors.plum,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lookingFor ?? 'Friendly chats, voice hangouts and like-minded friends.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: FriendLoopColors.plum,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. + Add Friend Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Friend request sent to $_displayName!'),
                        backgroundColor: FriendLoopColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                  label: const Text(
                    '+ Add Friend',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 5. Circular Action Buttons Row: Voice, Video, Chat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionCircle(
                    icon: Icons.mic_none_outlined,
                    label: 'Voice',
                    onTap: () => context.push('/call'),
                  ),
                  _buildActionCircle(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    onTap: () => context.push('/call'),
                  ),
                  _buildActionCircle(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    onTap: () {
                      context.push('/chat/${widget.friendshipId}', extra: widget.initialFriend);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: FriendLoopColors.lavender, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: FriendLoopColors.violet, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: FriendLoopColors.plum,
          ),
        ),
      ],
    );
  }
}
