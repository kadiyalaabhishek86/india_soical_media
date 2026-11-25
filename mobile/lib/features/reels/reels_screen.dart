import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/reels_provider.dart';
import '../home/main_shell_screen.dart';
import 'video_controller_helper.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final ApiClient _client = ApiClient();
  final PageController _pageController = PageController();

  static final List<Map<String, dynamic>> _defaultSeedReels = [
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
      'thumbnail_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
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

  int _selectedTab = 0; // 0 = Discover, 1 = Following
  int _currentPage = 0;
  int _settledPage = 0;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  void _fetchReels({bool shuffle = false}) {
    ref.read(reelsProvider.notifier).fetchReels(
      feed: _selectedTab == 0 ? 'discover' : 'following',
      shuffle: shuffle,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _navigateToCreateReel() async {
    final res = await context.push('/create-reel');
    if (res is Map<String, dynamic> && mounted) {
      ref.read(reelsProvider.notifier).addUploadedReel(res);
      setState(() {
        _currentPage = 0;
        _settledPage = 0;
        _isScrolling = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your new reel is live! 🎬'),
          backgroundColor: FriendLoopColors.success,
        ),
      );
    } else if (res == true && mounted) {
      ref.read(reelsProvider.notifier).fetchReels(shuffle: true);
    }
  }

  void _showCommentsSheet(BuildContext context, Map<String, dynamic> reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CommentsBottomSheet(reelId: reel['id']?.toString() ?? ''),
    );
  }

  void _showShareModal(BuildContext context, Map<String, dynamic> reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReelShareBottomSheet(reel: reel),
    );
  }

  void _showReelModerationOptions(BuildContext context, Map<String, dynamic> reel, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: FriendLoopColors.violet),
                  SizedBox(width: 8),
                  Text(
                    'Reel Safety & Moderation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Creator: ${reel['user_name'] ?? 'User'}',
                style: const TextStyle(fontSize: 13, color: FriendLoopColors.textSecondary),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined, color: Colors.amber),
                title: const Text('Report Reel', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Report inappropriate content, underage users, or abuse'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportReelDialog(context, reel);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block, color: FriendLoopColors.rose),
                title: Text('Block ${reel['user_name'] ?? 'Creator'}', style: const TextStyle(fontWeight: FontWeight.w600, color: FriendLoopColors.rose)),
                subtitle: const Text('You will no longer see content or reels from them'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmBlockReelCreator(context, reel, index);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.verified_user_outlined, color: FriendLoopColors.violet),
                title: const Text('Child Safety Standards (18+ Policy)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Read zero-tolerance CSAM/CSAE guidelines'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final url = Uri.parse('${ApiEndpoints.rootUrl}/child-safety');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportReelDialog(BuildContext context, Map<String, dynamic> reel) {
    final reasons = [
      'Inappropriate / Explicit Content',
      'Underage User / Minor Safety',
      'Harassment or Hate Speech',
      'Spam or Scam',
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Reel', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this reel?', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            ...reasons.map(
              (r) => ListTile(
                title: Text(r, style: const TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _client.post(
                      '/moderation/report',
                      body: {
                        'target_type': 'reel',
                        'target_id': reel['id']?.toString() ?? 'reel_unknown',
                        'reason': r,
                      },
                    );
                  } catch (_) {}
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted. Our 24/7 moderation team will review it immediately.'),
                        backgroundColor: FriendLoopColors.violet,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlockReelCreator(BuildContext context, Map<String, dynamic> reel, int index) {
    final name = reel['user_name'] ?? 'Creator';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block $name?'),
        content: Text('Are you sure you want to block $name? Their reels and messages will be hidden immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _client.post(
                  ApiEndpoints.block,
                  body: {'blocked_id': reel['user_id'] ?? reel['id'] ?? 'creator'},
                );
              } catch (_) {}
              ref.read(reelsProvider.notifier).removeReel(reel['id']?.toString() ?? '');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name has been blocked.'),
                    backgroundColor: FriendLoopColors.rose,
                  ),
                );
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleLike(int index, List<Map<String, dynamic>> reels) {
    if (index >= 0 && index < reels.length) {
      final reelId = reels[index]['id']?.toString() ?? '';
      ref.read(reelsProvider.notifier).toggleLike(reelId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsProvider);
    final activeShellTab = ref.watch(activeShellTabProvider);
    final isShellReelsVisible = activeShellTab == 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Reel Video Carousel
          if (reels.isEmpty)
            const Center(
              child: Text('No reels found', style: TextStyle(color: Colors.white70)),
            )
          else
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  if (!_isScrolling) {
                    setState(() => _isScrolling = true);
                  }
                } else if (notification is ScrollEndNotification) {
                  final page = _pageController.page?.round() ?? _currentPage;
                  setState(() {
                    _isScrolling = false;
                    _settledPage = page;
                    _currentPage = page;
                  });
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const PageScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: reels.length,
                itemBuilder: (context, index) {
                  final reel = reels[index];
                  final isLiked = reel['is_liked'] == true;
                  final likesCount = reel['likes_count'] ?? 3401;
                  final commentsCount = reel['comments_count'] ?? 287;
                  final userName = reel['user_name'] ?? 'Priya Patel';
                  final caption = reel['caption'] ?? 'Friendship trips hit different! 💜';
                  final rawThumb = reel['thumbnail_url']?.toString();
                  final thumb = (rawThumb != null && rawThumb.startsWith('/'))
                      ? '${ApiEndpoints.rootUrl}$rawThumb'
                      : (rawThumb ?? 'assets/telegram/wallpaper_sample.png');
                  final rawVideo = reel['video_url']?.toString();
                  final videoUrl = (rawVideo != null && rawVideo.startsWith('/'))
                      ? '${ApiEndpoints.rootUrl}$rawVideo'
                      : rawVideo;
                  final fallbackUrl = reel['local_video_url']?.toString();

                  final isSettled = _settledPage == index && !_isScrolling;
                  final isActive = isSettled && isShellReelsVisible;
                  final distance = (index - _settledPage).abs();
                  final shouldPreload = distance <= 1;

                  return Stack(
                    key: ValueKey(reel['id'] ?? 'reel-$index'),
                    fit: StackFit.expand,
                    children: [
                      // Real Interactive Video Player with Auto-loop, Mute & Play/Pause
                      _ReelVideoPlayer(
                        key: ValueKey('${reel['id']}_player'),
                        videoUrl: videoUrl,
                        fallbackUrl: fallbackUrl,
                        thumbnailUrl: thumb,
                        isActive: isActive,
                        shouldPreload: shouldPreload,
                      ),
                    // Dark Gradient Overlay for Readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Right Action Sidebar
                    Positioned(
                      right: 14,
                      bottom: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Like Button
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.redAccent : Colors.white,
                              size: 32,
                            ),
                            onPressed: () => _toggleLike(index, reels),
                          ),
                          Text(
                            '$likesCount',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Comment Button
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 30),
                            onPressed: () => _showCommentsSheet(context, reel),
                          ),
                          Text(
                            '$commentsCount',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Share Button
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 28),
                            onPressed: () {
                              _showShareModal(context, reel);
                            },
                          ),
                          const SizedBox(height: 12),

                          // Report & Block Moderation Button
                          IconButton(
                            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 28),
                            tooltip: 'Report or Block',
                            onPressed: () {
                              _showReelModerationOptions(context, reel, index);
                            },
                          ),
                          const SizedBox(height: 16),

                          // + Create / Upload Reel Button
                          GestureDetector(
                            onTap: _navigateToCreateReel,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: FriendLoopColors.violet,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.video_library_rounded, color: Colors.white, size: 20),
                                  SizedBox(height: 2),
                                  Text(
                                    'Upload\nReel',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Caption & Profile Info
                    Positioned(
                      left: 16,
                      bottom: 30,
                      right: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: FriendLoopColors.lavender,
                                backgroundImage: reel['user_avatar'] != null
                                    ? NetworkImage(reel['user_avatar'])
                                    : null,
                                child: reel['user_avatar'] == null
                                    ? const Icon(Icons.person, color: FriendLoopColors.plum)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Top Header with Infinity Logo and Discover / Following Tabs
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/friendloop_logo.png',
                      height: 28,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.all_inclusive_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tab Pills (Discover vs Following)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabPill('Discover', 0),
                          _buildTabPill('Following', 1),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                      tooltip: 'Reload Reels',
                      onPressed: () {
                        _fetchReels(shuffle: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reels refreshed with new content! 🔄'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: const Icon(Icons.video_library_outlined, color: Colors.white, size: 22),
                      tooltip: 'Upload from Gallery',
                      onPressed: _navigateToCreateReel,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                      onPressed: () => context.push('/notifications'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: const Icon(Icons.search, color: Colors.white, size: 22),
                      onPressed: () => context.push('/friends'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _currentPage = 0;
          _settledPage = 0;
          _isScrolling = false;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
        _fetchReels();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FriendLoopColors.violet : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final String reelId;

  const _CommentsBottomSheet({required this.reelId});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final ApiClient _client = ApiClient();
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final res = await _client.get('/reels/${widget.reelId}/comments');
      if (mounted) {
        setState(() {
          _comments = List<dynamic>.from(res);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();

    try {
      final res = await _client.post(
        '/reels/${widget.reelId}/comments',
        body: {'comment_text': text},
      );
      setState(() {
        _comments.insert(0, res);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 480,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comments (${_comments.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum),
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet. Be the first to comment! ✨',
                            style: TextStyle(
                              color: FriendLoopColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (ctx, idx) {
                        final c = _comments[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: FriendLoopColors.lavender,
                            backgroundImage: c['user_avatar'] != null ? NetworkImage(c['user_avatar']) : null,
                            child: c['user_avatar'] == null ? const Icon(Icons.person, size: 16, color: FriendLoopColors.plum) : null,
                          ),
                          title: Text(
                            c['user_name'] ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.plum),
                          ),
                          subtitle: Text(
                            c['comment_text'] ?? '',
                            style: const TextStyle(fontSize: 13, color: FriendLoopColors.textPrimary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${c['likes_count'] ?? 0}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: FriendLoopColors.canvas,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(fontSize: 13, color: FriendLoopColors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: FriendLoopColors.violet, size: 20),
                    onPressed: _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? fallbackUrl;
  final String thumbnailUrl;
  final bool isActive;
  final bool shouldPreload;

  const _ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    this.fallbackUrl,
    required this.thumbnailUrl,
    required this.isActive,
    this.shouldPreload = true,
  });

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isFirstFrameReady = false;
  bool _isBuffering = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  String _errorMessage = '';
  String? _currentlyLoadedUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.shouldPreload) {
      _initVideo();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_isInitialized) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller!.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _playVideo();
    }
  }

  void _onVideoControllerUpdate() {
    if (!mounted || _controller == null) return;
    final val = _controller!.value;
    final firstFrame = val.isInitialized && (val.position > Duration.zero || val.isPlaying);
    final isBuffering = val.isBuffering;
    final isPlaying = val.isPlaying;

    if (firstFrame != _isFirstFrameReady || isBuffering != _isBuffering || isPlaying != _isPlaying) {
      setState(() {
        _isFirstFrameReady = firstFrame;
        _isBuffering = isBuffering;
        _isPlaying = isPlaying;
      });
    }
  }

  Future<void> _disposeController() async {
    final oldController = _controller;
    _controller = null;
    _isInitialized = false;
    _isFirstFrameReady = false;
    _isBuffering = false;
    _isPlaying = false;
    _currentlyLoadedUrl = null;
    if (oldController != null) {
      oldController.removeListener(_onVideoControllerUpdate);
      try {
        await oldController.pause();
      } catch (_) {}
      try {
        await oldController.dispose();
      } catch (_) {}
    }
  }

  Future<void> _initVideo() async {
    final primaryUrl = widget.videoUrl?.trim();
    final fallback = widget.fallbackUrl?.trim();

    final targetUrl = (primaryUrl != null && primaryUrl.isNotEmpty)
        ? primaryUrl
        : ((fallback != null && fallback.isNotEmpty) ? fallback : null);

    if (targetUrl == null) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No video URL provided';
        });
      }
      return;
    }

    if (_controller != null && _currentlyLoadedUrl == targetUrl && _isInitialized) {
      if (widget.isActive && !_isPlaying) {
        _playVideo();
      }
      return;
    }

    await _disposeController();

    final urlsToTry = <String>[targetUrl];
    if (fallback != null && fallback.isNotEmpty && fallback != targetUrl) {
      urlsToTry.add(fallback);
    }

    for (final url in urlsToTry) {
      try {
        final controller = createVideoControllerForUrlOrPath(url);
        _controller = controller;
        await controller.initialize();
        if (!mounted) {
          controller.dispose();
          return;
        }

        await controller.setLooping(true);
        controller.addListener(_onVideoControllerUpdate);
        _currentlyLoadedUrl = url;

        if (widget.isActive) {
          await _playVideo();
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
            _errorMessage = '';
          });
        }
        return;
      } catch (_) {
        await _disposeController();
      }
    }

    if (mounted) {
      setState(() {
        _hasError = true;
        _isInitialized = false;
        _isFirstFrameReady = false;
        _errorMessage = 'Playback error';
      });
    }
  }

  Future<void> _playVideo() async {
    if (_controller == null) return;
    try {
      await _controller!.play();
      if (mounted) setState(() => _isPlaying = true);
    } catch (_) {
      try {
        await _controller!.setVolume(0.0);
        _isMuted = true;
        await _controller!.play();
        if (mounted) setState(() => _isPlaying = true);
      } catch (_) {
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_controller == null || !_isInitialized) return;
    try {
      if (_isMuted) {
        await _controller!.setVolume(1.0);
        if (mounted) setState(() => _isMuted = false);
      } else {
        await _controller!.setVolume(0.0);
        if (mounted) setState(() => _isMuted = true);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.videoUrl != oldWidget.videoUrl || widget.fallbackUrl != oldWidget.fallbackUrl) {
      if (widget.shouldPreload) {
        _initVideo();
      } else {
        _disposeController();
        if (mounted) setState(() {});
      }
      return;
    }

    if (widget.shouldPreload != oldWidget.shouldPreload) {
      if (widget.shouldPreload) {
        if (_controller == null) {
          _initVideo();
        }
      } else {
        _disposeController();
        if (mounted) setState(() {});
      }
      return;
    }

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        if (_controller != null && _isInitialized) {
          _playVideo();
        } else if (widget.shouldPreload && _controller == null) {
          _initVideo();
        }
      } else {
        _controller?.pause();
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller != null) {
      _controller!.removeListener(_onVideoControllerUpdate);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        setState(() => _isPlaying = false);
      } else {
        _playVideo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Clean solid black background for Reels (no background images behind video)
          const ColoredBox(color: Colors.black),

          // 2. Video Player with smooth fade-in once first frame is decoded
          if (_isInitialized && _controller != null)
            AnimatedOpacity(
              opacity: _isFirstFrameReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 9 / 16,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),

          // 3. Subtle Loading / Buffering Spinner
          if (widget.isActive && (!_isFirstFrameReady || _isBuffering) && !_hasError)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),

          // 4. Non-blocking error notification badge (allows swiping past without obstruction)
          if (_hasError)
            Positioned(
              top: 75,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Video unavailable',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _hasError = false;
                            _errorMessage = '';
                          });
                          _initVideo();
                        },
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: FriendLoopColors.lavender, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Play / Pause overlay indicator when paused
          if (_isInitialized && !_isPlaying && !_hasError && _isFirstFrameReady)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
              ),
            ),

          // 6. Mute indicator if web muted autoplay was triggered
          if (_isMuted && _isPlaying)
            Positioned(
              bottom: 80,
              right: 16,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_off_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReelShareBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> reel;

  const _ReelShareBottomSheet({required this.reel});

  @override
  ConsumerState<_ReelShareBottomSheet> createState() => _ReelShareBottomSheetState();
}

class _ReelShareBottomSheetState extends ConsumerState<_ReelShareBottomSheet> {
  final Set<String> _sentFriends = {};

  void _shareWithFriend(FriendItem friend, String shareUrl) {
    ref.read(chatProviderFamily(friend.friendshipId).notifier).sendMessage(
      'Check out this reel on FriendLoop! 🎬 $shareUrl',
    );
    setState(() {
      _sentFriends.add(friend.friendId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reel sent to ${friend.displayName}! 💜'),
        backgroundColor: FriendLoopColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareToWhatsApp(String shareUrl, String caption) async {
    Navigator.pop(context);
    final text = 'Watch this reel on FriendLoop! 🎬\n"$caption"\n$shareUrl';
    final whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    final webWhatsappUri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(text, subject: 'Share Reel on FriendLoop');
      }
    } catch (_) {
      try {
        await Share.share(text, subject: 'Share Reel on FriendLoop');
      } catch (_) {
        await _copyToClipboard(shareUrl, platformName: 'WhatsApp');
      }
    }
  }

  Future<void> _shareToTelegram(String shareUrl, String caption) async {
    Navigator.pop(context);
    final text = 'Watch this reel on FriendLoop! 🎬\n"$caption"';
    final tgUri = Uri.parse('tg://msg?text=${Uri.encodeComponent('$text\n$shareUrl')}');
    final webTgUri = Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(tgUri)) {
        await launchUrl(tgUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webTgUri)) {
        await launchUrl(webTgUri, mode: LaunchMode.externalApplication);
      } else {
        await Share.share('$text\n$shareUrl', subject: 'Share Reel on FriendLoop');
      }
    } catch (_) {
      try {
        await Share.share('$text\n$shareUrl', subject: 'Share Reel on FriendLoop');
      } catch (_) {
        await _copyToClipboard(shareUrl, platformName: 'Telegram');
      }
    }
  }

  Future<void> _shareToSms(String shareUrl, String caption) async {
    Navigator.pop(context);
    final text = 'Watch this reel on FriendLoop! 🎬 $shareUrl';
    final smsUri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await Share.share(text);
      }
    } catch (_) {
      try {
        await Share.share(text);
      } catch (_) {
        await _copyToClipboard(shareUrl, platformName: 'SMS');
      }
    }
  }

  Future<void> _shareToSystemShareSheet(String shareUrl, String caption) async {
    Navigator.pop(context);
    final text = 'Watch this reel on FriendLoop! 🎬\n"$caption"\n$shareUrl';
    try {
      await Share.share(text, subject: 'Share Reel on FriendLoop');
    } catch (_) {
      await _copyToClipboard(shareUrl);
    }
  }

  Future<void> _copyToClipboard(String url, {String? platformName}) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          platformName != null
              ? 'Reel link copied for $platformName! 🔗'
              : 'Reel link copied to clipboard! 🔗',
        ),
        backgroundColor: FriendLoopColors.violet,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final reelId = reel['id']?.toString() ?? '1';
    final shareUrl = 'https://friendloop.in/reels/$reelId';
    final userName = reel['user_name'] ?? 'FriendLoop Creator';
    final caption = reel['caption'] ?? 'Check out this reel on FriendLoop!';
    final thumb = reel['thumbnail_url'] ??
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80';
    final friends = ref.watch(friendsProvider).friends;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Share Reel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reel Preview Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FriendLoopColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FriendLoopColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    thumb,
                    width: 50,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 64,
                      color: FriendLoopColors.violet,
                      child: const Icon(Icons.videocam, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shareUrl,
                        style: const TextStyle(fontSize: 11, color: FriendLoopColors.violet, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Send to FriendLoop Friends Section
          if (friends.isNotEmpty) ...[
            const Text(
              'Send to Friends',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (ctx, idx) {
                  final friend = friends[idx];
                  final isSent = _sentFriends.contains(friend.friendId);
                  final avatarUrl = friend.images.isNotEmpty ? friend.images.first : friend.avatarUrl;

                  return Padding(
                    padding: const EdgeInsets.only(right: 14.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _shareWithFriend(friend, shareUrl),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                backgroundColor: FriendLoopColors.lavender,
                                child: avatarUrl == null ? const Icon(Icons.person, color: FriendLoopColors.plum) : null,
                              ),
                              if (isSent)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: FriendLoopColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 58,
                          child: Text(
                            friend.displayName.split(' ').first,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _shareWithFriend(friend, shareUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSent ? Colors.grey.shade300 : FriendLoopColors.violet,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isSent ? 'Sent' : 'Send',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSent ? Colors.black54 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Share Options Row
          const Text(
            'Share via',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSharePlatformButton(
                icon: Icons.link_rounded,
                label: 'Copy Link',
                color: FriendLoopColors.violet,
                onTap: () => _copyToClipboard(shareUrl),
              ),
              _buildSharePlatformButton(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _shareToWhatsApp(shareUrl, caption),
              ),
              _buildSharePlatformButton(
                icon: Icons.send_rounded,
                label: 'Telegram',
                color: const Color(0xFF0088CC),
                onTap: () => _shareToTelegram(shareUrl, caption),
              ),
              _buildSharePlatformButton(
                icon: Icons.message_outlined,
                label: 'SMS',
                color: const Color(0xFF34B7F1),
                onTap: () => _shareToSms(shareUrl, caption),
              ),
              _buildSharePlatformButton(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                color: Colors.grey.shade700,
                onTap: () => _shareToSystemShareSheet(shareUrl, caption),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSharePlatformButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
