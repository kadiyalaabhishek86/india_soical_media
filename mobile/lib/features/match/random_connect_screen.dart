import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/match_provider.dart';
import '../../core/providers/call_provider.dart';

class RandomConnectScreen extends ConsumerStatefulWidget {
  const RandomConnectScreen({super.key});

  @override
  ConsumerState<RandomConnectScreen> createState() => _RandomConnectScreenState();
}

class _RandomConnectScreenState extends ConsumerState<RandomConnectScreen> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  String _selectedMode = 'voice'; // 'chat', 'voice', 'video'
  late AnimationController _radarController;
  Timer? _searchTimeout;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    _searchTimeout?.cancel();
    super.dispose();
  }

  void _startSearching(String mode) {
    setState(() {
      _selectedMode = mode;
      _isSearching = true;
    });
    _radarController.repeat();

    // Call match provider
    ref.read(matchProvider.notifier).joinQueue(callMode: mode == 'video' ? 'video' : 'voice');

    // Simulate match connection after 3.5s
    _searchTimeout?.cancel();
    _searchTimeout = Timer(const Duration(milliseconds: 3500), () {
      if (!mounted || !_isSearching) return;
      _radarController.stop();
      setState(() => _isSearching = false);
      if (mode == 'chat') {
        context.push('/chat/demo-chat-random');
      } else {
        context.push('/call');
      }
    });
  }

  void _cancelSearching() {
    _searchTimeout?.cancel();
    _radarController.stop();
    setState(() => _isSearching = false);
    ref.read(matchProvider.notifier).cancelQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => context.pop(),
        ),
        title: Image.asset(
          'assets/images/friendloop_logo.png',
          height: 32,
          errorBuilder: (_, __, ___) => const Icon(Icons.all_inclusive, color: FriendLoopColors.violet, size: 28),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: _isSearching ? _buildSearchingView() : _buildSelectionView(),
        ),
      ),
    );
  }

  Widget _buildSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Meet a new friend\ninstantly!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: FriendLoopColors.plum,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Get matched with a friendly person\nacross India for a text, voice or video chat.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: FriendLoopColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 36),

        // 3 Cards Row (Text Chat, Voice Call, Video Call)
        Row(
          children: [
            _buildModeCard(
              mode: 'chat',
              title: 'Text\nChat',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            const SizedBox(width: 12),
            _buildModeCard(
              mode: 'voice',
              title: 'Voice\nCall',
              icon: Icons.phone_outlined,
            ),
            const SizedBox(width: 12),
            _buildModeCard(
              mode: 'video',
              title: 'Video\nCall',
              icon: Icons.videocam_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeCard({required String mode, required String title, required IconData icon}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _startSearching(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FriendLoopColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: FriendLoopColors.violet),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mode indicator tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: FriendLoopColors.lavender,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedMode == 'video' ? Icons.videocam : (_selectedMode == 'voice' ? Icons.phone : Icons.chat),
                color: FriendLoopColors.violet,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedMode.toUpperCase()} MODE',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.violet),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),

        // Animated Radar with Magnifying Glass
        Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _radarController,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FriendLoopColors.brightViolet.withValues(alpha: 0.25),
                      FriendLoopColors.violet.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: FriendLoopColors.violet.withValues(alpha: 0.2), blurRadius: 20),
                ],
              ),
              child: const Center(
                child: Icon(Icons.search, size: 48, color: FriendLoopColors.violet),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),

        const Text(
          'Searching for a friend...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: FriendLoopColors.plum),
        ),
        const SizedBox(height: 8),
        Text(
          'Finding someone to talk with in ${_selectedMode.toUpperCase()} mode.\nThis may take a few seconds.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: FriendLoopColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 48),

        OutlinedButton.icon(
          onPressed: _cancelSearching,
          icon: const Icon(Icons.close, color: FriendLoopColors.rose),
          label: const Text('Cancel', style: TextStyle(color: FriendLoopColors.rose, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: FriendLoopColors.rose),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
