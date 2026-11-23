import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ApiClient _client = ApiClient();
  int _selectedGalleryTab = 0; // 0 = Photos, 1 = Videos
  late final PageController _heroPageController;
  Timer? _autoScrollTimer;
  int _currentHeroIndex = 0;

  final List<String> _galleryPhotos = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1511884642898-4c92249e20b6?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1439853941329-a99ce0435c81?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=800&q=80',
  ];

  final List<String> _galleryVideos = [
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_heroPageController.hasClients) return;
      final next = (_currentHeroIndex + 1) % 3;
      _heroPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo captured from live camera! 📸'), backgroundColor: FriendLoopColors.success),
        );
      }
    } catch (_) {}
  }

  Future<void> _openGalleryUploadSheet() async {
    final captionCtrl = TextEditingController(text: 'Trekking in the Himalayas ⛰️');
    int mediaType = 0; // 0 = Photo, 1 = Video
    String access = 'Plus members only';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload to My Gallery',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Upload a file', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setModalState(() => mediaType = 0),
                          icon: const Icon(Icons.photo_outlined),
                          label: const Text('Photo'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: mediaType == 0 ? FriendLoopColors.lavender : Colors.white,
                            side: BorderSide(color: mediaType == 0 ? FriendLoopColors.violet : FriendLoopColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setModalState(() => mediaType = 1),
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('Video'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: mediaType == 1 ? FriendLoopColors.lavender : Colors.white,
                            side: BorderSide(color: mediaType == 1 ? FriendLoopColors.violet : FriendLoopColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Media Preview Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Caption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: captionCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FriendLoopColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: access,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Plus members only', child: Text('🔒 Plus members only')),
                          DropdownMenuItem(value: 'Public', child: Text('🌐 Public')),
                        ],
                        onChanged: (v) => setModalState(() => access = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: FriendLoopColors.textMuted),
                      SizedBox(width: 6),
                      Text('Your profile photo and bio stay public', style: TextStyle(fontSize: 12, color: FriendLoopColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _galleryPhotos.insert(0, 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80');
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Published to your gallery! 📷'), backgroundColor: FriendLoopColors.success),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.violet),
                      child: const Text('Publish to gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUserProfile;
    final displayName = user?.displayName ?? 'Ananya Sharma';
    final bio = user?.lookingFor ?? 'Travel lover, hiker and photographer. Sharing my journeys here.';
    final isPlus = user?.isPlusSubscriber ?? false;
    final coins = user?.coins ?? 120;

    final heroImages = (user?.images != null && user!.images.isNotEmpty)
        ? user.images
        : const [
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
          ];

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined, color: FriendLoopColors.violet),
            tooltip: 'Live Camera',
            onPressed: _openCamera,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: FriendLoopColors.plum),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Photo Horizontal Carousel (Auto-scrolls without buttons)
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _heroPageController,
                        itemCount: heroImages.length,
                        onPageChanged: (idx) => setState(() => _currentHeroIndex = idx),
                        itemBuilder: (ctx, idx) {
                          return Image.network(
                            heroImages[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset('assets/telegram/wallpaper_sample.png', fit: BoxFit.cover),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Name & Status
                      Positioned(
                        bottom: 14,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                                if (isPlus) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FriendLoopColors.brightViolet,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('PLUS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text('last seen recently', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bio Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(bio, style: const TextStyle(fontSize: 14, color: FriendLoopColors.plum, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons Row (Wallet & Plus)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/wallet'),
                      icon: const Text('🪙'),
                      label: Text('$coins Coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: FriendLoopColors.violet),
                        foregroundColor: FriendLoopColors.violet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/plus'),
                      icon: const Icon(Icons.star, color: Colors.white, size: 18),
                      label: Text(isPlus ? 'Plus Active' : 'Get Plus', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FriendLoopColors.plum,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // My Gallery Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Gallery',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: FriendLoopColors.plum),
                  ),
                  // Tabs: Photos / Videos
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FriendLoopColors.border),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedGalleryTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedGalleryTab == 0 ? FriendLoopColors.lavender : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedGalleryTab == 0 ? FontWeight.bold : FontWeight.normal,
                                color: _selectedGalleryTab == 0 ? FriendLoopColors.violet : FriendLoopColors.plum,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedGalleryTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedGalleryTab == 1 ? FriendLoopColors.lavender : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Videos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedGalleryTab == 1 ? FontWeight.bold : FontWeight.normal,
                                color: _selectedGalleryTab == 1 ? FriendLoopColors.violet : FriendLoopColors.plum,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4-grid Gallery Tiles
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _selectedGalleryTab == 0 ? _galleryPhotos.length : _galleryVideos.length,
                itemBuilder: (ctx, idx) {
                  final url = _selectedGalleryTab == 0 ? _galleryPhotos[idx] : _galleryVideos[idx];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(url, fit: BoxFit.cover),
                        if (_selectedGalleryTab == 1)
                          const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // + Upload photo or video Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openGalleryUploadSheet,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Upload photo or video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Plus banner card
              GestureDetector(
                onTap: () => context.push('/plus'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FriendLoopColors.lavender),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.all_inclusive, color: FriendLoopColors.violet, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Plus • ₹350/month',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: FriendLoopColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
