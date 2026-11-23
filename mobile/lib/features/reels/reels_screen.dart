import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final ApiClient _client = ApiClient();
  final PageController _pageController = PageController();

  int _selectedTab = 0; // 0 = Discover, 1 = Following
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
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index] as Map<String, dynamic>;
                final isLiked = reel['is_liked'] == true;
                final likesCount = reel['likes_count'] ?? 3400;
                final commentsCount = reel['comments_count'] ?? 286;
                final userName = reel['user_name'] ?? 'Aditi Sharma';
                final caption = reel['caption'] ?? 'Friendship trips hit different! 💜';
                final thumb = reel['thumbnail_url'] ?? 'assets/telegram/wallpaper_sample.png';

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video Background Thumbnail
                    Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/telegram/wallpaper_sample.png',
                        fit: BoxFit.cover,
                      ),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reel link copied to clipboard!')),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // + Create Reel Button
                          GestureDetector(
                            onTap: () => context.push('/create-reel'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: FriendLoopColors.violet,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.add, color: Colors.white, size: 20),
                                  Text(
                                    'Create\nReel',
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
