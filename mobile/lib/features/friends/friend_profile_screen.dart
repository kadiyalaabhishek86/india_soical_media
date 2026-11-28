import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/coin_billing.dart';
import '../../core/utils/nav_helper.dart';

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
  final PageController _photoPageController = PageController();
  Timer? _autoScrollTimer;
  Timer? _snackDismissTimer;
  int _currentPhotoIndex = 0;
  bool _isLoading = false;
  bool _friendRequestSent = false;

  String _displayName = 'Ananya Reddy';
  int _age = 26;
  String? _gender = 'Female';
  String? _state = 'Telangana';
  String? _city = 'Bengaluru';
  String? _languages = 'Telugu, English, Hindi';
  String? _bio = 'Techie, foodie and a movie lover. I enjoy meaningful conversations and making new friends.';
  String? _lookingFor = 'Long-term relationship';
  List<String> _images = const [
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
  ];
  String? _friendId;

  String _distance = '84 miles away';
  String _height = '168 cm';
  String _orientation = 'Straight';
  String _pets = 'Dog lover 🐶';
  String _drinking = 'Socially 🍷';
  String _smoking = 'Non-smoker 🚭';
  String _workouts = 'Regular workouts 💪';
  String _socialMedia = 'Active on Instagram 📱';
  String _zodiac = 'Scorpio ♏';
  String _education = 'Masters Graduate 🎓';
  String _familyPlan = 'Wants children 👶';
  String _communicationStyle = 'Big texter & calls 💬';
  String _loveStyle = 'Quality time & words of affirmation 💜';
  List<String> _interests = const [
    'Long walks with photography 📷',
    'Biryani 🍛',
    'Harry Potter ⚡',
  ];

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
      _lookingFor = f.lookingFor ?? 'Long-term relationship';
      _languages = f.languages ?? _languages;

      if (f.images.isNotEmpty) {
        _images = List<String>.from(f.images);
      } else if (f.avatarUrl != null && f.avatarUrl!.isNotEmpty) {
        _images = [f.avatarUrl!];
      }

      _distance = f.distance ?? _distance;
      _height = f.height ?? _height;
      _orientation = f.orientation ?? _orientation;
      _pets = f.pets ?? _pets;
      _drinking = f.drinking ?? _drinking;
      _smoking = f.smoking ?? _smoking;
      _workouts = f.workouts ?? _workouts;
      _socialMedia = f.socialMedia ?? _socialMedia;
      _zodiac = f.zodiac ?? _zodiac;
      _education = f.education ?? _education;
      _familyPlan = f.familyPlan ?? _familyPlan;
      _communicationStyle = f.communicationStyle ?? _communicationStyle;
      _loveStyle = f.loveStyle ?? _loveStyle;
      if (f.interests != null && f.interests!.isNotEmpty) {
        _interests = List<String>.from(f.interests!);
      }
    }
    _loadFriendProfile();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_photoPageController.hasClients || _images.length <= 1) return;
      final next = (_currentPhotoIndex + 1) % _images.length;
      _photoPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _snackDismissTimer?.cancel();
    _photoPageController.dispose();
    super.dispose();
  }

  FriendItem _buildFriendExtra() {
    return widget.initialFriend ??
        FriendItem(
          friendshipId: widget.friendshipId,
          friendId: _friendId ?? '',
          displayName: _displayName,
          state: _state ?? 'India',
          city: _city,
          images: _images,
        );
  }

  void _handleVoiceCall() {
    final friend = _buildFriendExtra();
    if (!CoinBilling.checkAndDeductForAction(
      context: context,
      ref: ref,
      actionType: CoinActionType.voice,
      friend: friend,
    )) {
      return;
    }
    context.push('/call', extra: friend);
  }

  void _handleVideoCall() {
    final friend = _buildFriendExtra();
    if (!CoinBilling.checkAndDeductForAction(
      context: context,
      ref: ref,
      actionType: CoinActionType.video,
      friend: friend,
    )) {
      return;
    }
    context.push('/call/video', extra: friend);
  }

  void _handleChat() {
    final friend = _buildFriendExtra();
    if (!CoinBilling.checkAndDeductForAction(
      context: context,
      ref: ref,
      actionType: CoinActionType.chat,
      friend: friend,
      chatRouteId: widget.friendshipId,
    )) {
      return;
    }
    context.push('/chat/${widget.friendshipId}', extra: friend);
  }

  Future<void> _loadFriendProfile() async {
    if (!ApiEndpoints.isValidUuid(widget.friendshipId)) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
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
          _languages = data['languages'] ?? _languages;
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
    return Scaffold(
      backgroundColor: FriendLoopColors.canvas, // FriendLoop canvas #F4EBFC
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => safePop(context),
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(
            color: FriendLoopColors.plum,
            fontSize: 18,
            fontWeight: FontWeight.bold,
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

              // 1. 3-Photo Horizontal Swiper with page indicator bars
              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _photoPageController,
                        itemCount: _images.length,
                        onPageChanged: (idx) => setState(() => _currentPhotoIndex = idx),
                        itemBuilder: (ctx, idx) {
                          return Image.network(
                            _images[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/telegram/wallpaper_sample.png',
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                      // Segmented progress bars at top
                      if (_images.length > 1)
                        Positioned(
                          top: 12,
                          left: 14,
                          right: 14,
                          child: Row(
                            children: List.generate(_images.length, (pIdx) {
                              final isCur = pIdx == _currentPhotoIndex;
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: isCur ? Colors.white : Colors.white.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 2),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                            stops: const [0.55, 1.0],
                          ),
                        ),
                      ),
                      // Name & Age & Online status on photo
                      Positioned(
                        bottom: 14,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 4),
                                    ],
                                  ),
                                ),
                                Text(
                                  ', $_age',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: FriendLoopColors.onlineGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• ${_city ?? "Bengaluru"}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
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
              ),
              const SizedBox(height: 14),

              // 1b. Neat & Clean Quick Action Bar right under the profile image
              _buildTopActionBar(),
              const SizedBox(height: 14),

              // 2. Looking For Card
              _buildSectionCard(
                title: 'Looking for',
                icon: Icons.favorite_outline_rounded,
                child: Text(
                  _lookingFor ?? 'Long-term relationship',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FriendLoopColors.plum,
                  ),
                ),
              ),

              // 3. Essentials Card
              _buildSectionCard(
                title: 'Essentials',
                icon: Icons.person_pin_circle_outlined,
                child: Column(
                  children: [
                    _buildDetailRow(Icons.near_me_outlined, _distance),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.height_rounded, 'Height $_height'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.location_city_outlined, _city ?? 'Bengaluru'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.transgender_outlined, _orientation),
                  ],
                ),
              ),

              // 4. Lifestyle Card
              _buildSectionCard(
                title: 'Lifestyle',
                icon: Icons.spa_outlined,
                child: Column(
                  children: [
                    _buildDetailRow(Icons.pets_outlined, 'Pets: $_pets'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.local_bar_outlined, 'Drinking: $_drinking'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.smoke_free_outlined, 'Smoking: $_smoking'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.fitness_center_outlined, 'Workouts: $_workouts'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.camera_alt_outlined, 'Social media: $_socialMedia'),
                  ],
                ),
              ),

              // 5. Basics Card
              _buildSectionCard(
                title: 'Basics',
                icon: Icons.info_outline_rounded,
                child: Column(
                  children: [
                    _buildDetailRow(Icons.auto_awesome_outlined, 'Zodiac: $_zodiac'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.school_outlined, 'Education: $_education'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.child_care_outlined, 'Family plan: $_familyPlan'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.chat_bubble_outline_rounded, 'Communication style: $_communicationStyle'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.favorite_border_rounded, 'Love style: $_loveStyle'),
                  ],
                ),
              ),

              // 6. Interests Card
              _buildSectionCard(
                title: 'Interests',
                icon: Icons.interests_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interests
                      .map((interest) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: FriendLoopColors.lavender.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FriendLoopColors.violet.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: FriendLoopColors.plum,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // 7. Bio Card
              _buildSectionCard(
                title: 'Bio',
                icon: Icons.person_outline,
                child: Text(
                  _bio ?? 'Techie, foodie and a movie lover. I enjoy meaningful conversations and making new friends.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: FriendLoopColors.plum,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // 8. + Add Friend Button (shows "Friend Request Sent" when clicked)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _friendRequestSent
                      ? null
                      : () {
                          setState(() => _friendRequestSent = true);
                          _snackDismissTimer?.cancel();
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Friend request sent to $_displayName!'),
                              backgroundColor: FriendLoopColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _snackDismissTimer = Timer(const Duration(seconds: 2), () {
                            if (mounted) {
                              ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
                            }
                          });
                        },
                  icon: Icon(
                    _friendRequestSent ? Icons.check_circle_rounded : Icons.person_add_alt_1,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    _friendRequestSent ? 'Friend Request Sent' : '+ Add Friend',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _friendRequestSent ? FriendLoopColors.success : FriendLoopColors.violet,
                    disabledBackgroundColor: FriendLoopColors.success,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              if (_friendRequestSent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: FriendLoopColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 15, color: FriendLoopColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Friend request sent to $_displayName',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: FriendLoopColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionBar() {
    final profile = ref.watch(authProvider).currentUserProfile;
    final isPlus = profile?.isPlusSubscriber ?? false;
    final coins = profile?.coins ?? 120;
    final voiceCost = CoinBilling.costForAction(CoinActionType.voice, isPlus: isPlus);
    final videoCost = CoinBilling.costForAction(CoinActionType.video, isPlus: isPlus);
    final chatCost = CoinBilling.costForAction(CoinActionType.chat, isPlus: isPlus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FriendLoopColors.lavender),
        boxShadow: [
          BoxShadow(
            color: FriendLoopColors.violet.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionPill(
                  icon: Icons.mic_none_outlined,
                  label: 'Voice',
                  rateText: '${voiceCost}c/m',
                  color: FriendLoopColors.violet,
                  onTap: _handleVoiceCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionPill(
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  rateText: '${videoCost}c/m',
                  color: const Color(0xFF7B2CBF),
                  onTap: _handleVideoCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionPill(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  rateText: '${chatCost}c',
                  color: FriendLoopColors.plum,
                  onTap: _handleChat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.push('/wallet'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FriendLoopColors.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    '$coins coins • ${CoinBilling.planLabel(isPlus)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Check Coins ›',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: FriendLoopColors.violet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required String rateText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: FriendLoopColors.canvas,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FriendLoopColors.lavender, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FriendLoopColors.plum,
                ),
              ),
              Text(
                rateText,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: FriendLoopColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              Icon(icon, size: 18, color: FriendLoopColors.violet),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: FriendLoopColors.plum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FriendLoopColors.violet),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: FriendLoopColors.plum,
            ),
          ),
        ),
      ],
    );
  }
}
