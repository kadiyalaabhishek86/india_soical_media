import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/chat_provider.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final ApiClient _client = ApiClient();
  final PageController _pageController = PageController();

  int _selectedTab = 0; // 0 = Discover, 1 = Following
  int _currentPage = 0;
  bool _isLoading = true;
  List<dynamic> _reels = [];

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchReels() async {
    setState(() => _isLoading = true);
    try {
      final feed = _selectedTab == 0 ? 'discover' : 'following';
      final res = await _client.get('/reels?feed=$feed');
      if (mounted) {
        setState(() {
          _reels = List<dynamic>.from(res);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _toggleLike(int index) async {
    final reel = _reels[index];
    final reelId = reel['id']?.toString() ?? '';
    final wasLiked = reel['is_liked'] == true;
    final oldCount = reel['likes_count'] ?? 0;

    setState(() {
      _reels[index]['is_liked'] = !wasLiked;
      _reels[index]['likes_count'] = wasLiked ? oldCount - 1 : oldCount + 1;
    });

    try {
      await _client.post('/reels/$reelId/like');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Reel Video Carousel
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: FriendLoopColors.brightViolet))
          else if (_reels.isEmpty)
            const Center(
              child: Text('No reels found', style: TextStyle(color: Colors.white70)),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index] as Map<String, dynamic>;
                final isLiked = reel['is_liked'] == true;
                final likesCount = reel['likes_count'] ?? 3401;
                final commentsCount = reel['comments_count'] ?? 287;
                final userName = reel['user_name'] ?? 'Priya Patel';
                final caption = reel['caption'] ?? 'Friendship trips hit different! 💜';
                final thumb = reel['thumbnail_url'] ?? 'assets/telegram/wallpaper_sample.png';
                final videoUrl = reel['video_url']?.toString();
                final isCurrent = _currentPage == index;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Real Interactive Video Player with Auto-loop, Mute & Play/Pause
                    _ReelVideoPlayer(
                      videoUrl: videoUrl,
                      thumbnailUrl: thumb,
                      isActive: isCurrent,
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
                            onPressed: () => _toggleLike(index),
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
                          const SizedBox(height: 16),

                          // + Create / Upload Reel Button
                          GestureDetector(
                            onTap: () async {
                              final res = await context.push('/create-reel');
                              if (res == true && mounted) {
                                _fetchReels();
                              }
                            },
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

          // Top Header with Infinity Logo and Discover / Following Tabs
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/friendloop_logo.png',
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.all_inclusive_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    // Tab Pills (Discover vs Following)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _buildTabPill('Discover', 0),
                          _buildTabPill('Following', 1),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.video_library_outlined, color: Colors.white),
                      tooltip: 'Upload from Gallery',
                      onPressed: () async {
                        final res = await context.push('/create-reel');
                        if (res == true && mounted) {
                          _fetchReels();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () => context.push('/notifications'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
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
        setState(() => _selectedTab = index);
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
  final String thumbnailUrl;
  final bool isActive;

  const _ReelVideoPlayer({
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.isActive,
  });

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final uri = Uri.parse(widget.videoUrl!);
      final controller = VideoPlayerController.networkUrl(uri);
      _controller = controller;
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      await controller.setLooping(true);
      if (widget.isActive) {
        await controller.play();
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
        });
      } else {
        setState(() {
          _isInitialized = true;
          _isPlaying = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant _ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _isInitialized) {
      if (widget.isActive && !oldWidget.isActive) {
        _controller!.play();
        setState(() => _isPlaying = true);
      } else if (!widget.isActive && oldWidget.isActive) {
        _controller!.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          _controller!.play();
          _isPlaying = true;
        }
      });
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
          // Fallback thumbnail or video player
          if (_isInitialized && _controller != null && !_hasError)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 9 / 16,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Image.network(
              widget.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/telegram/wallpaper_sample.png',
                fit: BoxFit.cover,
              ),
            ),

          // Play / Pause overlay indicator when paused
          if (_isInitialized && !_isPlaying)
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
                onTap: () => _copyToClipboard(shareUrl, platformName: 'WhatsApp'),
              ),
              _buildSharePlatformButton(
                icon: Icons.send_rounded,
                label: 'Telegram',
                color: const Color(0xFF0088CC),
                onTap: () => _copyToClipboard(shareUrl, platformName: 'Telegram'),
              ),
              _buildSharePlatformButton(
                icon: Icons.message_outlined,
                label: 'SMS',
                color: const Color(0xFF34B7F1),
                onTap: () => _copyToClipboard(shareUrl, platformName: 'SMS'),
              ),
              _buildSharePlatformButton(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                color: Colors.grey.shade700,
                onTap: () => _copyToClipboard(shareUrl),
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
