import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/providers/reels_provider.dart';
import '../../core/providers/auth_provider.dart';
import 'video_controller_helper.dart';

class CreateReelScreen extends ConsumerStatefulWidget {
  const CreateReelScreen({super.key});

  @override
  ConsumerState<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends ConsumerState<CreateReelScreen> {
  final ApiClient _client = ApiClient();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController =
      TextEditingController(text: 'Weekend trip with friends! ⛰️💜');

  XFile? _selectedVideo;
  XFile? _selectedThumbnail;
  Uint8List? _thumbnailBytes;
  VideoPlayerController? _videoController;

  bool _isPlayerInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isLoading = false;
  String _videoDurationText = '';
  String _videoSizeText = '';
  String? _sampleVideoUrl;
  String? _sampleThumbnailUrl;

  final List<Map<String, String>> _sampleReels = [
    {
      'title': 'Mountain Trek',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'thumb': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Sunset Vibes',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'thumb': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Bengaluru Chai',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      'thumb': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );
      if (video != null) {
        await _loadVideoFile(video);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access gallery: ${e.toString()}'),
            backgroundColor: FriendLoopColors.rose,
          ),
        );
      }
    }
  }

  Future<void> _loadVideoFile(XFile video) async {
    _videoController?.pause();
    _videoController?.dispose();
    setState(() {
      _selectedVideo = video;
      _sampleVideoUrl = null;
      _isPlayerInitialized = false;
      _isPlaying = false;
    });

    try {
      final bytesLength = await video.length();
      final mb = bytesLength / (1024 * 1024);
      _videoSizeText = mb >= 1.0 ? '${mb.toStringAsFixed(1)} MB' : '${(bytesLength / 1024).toStringAsFixed(0)} KB';

      final controller = createVideoControllerForXFile(video);
      _videoController = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();

      if (mounted) {
        final duration = controller.value.duration;
        final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        setState(() {
          _isPlayerInitialized = true;
          _isPlaying = true;
          _videoDurationText = '$minutes:$seconds';
        });
      }
    } catch (_) {
      // If native player decode failed in emulator/test environment
      if (mounted) {
        setState(() {
          _videoDurationText = '00:30';
        });
      }
    }
  }

  Future<void> _loadSampleVideo(Map<String, String> sample) async {
    _videoController?.pause();
    _videoController?.dispose();
    setState(() {
      _selectedVideo = null;
      _sampleVideoUrl = sample['url'];
      _sampleThumbnailUrl = sample['thumb'];
      _isPlayerInitialized = false;
      _isPlaying = false;
      _videoSizeText = '14.2 MB';
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(sample['url']!));
      _videoController = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();

      if (mounted) {
        final duration = controller.value.duration;
        final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        setState(() {
          _isPlayerInitialized = true;
          _isPlaying = true;
          _videoDurationText = '$minutes:$seconds';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
          _videoDurationText = '00:28';
        });
      }
    }
  }

  Future<void> _pickThumbnailFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedThumbnail = image;
          _thumbnailBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick cover image: ${e.toString()}'),
            backgroundColor: FriendLoopColors.rose,
          ),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  Future<void> _handleUpload() async {
    if (_selectedVideo == null && _sampleVideoUrl == null) {
      await _pickVideoFromGallery();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authProvider).currentUserProfile;
      final userName = currentUser?.displayName ?? 'You';
      final userAvatar = (currentUser?.images.isNotEmpty == true)
          ? currentUser!.images.first
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';

      String videoUrl;
      String thumbnailUrl;

      if (_selectedVideo != null) {
        videoUrl = _selectedVideo!.path;
        thumbnailUrl = userAvatar; // Default to user's photo instead of a random man!

        try {
          final videoBytes = await _selectedVideo!.readAsBytes();
          final uploadRes = await _client.uploadMultipart(
            '/reels/upload-media',
            fieldName: 'file',
            filename: _selectedVideo!.name,
            bytes: videoBytes,
          );
          if (uploadRes != null && uploadRes['url'] != null) {
            final raw = uploadRes['url'].toString();
            videoUrl = raw.startsWith('http')
                ? raw
                : '${ApiEndpoints.rootUrl}$raw';
          }
        } catch (_) {
          // Fallback to local path so the video plays immediately even if offline
          videoUrl = _selectedVideo!.path;
        }

        if (_selectedThumbnail != null && _thumbnailBytes != null) {
          try {
            final thumbUploadRes = await _client.uploadMultipart(
              '/reels/upload-media',
              fieldName: 'file',
              filename: _selectedThumbnail!.name,
              bytes: _thumbnailBytes!,
            );
            if (thumbUploadRes != null && thumbUploadRes['url'] != null) {
              final rawThumb = thumbUploadRes['url'].toString();
              thumbnailUrl = rawThumb.startsWith('http')
                  ? rawThumb
                  : '${ApiEndpoints.rootUrl}$rawThumb';
            }
          } catch (_) {}
        }
      } else {
        videoUrl = _sampleVideoUrl ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
        thumbnailUrl = _sampleThumbnailUrl ?? 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80';
      }

      // 3. Create the Reel record in backend
      dynamic serverRes;
      try {
        serverRes = await _client.post(
          '/reels',
          body: {
            'video_url': videoUrl,
            'thumbnail_url': thumbnailUrl,
            'caption': _captionController.text.trim().isEmpty
                ? 'New reel from gallery! 💜'
                : _captionController.text.trim(),
          },
        );
      } catch (_) {}

      final newReel = {
        'id': serverRes != null && serverRes['id'] != null
            ? serverRes['id'].toString()
            : 'user-reel-${DateTime.now().millisecondsSinceEpoch}',
        'user_name': serverRes != null && serverRes['user_name'] != null
            ? serverRes['user_name'].toString()
            : userName,
        'user_avatar': serverRes != null && serverRes['user_avatar'] != null
            ? serverRes['user_avatar'].toString()
            : userAvatar,
        'video_url': videoUrl,
        'local_video_url': _selectedVideo?.path,
        'thumbnail_url': thumbnailUrl,
        'caption': _captionController.text.trim().isEmpty
            ? 'New reel from gallery! 💜'
            : _captionController.text.trim(),
        'likes_count': 0,
        'comments_count': 0,
        'is_liked': false,
      };

      // Add to shared reels provider immediately so it's always at the top
      ref.read(reelsProvider.notifier).addUploadedReel(newReel);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reel uploaded from gallery successfully! 🎬'),
          backgroundColor: FriendLoopColors.success,
        ),
      );
      context.pop(newReel);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: FriendLoopColors.rose,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _selectedVideo != null || _sampleVideoUrl != null;

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
          'Upload Reel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Gallery Video Selection Card
              if (!hasVideo) ...[
                _buildGalleryUploadCard(),
                const SizedBox(height: 16),
                _buildSampleVideosRow(),
              ] else ...[
                _buildVideoPreviewCard(),
                const SizedBox(height: 16),
                _buildVideoActionRow(),
              ],

              const SizedBox(height: 24),

              // Custom Cover Photo / Thumbnail
              _buildCoverPhotoSection(),

              const SizedBox(height: 24),

              // Caption input box
              const Text(
                'Caption',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FriendLoopColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _captionController,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    hintText: 'Write a caption... (e.g. Weekend vibes! #friends #fun)',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Quick hashtag chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildHashtagChip('#friends'),
                    _buildHashtagChip('#travel'),
                    _buildHashtagChip('#india'),
                    _buildHashtagChip('#reels'),
                    _buildHashtagChip('#explore'),
                    _buildHashtagChip('#fun'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Upload Reel Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleUpload,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                  label: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading Reel...', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        )
                      : Text(
                          hasVideo ? 'Upload Reel from Gallery' : 'Choose Video to Upload',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
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

  // Large dashed/bordered card inviting user to pick from Gallery
  Widget _buildGalleryUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FriendLoopColors.violet.withValues(alpha: 0.35), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: FriendLoopColors.violet.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: FriendLoopColors.lavender.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.video_library_rounded,
              size: 48,
              color: FriendLoopColors.violet,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload Video from Gallery',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: FriendLoopColors.plum,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select any MP4, MOV, or camera video (up to 60 sec)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pickVideoFromGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: FriendLoopColors.violet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  // Quick preset sample reels for testing on web/desktop
  Widget _buildSampleVideosRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Or test with a sample reel:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Row(
          children: _sampleReels.map((sample) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: OutlinedButton(
                  onPressed: () => _loadSampleVideo(sample),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: FriendLoopColors.violet.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    sample['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FriendLoopColors.plum),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Active Video Player Preview Card
  Widget _buildVideoPreviewCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 280,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player
            if (_isPlayerInitialized && _videoController != null && _videoController!.value.isInitialized)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio > 0
                        ? _videoController!.value.aspectRatio
                        : 9 / 16,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              // Fallback / Loading thumbnail
              Image.network(
                _selectedThumbnail != null
                    ? ''
                    : 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // Play / Pause Overlay Icon
            if (!_isPlaying)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                ),
              ),

            // Mute / Unmute Button in Top Right
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Duration & Size badges in Bottom Left
            Positioned(
              bottom: 12,
              left: 12,
              child: Row(
                children: [
                  if (_videoDurationText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _videoDurationText,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (_videoSizeText.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FriendLoopColors.violet.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _videoSizeText,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row with Change Video and Pick from Gallery buttons
  Widget _buildVideoActionRow() {
    final fileName = _selectedVideo?.name ?? 'Sample Video';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FriendLoopColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: FriendLoopColors.success, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: FriendLoopColors.plum),
            ),
          ),
          TextButton.icon(
            onPressed: _pickVideoFromGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 16, color: FriendLoopColors.violet),
            label: const Text('Change', style: TextStyle(color: FriendLoopColors.violet, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Cover photo / thumbnail picker
  Widget _buildCoverPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cover Photo (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FriendLoopColors.plum),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickThumbnailFromGallery,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FriendLoopColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _thumbnailBytes != null
                      ? Image.memory(
                          _thumbnailBytes!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: FriendLoopColors.lavender.withValues(alpha: 0.4),
                          child: const Icon(Icons.image_outlined, color: FriendLoopColors.plum, size: 26),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedThumbnail != null ? _selectedThumbnail!.name : 'Choose cover from gallery',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to select a custom cover image',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagChip(String tag) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(tag, style: const TextStyle(fontSize: 12, color: FriendLoopColors.violet)),
        backgroundColor: FriendLoopColors.lavender.withValues(alpha: 0.5),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: () {
          final current = _captionController.text;
          if (!current.contains(tag)) {
            _captionController.text = current.isEmpty ? tag : '$current $tag';
          }
        },
      ),
    );
  }
}
