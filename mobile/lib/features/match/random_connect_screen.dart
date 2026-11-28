import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/indian_states.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/match_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/utils/nav_helper.dart';

class RandomConnectScreen extends ConsumerStatefulWidget {
  const RandomConnectScreen({super.key});

  @override
  ConsumerState<RandomConnectScreen> createState() => _RandomConnectScreenState();
}

class _RandomConnectScreenState extends ConsumerState<RandomConnectScreen> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  String _selectedMode = 'voice'; // 'voice', 'video', 'chat'
  String _selectedCountry = 'Any country';
  String _selectedLanguage = 'Any language';
  late AnimationController _pulseController;
  Timer? _searchTimeout;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchTimeout?.cancel();
    super.dispose();
  }

  void _startSearching() {
    setState(() {
      _isSearching = true;
    });
    _pulseController.repeat(reverse: true);

    // Call match provider safely
    try {
      ref.read(matchProvider.notifier).joinQueue(
        callMode: _selectedMode == 'video' ? 'video' : 'voice',
        allowAnyLanguage: _selectedLanguage == 'Any language',
      ).catchError((_) {});
    } catch (_) {}

    // Simulate match connection after 3.5s
    _searchTimeout?.cancel();
    _searchTimeout = Timer(const Duration(milliseconds: 3500), () {
      if (!mounted || !_isSearching) return;
      _pulseController.stop();
      setState(() => _isSearching = false);
      if (_selectedMode == 'chat') {
        context.push(
          '/chat/11111111-0000-0000-0000-000000000001',
          extra: FriendItem(
            friendshipId: '11111111-0000-0000-0000-000000000001',
            friendId: '21111111-0000-0000-0000-000000000001',
            displayName: 'Ananya Reddy',
            state: 'Telangana',
            city: 'Hyderabad',
            age: 26,
            languages: 'Telugu, English, Hindi',
            images: const ['https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80'],
          ),
        );
      } else {
        context.push('/call');
      }
    });
  }

  void _cancelSearching() {
    _searchTimeout?.cancel();
    _pulseController.stop();
    setState(() => _isSearching = false);
    ref.read(matchProvider.notifier).cancelQueue();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUserProfile;
    final coins = user?.coins ?? 120;

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () {
            if (_isSearching) {
              _cancelSearching();
            } else {
              safePop(context);
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/friendloop_logo.png',
              height: 26,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.all_inclusive_rounded,
                color: FriendLoopColors.violet,
                size: 24,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'FriendLoop',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: FriendLoopColors.plum,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Coins Pill on Top Right
          GestureDetector(
            onTap: () => context.push('/wallet'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FriendLoopColors.lavender),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '$coins coins',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
          child: _isSearching ? _buildSearchingView() : _buildSelectionView(),
        ),
      ),
    );
  }

  // Screen 1: Selection View (matching left screen in mockup)
  Widget _buildSelectionView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Random Connect',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: FriendLoopColors.plum,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Meet a new friend across India',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: FriendLoopColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: FriendLoopColors.onlineGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Online now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FriendLoopColors.plum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Voice Call Option
          _buildOptionTile(
            mode: 'voice',
            title: 'Voice Call',
            subtitle: '🪙 10 coins/min',
            icon: Icons.mic,
          ),

          // 2. Video Call Option
          _buildOptionTile(
            mode: 'video',
            title: 'Video Call',
            subtitle: '🪙 40 coins/min',
            icon: Icons.videocam_rounded,
          ),

          // 3. Text Chat Option
          _buildOptionTile(
            mode: 'chat',
            title: 'Text Chat',
            subtitle: '🪙 Uses coins',
            icon: Icons.chat_bubble_rounded,
          ),

          const SizedBox(height: 8),

          // Country (optional) Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Country (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: FriendLoopColors.plum,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountry,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: FriendLoopColors.plum),
                    items: ['Any country', ...IndianData.allCountries]
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(fontSize: 14, color: FriendLoopColors.plum)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCountry = v);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Language (optional) Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Language (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: FriendLoopColors.plum,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: FriendLoopColors.plum),
                    items: const [
                      DropdownMenuItem(value: 'Any language', child: Text('Any language', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Hindi', child: Text('Hindi', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'English', child: Text('English', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Telugu', child: Text('Telugu', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Tamil', child: Text('Tamil', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Kannada', child: Text('Kannada', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Malayalam', child: Text('Malayalam', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Marathi', child: Text('Marathi', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Bengali', child: Text('Bengali', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Gujarati', child: Text('Gujarati', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                      DropdownMenuItem(value: 'Punjabi', child: Text('Punjabi', style: TextStyle(fontSize: 14, color: FriendLoopColors.plum))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedLanguage = v);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Primary Find Match Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _startSearching,
              style: ElevatedButton.styleFrom(
                backgroundColor: FriendLoopColors.violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                _selectedMode == 'voice'
                    ? 'Find a voice match'
                    : (_selectedMode == 'video' ? 'Find a video match' : 'Find a text match'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.push('/wallet'),
            child: const Text(
              'Calls use coins once connected',
              style: TextStyle(
                fontSize: 12,
                color: FriendLoopColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? FriendLoopColors.lavender.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FriendLoopColors.lavender.withValues(alpha: 0.7),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: FriendLoopColors.violet,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // Screen 2: Searching View (matching right screen in mockup)
  Widget _buildSearchingView() {
    final modeLabel = _selectedMode == 'voice'
        ? 'Voice Call'
        : (_selectedMode == 'video' ? 'Video Call' : 'Text Chat');

    final modeIcon = _selectedMode == 'video'
        ? Icons.videocam_rounded
        : (_selectedMode == 'voice' ? Icons.mic : Icons.chat_bubble_rounded);

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Finding a friend...',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: FriendLoopColors.plum,
          ),
        ),
        const SizedBox(height: 12),

        // Pill badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: FriendLoopColors.lavender,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(modeIcon, color: FriendLoopColors.violet, size: 18),
              const SizedBox(width: 8),
              Text(
                modeLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: FriendLoopColors.plum,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Animated Radar with Concentric Circles
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.08);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FriendLoopColors.lavender.withValues(alpha: 0.35),
                ),
                child: Center(
                  child: Container(
                    width: 175,
                    height: 175,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FriendLoopColors.lavender.withValues(alpha: 0.65),
                    ),
                    child: Center(
                      child: Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: FriendLoopColors.lavender, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: FriendLoopColors.violet.withValues(alpha: 0.15),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(modeIcon, size: 40, color: FriendLoopColors.violet),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),
        const Text(
          'Looking for someone to talk with',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: FriendLoopColors.plum,
          ),
        ),

        const Spacer(),

        // Cancel Search Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _cancelSearching,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: FriendLoopColors.violet, width: 1.5),
              foregroundColor: FriendLoopColors.violet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Cancel search',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: FriendLoopColors.violet,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
