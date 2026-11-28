import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/chats_inbox_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/coin_billing.dart';

class PrivateChatScreen extends ConsumerStatefulWidget {
  final String friendshipId;
  final FriendItem? friendInfo;

  const PrivateChatScreen({
    super.key,
    required this.friendshipId,
    this.friendInfo,
  });

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasNow = _messageController.text.trim().isNotEmpty;
      if (hasNow != _hasText) {
        setState(() => _hasText = hasNow);
      }
    });

    // Mark messages as read as soon as user opens this chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatsInboxProvider.notifier).markAsRead(
        widget.friendshipId,
        widget.friendInfo?.displayName,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend([String? customText]) async {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    final userCoins = ref.read(authProvider).currentUserProfile?.coins ?? 120;
    if (userCoins < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient coins to send message (2 coins required, you have $userCoins). Please recharge.'),
          backgroundColor: FriendLoopColors.plum,
          duration: const Duration(seconds: 2),
        ),
      );
      context.push('/wallet');
      return;
    }
    ref.read(authProvider.notifier).updateCoins(userCoins - 2);

    if (customText == null) {
      _messageController.clear();
      setState(() => _hasText = false);
    }

    try {
      await ref.read(chatProviderFamily(widget.friendshipId).notifier).sendMessage(text);
      ref.read(chatsInboxProvider.notifier).updateLastMessage(
        widget.friendshipId,
        text,
        isOutgoing: true,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {}
  }

  // Pick and upload image directly in friends chat
  Future<void> _pickAndUploadImage(BuildContext context, [ImageSource source = ImageSource.gallery]) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await ref.read(chatProviderFamily(widget.friendshipId).notifier).sendMediaMessage(
          type: 'image',
          mediaUrl: base64String,
          caption: 'Photo',
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not attach image: ${e.toString()}')),
      );
    }
  }

  // Pick and upload video directly in friends chat
  Future<void> _pickAndUploadVideo(BuildContext context, [ImageSource source = ImageSource.gallery]) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );

      if (file != null) {
        final path = file.path;
        await ref.read(chatProviderFamily(widget.friendshipId).notifier).sendMediaMessage(
          type: 'video',
          mediaUrl: path,
          caption: 'Video Clip (0:30)',
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not attach video: ${e.toString()}')),
      );
    }
  }

  // Send sample image preset for instant testing
  void _sendSampleImage(String url, String title) {
    ref.read(chatProviderFamily(widget.friendshipId).notifier).sendMediaMessage(
      type: 'image',
      mediaUrl: url,
      caption: title,
    );
    _scrollToBottom();
  }

  // Send sample video preset for instant testing
  void _sendSampleVideo(String title) {
    ref.read(chatProviderFamily(widget.friendshipId).notifier).sendMediaMessage(
      type: 'video',
      mediaUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      caption: title,
    );
    _scrollToBottom();
  }

  // Screen 3: Call Request Chooser (matching FriendLoop mockup)
  void _showCallChooser(BuildContext context, FriendItem? friend, {bool preselectVideo = false}) {
    String selectedMode = preselectVideo ? 'video' : 'voice';
    final avatarUrl = (friend != null && friend.images.isNotEmpty)
        ? friend.images.first
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
    final friendName = friend?.displayName ?? 'Priya Sharma';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: FriendLoopColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Back button & Infinity Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                      Image.asset(
                        'assets/images/friendloop_logo.png',
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.all_inclusive_rounded,
                          size: 24,
                          color: FriendLoopColors.violet,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance leading icon
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title: Start a private call with Priya Sharma
                  Text(
                    'Start a private call with $friendName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Large Avatar with Online Indicator
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage(avatarUrl),
                          onBackgroundImageError: (_, __) {},
                          child: const Icon(Icons.person, size: 46, color: FriendLoopColors.plum),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: FriendLoopColors.onlineGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Option 1: Voice Call (10 coins/min)
                  _buildCallOptionCard(
                    title: 'Voice Call',
                    subtitle: '10 coins/min',
                    icon: Icons.phone_outlined,
                    isSelected: selectedMode == 'voice',
                    onTap: () => setModalState(() => selectedMode = 'voice'),
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Video Call (40 coins/min)
                  _buildCallOptionCard(
                    title: 'Video Call',
                    subtitle: '40 coins/min',
                    icon: Icons.videocam_outlined,
                    isSelected: selectedMode == 'video',
                    onTap: () => setModalState(() => selectedMode = 'video'),
                  ),
                  const SizedBox(height: 20),

                  // "Request Call" purple CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FriendLoopColors.violet,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(modalContext);
                        if (selectedMode == 'video') {
                          if (!CoinBilling.checkAndDeductForAction(
                            context: context,
                            ref: ref,
                            actionType: CoinActionType.video,
                            friend: friend,
                          )) {
                            return;
                          }
                          context.push('/call/video', extra: friend);
                        } else {
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
                      },
                      child: const Text(
                        'Request Call',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCallOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? FriendLoopColors.lavender.withValues(alpha: 0.35) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FriendLoopColors.lavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: FriendLoopColors.violet, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: FriendLoopColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              activeColor: FriendLoopColors.violet,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  // Screen 4: Incoming Video Call (matching FriendLoop mockup)
  void _showIncomingVideoCallOverlay(BuildContext context, FriendItem? friend) {
    final avatarUrl = (friend != null && friend.images.isNotEmpty)
        ? friend.images.first
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
    final friendName = friend?.displayName ?? 'Priya Sharma';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (ctx, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full-screen background image of caller
              Positioned.fill(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: FriendLoopColors.plumDark),
                ),
              ),

              // Dark overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // Top details: Infinity Logo, "Incoming Video Call", Caller Name
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/friendloop_logo.png',
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.all_inclusive_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Incoming Video Call',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          friendName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Actions: Decline (Red) and Accept (Purple)
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Call declined')),
                            );
                          },
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Decline',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    // Accept Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showActiveVideoCallOverlay(context, friend);
                          },
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: FriendLoopColors.violet,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam, color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Screen 5: Active Video Call (matching FriendLoop mockup)
  void _showActiveVideoCallOverlay(BuildContext context, FriendItem? friend) {
    final avatarUrl = (friend != null && friend.images.isNotEmpty)
        ? friend.images.first
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
    bool isMuted = false;
    bool isCameraOff = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (ctx, anim1, anim2) {
        return StatefulBuilder(
          builder: (callContext, setCallState) {
            return Scaffold(
              backgroundColor: const Color(0xFF101418),
              body: Stack(
                children: [
                  // Full-screen Friend Video Feed
                  Positioned.fill(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: FriendLoopColors.plumDark),
                    ),
                  ),

                  // Floating PiP preview of self (Top Right)
                  Positioned(
                    top: 50,
                    right: 18,
                    child: Container(
                      width: 90,
                      height: 125,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E50),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.person, color: Colors.white70, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top Header: Center Infinity Logo & Timer Pill (02:16)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/friendloop_logo.png',
                              height: 24,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.all_inclusive_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '02:16',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Controls: Mic, Camera, End Call
                  Positioned(
                    bottom: 36,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mic Button
                        _buildCallRoundBtn(
                          icon: isMuted ? Icons.mic_off : Icons.mic,
                          color: isMuted ? FriendLoopColors.rose : Colors.white24,
                          iconColor: Colors.white,
                          onTap: () => setCallState(() => isMuted = !isMuted),
                        ),

                        // Camera Button
                        _buildCallRoundBtn(
                          icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
                          color: isCameraOff ? FriendLoopColors.rose : Colors.white24,
                          iconColor: Colors.white,
                          onTap: () => setCallState(() => isCameraOff = !isCameraOff),
                        ),

                        // Red End Call Button
                        _buildCallRoundBtn(
                          icon: Icons.call_end,
                          color: const Color(0xFFE53935),
                          iconColor: Colors.white,
                          onTap: () {
                            Navigator.pop(callContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Video call ended')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCallRoundBtn({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProviderFamily(widget.friendshipId));
    final currentUserId = ref.watch(authProvider).currentUserProfile?.id ?? 'me';
    final friend = widget.friendInfo;

    // Current messages from state with persistent starter conversation fallback
    final effectiveMessages = chatState.messages.isNotEmpty
        ? chatState.messages
        : getInitialStarterMessages(widget.friendshipId);

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas, // Soft FriendLoop lilac canvas #F4EBFC
      appBar: _buildAppBar(context, friend),
      body: Stack(
        children: [
          // 1. Chat messages and input bar
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: effectiveMessages.length,
                    itemBuilder: (context, index) {
                      final msg = effectiveMessages[index];
                      final isMe = msg.senderId == currentUserId || msg.senderId == 'me';
                      return _buildFriendLoopMessageBubble(msg, isMe, friend);
                    },
                  ),
                ),

                // Coin notice banner right above input bar (matching Screen 2, taps to wallet)
                GestureDetector(
                  onTap: () => context.push('/wallet'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: FriendLoopColors.lavender.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: FriendLoopColors.lavender),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🪙 ', style: TextStyle(fontSize: 13)),
                        Text(
                          'Calls use coins from your balance.',
                          style: TextStyle(
                            color: FriendLoopColors.plum,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Chat Input Bar with Image & Video Upload
                _buildBottomInputBar(context),
              ],
            ),
          ),

          // 2. Floating Pop-up Menu
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _isMenuOpen = false),
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: _buildTelegramPopupMenu(context, friend),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Top AppBar matching Screen 2 (Clean back, Avatar with Online dot, Phone & Video icons)
  PreferredSizeWidget _buildAppBar(BuildContext context, FriendItem? friend) {
    final avatarUrl = (friend != null && friend.images.isNotEmpty)
        ? friend.images.first
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
    final friendName = friend?.displayName ?? 'Priya Sharma';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          // Friend Avatar with Online Dot
          Stack(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundImage: NetworkImage(avatarUrl),
                onBackgroundImageError: (_, __) {},
                child: const Icon(Icons.person, size: 18, color: FriendLoopColors.plum),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: FriendLoopColors.onlineGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendName,
                  style: const TextStyle(
                    color: FriendLoopColors.plum,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: FriendLoopColors.onlineGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: FriendLoopColors.onlineGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Voice Call Icon (Phone) -> opens Screen 3 Call Request Chooser
        IconButton(
          icon: const Icon(Icons.phone_outlined, color: FriendLoopColors.violet, size: 22),
          tooltip: 'Voice Call',
          onPressed: () => _showCallChooser(context, friend, preselectVideo: false),
        ),

        // Video Call Icon -> opens Screen 3 Call Request Chooser
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: FriendLoopColors.violet, size: 24),
          tooltip: 'Video Call',
          onPressed: () => _showCallChooser(context, friend, preselectVideo: true),
        ),

        // More Options (3 dots)
        IconButton(
          icon: const Icon(Icons.more_vert, color: FriendLoopColors.plum, size: 24),
          onPressed: () {
            setState(() {
              _isMenuOpen = !_isMenuOpen;
            });
          },
        ),
      ],
    );
  }

  // FriendLoop message bubbles matching Screen 2
  Widget _buildFriendLoopMessageBubble(ChatMessage msg, bool isMe, FriendItem? friend) {
    final isMedia = msg.messageType == 'image' || msg.messageType == 'video';
    final avatarUrl = (friend != null && friend.images.isNotEmpty)
        ? friend.images.first
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';

    if (isMe) {
      // Outgoing bubble (Solid purple #6E13D8, white text, white checkmarks)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: isMedia
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: const BoxDecoration(
              color: FriendLoopColors.violet,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (msg.messageType == 'image')
                  _buildImageMessageContent(msg)
                else if (msg.messageType == 'video')
                  _buildVideoMessageContent(msg)
                else
                  Text(
                    msg.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.25,
                    ),
                  ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMsgTime(msg.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Incoming bubble (Avatar on left, clean white bubble, dark text)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(avatarUrl),
              onBackgroundImageError: (_, __) {},
              child: const Icon(Icons.person, size: 14, color: FriendLoopColors.plum),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: isMedia
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FriendLoopColors.plum.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.messageType == 'image')
                      _buildImageMessageContent(msg)
                    else if (msg.messageType == 'video')
                      _buildVideoMessageContent(msg)
                    else
                      Text(
                        msg.content,
                        style: const TextStyle(
                          color: Color(0xFF1E232A),
                          fontSize: 14.5,
                          height: 1.25,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatMsgTime(msg.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 10.5,
                        ),
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
  }

  // Image Message Bubble Content
  Widget _buildImageMessageContent(ChatMessage msg) {
    final media = msg.mediaUrl ?? msg.content.replaceFirst('[IMAGE]', '').trim();

    return GestureDetector(
      onTap: () => _showFullscreenImage(context, media),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            if (media.startsWith('data:image'))
              Image.memory(
                base64Decode(media.substring(media.indexOf(',') + 1)),
                width: 220,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _mediaPlaceholder(Icons.broken_image, 'Photo unavailable'),
              )
            else if (media.startsWith('assets/'))
              Image.asset(
                media,
                width: 220,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _mediaPlaceholder(Icons.broken_image, 'Photo unavailable'),
              )
            else
              Image.network(
                media,
                width: 220,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _mediaPlaceholder(Icons.image, 'Photo Preview'),
              ),
          ],
        ),
      ),
    );
  }

  // Video Message Bubble Content
  Widget _buildVideoMessageContent(ChatMessage msg) {
    return GestureDetector(
      onTap: () => _playVideoModal(context, msg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 220,
          height: 140,
          color: const Color(0xFF1E2832),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.videocam, color: Colors.white24, size: 64),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.videocam, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('0:30', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaPlaceholder(IconData icon, String label) {
    return Container(
      width: 220,
      height: 140,
      color: const Color(0xFFF1F3F4),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8E8E93), size: 32),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String media) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: media.startsWith('data:image')
                  ? Image.memory(base64Decode(media.substring(media.indexOf(',') + 1)), fit: BoxFit.contain)
                  : media.startsWith('assets/')
                      ? Image.asset(media, fit: BoxFit.contain)
                      : Image.network(media, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _playVideoModal(BuildContext context, ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101418),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 54),
                  CircularProgressIndicator(color: Color(0xFF2481CC)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Playing Video Message',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Duration: 0:30 • High Definition Audio',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2481CC)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close Player', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMsgTime(String createdAt) {
    if (createdAt.length >= 5 && createdAt.contains(':')) {
      final parts = createdAt.split('T');
      if (parts.length > 1) {
        return parts[1].substring(0, 5);
      }
      return createdAt.substring(0, 5);
    }
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  // FriendLoop Bottom Input Bar matching Screen 2 (Emoji, Type a message..., Mic, Image, Purple send button)
  Widget _buildBottomInputBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: FriendLoopColors.border),
        boxShadow: [
          BoxShadow(
            color: FriendLoopColors.plum.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji Button
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt_outlined, color: FriendLoopColors.plum, size: 23),
            onPressed: () {
              _messageController.text += ' 😊 ';
            },
          ),

          // Message input field
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: FriendLoopColors.plum, fontSize: 15),
              cursorColor: FriendLoopColors.violet,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: FriendLoopColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),

          // Mic button
          IconButton(
            icon: const Icon(Icons.mic_none_outlined, color: FriendLoopColors.plum, size: 22),
            tooltip: 'Voice message',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hold to record voice message'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          // Gallery Image Button (tap to upload image, hold for attachment options)
          GestureDetector(
            onLongPress: () => _showAttachmentModal(context),
            child: IconButton(
              icon: const Icon(Icons.image_outlined, color: FriendLoopColors.plum, size: 22),
              tooltip: 'Upload Image',
              onPressed: () => _pickAndUploadImage(context),
            ),
          ),

          // Round Purple Send Button
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: FriendLoopColors.violet,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => _handleSend(),
            ),
          ),
        ],
      ),
    );
  }

  // 11-Item Telegram Pop-up Menu matching Image 2
  Widget _buildTelegramPopupMenu(BuildContext context, FriendItem? friend) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 235,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(Icons.search, 'Search', () {
              setState(() => _isMenuOpen = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search in chat activated')));
            }),
            _buildMenuItem(Icons.notifications_off_outlined, 'Mute...', () {
              setState(() => _isMenuOpen = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications muted for 8 hours')));
            }),
            _buildMenuItem(Icons.timer_outlined, 'Auto-Delete', () {
              setState(() => _isMenuOpen = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-delete messages enabled: 24h')));
            }, hasTrailingChevron: true),
            _buildMenuItem(Icons.flag_outlined, 'Report user', () {
              setState(() => _isMenuOpen = false);
              context.push('/report-block');
            }),
            _buildMenuItem(Icons.pan_tool_outlined, 'Block user', () async {
              setState(() => _isMenuOpen = false);
              if (friend != null) {
                try {
                  await ApiClient().post(ApiEndpoints.block, body: {'blocked_id': friend.friendId});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${friend.displayName} blocked.')));
                    context.pop();
                  }
                } catch (_) {}
              }
            }),
            const Divider(height: 12, thickness: 0.5, color: Color(0xFFEEEEEE)),
            _buildMenuItem(
              Icons.delete_outline,
              'Delete Chat',
              () async {
                setState(() => _isMenuOpen = false);
                await ref.read(friendsProvider.notifier).unfriend(widget.friendshipId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat deleted.')));
                  context.pop();
                }
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
    bool hasTrailingChevron = false,
  }) {
    final color = isDestructive ? const Color(0xFFE53935) : const Color(0xFF1E232A);
    final iconColor = isDestructive ? const Color(0xFFE53935) : const Color(0xFF555555);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14.5,
                  fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (hasTrailingChevron)
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8E8E93)),
          ],
        ),
      ),
    );
  }

  // Attachment Modal with Image, Video, Presets, File, and Location
  void _showAttachmentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Color(0xFF2481CC)),
                ),
                title: const Text('Upload Image (Gallery / Files)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Send high quality photos from device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                  child: const Icon(Icons.video_library, color: Color(0xFF4CAF50)),
                ),
                title: const Text('Upload Video', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Send short video clips from device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadVideo(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Color(0xFFFF9800)),
                ),
                title: const Text('Camera Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Snap and send instant picture'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(context, ImageSource.camera);
                },
              ),
              const Divider(),
              // Sample presets for quick instant demo testing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.image, size: 16, color: Color(0xFF2481CC)),
                        label: const Text('Sample Photo', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _sendSampleImage(
                            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
                            'Sample Portrait Photo',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.videocam, size: 16, color: Color(0xFF4CAF50)),
                        label: const Text('Sample Video', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _sendSampleVideo('Demo Video Clip (0:30)');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Telegram Signature Doodle Wallpaper Custom Painter
class TelegramDoodleWallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF335828).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const double stepX = 90;
    const double stepY = 90;

    int colIndex = 0;
    for (double x = 15; x < size.width; x += stepX) {
      int rowIndex = 0;
      for (double y = 20; y < size.height; y += stepY) {
        final doodleType = (colIndex * 3 + rowIndex) % 8;
        _drawSingleDoodle(canvas, paint, Offset(x, y), doodleType);
        rowIndex++;
      }
      colIndex++;
    }
  }

  void _drawSingleDoodle(Canvas canvas, Paint paint, Offset origin, int type) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    switch (type) {
      case 0:
        final path = Path()
          ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9))
          ..moveTo(12, 12)
          ..quadraticBezierTo(14, 8, 10, 8)
          ..quadraticBezierTo(7, 12, 11, 15)
          ..moveTo(3, 19)
          ..lineTo(23, 19)
          ..quadraticBezierTo(26, 17, 24, 13)
          ..moveTo(23, 13)
          ..lineTo(26, 10);
        canvas.drawPath(path, paint);
        break;

      case 1:
        final path = Path()
          ..moveTo(4, 14)
          ..quadraticBezierTo(16, 4, 28, 12)
          ..quadraticBezierTo(32, 16, 36, 11)
          ..lineTo(36, 19)
          ..quadraticBezierTo(32, 14, 28, 18)
          ..quadraticBezierTo(16, 24, 4, 14)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case 2:
        final outer = Path()
          ..moveTo(8, 6)
          ..quadraticBezierTo(20, 2, 24, 10)
          ..quadraticBezierTo(28, 18, 18, 22)
          ..quadraticBezierTo(8, 24, 4, 16)
          ..close();
        canvas.drawPath(outer, paint);
        canvas.drawCircle(const Offset(14, 12), 4, paint);
        break;

      case 3:
        final path = Path()
          ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 8, 14, 13), const Radius.circular(4)))
          ..moveTo(20, 10)
          ..quadraticBezierTo(25, 12, 25, 15)
          ..quadraticBezierTo(25, 18, 20, 19);
        canvas.drawPath(path, paint);
        break;

      case 4:
        final path = Path()
          ..addOval(const Rect.fromLTWH(6, 15, 6, 5))
          ..addOval(const Rect.fromLTWH(18, 12, 6, 5))
          ..moveTo(12, 17)
          ..lineTo(12, 6)
          ..lineTo(24, 3)
          ..lineTo(24, 14);
        canvas.drawPath(path, paint);
        break;

      case 5:
        final path = Path()
          ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 20, 15), const Radius.circular(5)))
          ..moveTo(9, 19)
          ..lineTo(6, 24)
          ..lineTo(14, 19);
        canvas.drawPath(path, paint);
        canvas.drawCircle(const Offset(10, 10), 1, paint);
        canvas.drawCircle(const Offset(18, 10), 1, paint);
        canvas.drawArc(const Rect.fromLTWH(11, 11, 6, 4), 0, 3.14, false, paint);
        break;

      case 6:
        final path = Path()
          ..moveTo(4, 18)
          ..lineTo(8, 18)
          ..lineTo(12, 10)
          ..lineTo(22, 10)
          ..quadraticBezierTo(26, 12, 24, 16)
          ..lineTo(20, 16)
          ..lineTo(20, 20)
          ..lineTo(16, 20)
          ..lineTo(16, 16)
          ..lineTo(10, 16)
          ..lineTo(4, 18);
        canvas.drawPath(path, paint);
        break;

      case 7:
        final star = Path()
          ..moveTo(12, 4)
          ..lineTo(14, 9)
          ..lineTo(19, 9)
          ..lineTo(15, 12)
          ..lineTo(17, 17)
          ..lineTo(12, 14)
          ..lineTo(7, 17)
          ..lineTo(9, 12)
          ..lineTo(5, 9)
          ..lineTo(10, 9)
          ..close();
        canvas.drawPath(star, paint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Grogu / Baby Yoda Sticker Painter
class GroguStickerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final earPaint = Paint()
      ..color = const Color(0xFF90B572)
      ..style = PaintingStyle.fill;

    final innerEarPaint = Paint()
      ..color = const Color(0xFFEAA2A2)
      ..style = PaintingStyle.fill;

    // Left ear
    final leftEar = Path()
      ..moveTo(cx - 20, cy - 8)
      ..quadraticBezierTo(cx - 55, cy - 18, cx - 65, cy - 2)
      ..quadraticBezierTo(cx - 45, cy + 12, cx - 18, cy + 6)
      ..close();
    canvas.drawPath(leftEar, earPaint);

    final innerLeft = Path()
      ..moveTo(cx - 22, cy - 5)
      ..quadraticBezierTo(cx - 48, cy - 12, cx - 55, cy)
      ..quadraticBezierTo(cx - 40, cy + 8, cx - 20, cy + 4)
      ..close();
    canvas.drawPath(innerLeft, innerEarPaint);

    // Right ear
    final rightEar = Path()
      ..moveTo(cx + 20, cy - 8)
      ..quadraticBezierTo(cx + 55, cy - 18, cx + 65, cy - 2)
      ..quadraticBezierTo(cx + 45, cy + 12, cx + 18, cy + 6)
      ..close();
    canvas.drawPath(rightEar, earPaint);

    final innerRight = Path()
      ..moveTo(cx + 22, cy - 5)
      ..quadraticBezierTo(cx + 48, cy - 12, cx + 55, cy)
      ..quadraticBezierTo(cx + 40, cy + 8, cx + 20, cy + 4)
      ..close();
    canvas.drawPath(innerRight, innerEarPaint);

    // Grogu Head
    final headPaint = Paint()
      ..color = const Color(0xFF9CCC65)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 2), width: 56, height: 42),
      headPaint,
    );

    // Big Dark Expressive Eyes with white highlights
    final eyePaint = Paint()
      ..color = const Color(0xFF1B2E15)
      ..style = PaintingStyle.fill;

    final eyeShine = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 12, cy - 2), width: 14, height: 16), eyePaint);
    canvas.drawCircle(Offset(cx - 14, cy - 6), 3, eyeShine);
    canvas.drawCircle(Offset(cx - 9, cy), 1.5, eyeShine);

    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 12, cy - 2), width: 14, height: 16), eyePaint);
    canvas.drawCircle(Offset(cx + 10, cy - 6), 3, eyeShine);
    canvas.drawCircle(Offset(cx + 15, cy), 1.5, eyeShine);

    // Little nose & mouth
    final detailPaint = Paint()
      ..color = const Color(0xFF558B2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + 6), width: 5, height: 3), 0, 3.14, false, detailPaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + 11), width: 10, height: 4), 0, 3.14, false, detailPaint);

    // Brown Robe / Cloak collar
    final robePaint = Paint()
      ..color = const Color(0xFF9E7D59)
      ..style = PaintingStyle.fill;

    final robeShadow = Paint()
      ..color = const Color(0xFF755B3E)
      ..style = PaintingStyle.fill;

    final robePath = Path()
      ..moveTo(cx - 28, cy + 16)
      ..quadraticBezierTo(cx, cy + 24, cx + 28, cy + 16)
      ..lineTo(cx + 34, cy + 45)
      ..lineTo(cx - 34, cy + 45)
      ..close();
    canvas.drawPath(robePath, robePaint);

    final collarPath = Path()
      ..moveTo(cx - 25, cy + 16)
      ..quadraticBezierTo(cx, cy + 22, cx + 25, cy + 16)
      ..lineTo(cx + 20, cy + 26)
      ..lineTo(cx - 20, cy + 26)
      ..close();
    canvas.drawPath(collarPath, robeShadow);

    // Green hands on ledge
    final handPaint = Paint()
      ..color = const Color(0xFF9CCC65)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx - 22, cy + 22), 5, handPaint);
    canvas.drawCircle(Offset(cx + 22, cy + 22), 5, handPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
