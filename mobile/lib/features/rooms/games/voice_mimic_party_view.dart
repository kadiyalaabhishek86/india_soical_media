import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class VoiceMimicPartyView extends StatefulWidget {
  final VoidCallback? onBack;
  final Map<String, dynamic>? roomData;
  final bool isPublicViewer;
  final void Function(String winnerName, String summary)? onGameFinished;

  const VoiceMimicPartyView({
    super.key,
    this.onBack,
    this.roomData,
    this.isPublicViewer = false,
    this.onGameFinished,
  });

  @override
  State<VoiceMimicPartyView> createState() => _VoiceMimicPartyViewState();
}

class _VoiceMimicPartyViewState extends State<VoiceMimicPartyView> with TickerProviderStateMixin {
  int _selectedFilter = 0; // 0 = Classic Tom, 1 = Robo-Cat, 2 = Chipmunk
  double _pitch = 0.65; // +65%
  double _speed = 1.25; // 1.25x
  bool _isPrivate = false; // false = Room Broadcast, true = Private
  bool _isRecording = false;
  String _tomSpeech = "\"Meow! 'Hey handsome, you missed that carrom queen!'\"";
  String _tomMood = '🎧 DJ Tom Ready!';
  int _coins = 40;
  int _mimicCount = 0;
  bool _hasEnded = false;

  late AnimationController _waveController;
  late AnimationController _bounceController;

  static const List<Map<String, dynamic>> _filters = [
    {'title': 'Classic Tom', 'sub': 'Helium Squeak', 'icon': '🐱'},
    {'title': 'Robo-Cat 3000', 'sub': 'Cyber Vocoder', 'icon': '🤖'},
    {'title': 'Chipmunk', 'sub': 'Sweet High', 'icon': '🐿️'},
  ];

  static const List<String> _funnyPhrases = [
    "\"Meow! 'Hey handsome, you missed that carrom queen!'\"",
    "\"Purr! 'Rahul said he can beat anyone in Ludo... yeah right!' 😹\"",
    "\"'Kitne aadmi the?!' Meow squeak squeak! 🎬\"",
    "\"'Party abhi baaki hai!' 🎵 Let's dance!\"",
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _pokeTom(String action, String feedback) {
    _bounceController.forward().then((_) => _bounceController.reverse());
    setState(() {
      _tomMood = feedback;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedback),
        backgroundColor: FriendLoopColors.brightViolet,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _triggerMimicSpeech() {
    if (widget.isPublicViewer || _hasEnded) return;
    setState(() => _isRecording = true);
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final nextPhrase = _funnyPhrases[math.Random().nextInt(_funnyPhrases.length)];
      setState(() {
        _isRecording = false;
        _tomSpeech = nextPhrase;
        _tomMood = '😸 Mimicking with Helium Pitch!';
        _mimicCount += 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐱 Tom is repeating your voice in Helium High! 🎈'),
          backgroundColor: FriendLoopColors.success,
        ),
      );
      if (_mimicCount >= 5 && !_hasEnded) {
        _hasEnded = true;
        widget.onGameFinished?.call('You', 'Funniest Voice Mimic Star of Party #104!');
      }
    });
  }

  void _playSfx(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔊 1-Tap SFX: $name played!'),
        backgroundColor: FriendLoopColors.plum,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _sendGift(String name, int cost) {
    if (_coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins! Please refill wallet.')),
      );
      return;
    }
    setState(() => _coins -= cost);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎁 Gifted $name to Tom & Room! (-$cost coins)'),
        backgroundColor: Colors.pink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9F7FC),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    // Header Banner: Party Room & Coins
                    _buildRoomHeader(),
                    const SizedBox(height: 8),

                    // Status Banner: Tom is mimicking Rhea!
                    _buildMimicStatusBanner(),
                    const SizedBox(height: 12),

                    // Talking Tom Animated Stage
                    _buildTomStage(),
                    const SizedBox(height: 12),

                    // Filters & Sliders
                    _buildFiltersAndSliders(),
                    const SizedBox(height: 12),

                    // Broadcast Mode Toggle
                    _buildBroadcastToggle(),
                    const SizedBox(height: 12),

                    // Hold to Speak Waveform & Button (hidden for public viewers)
                    if (!widget.isPublicViewer) ...[
                      _buildVoiceWaveAndRecordButton(),
                      const SizedBox(height: 14),
                    ],

                    // Room Banter & Reactions
                    _buildBanterComments(),
                    const SizedBox(height: 12),

                    // Soundboard SFX
                    _buildSoundboard(),
                    const SizedBox(height: 12),

                    // Cheer Tom & The Room
                    _buildCheerGifts(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Bottom Input
            _buildBottomMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          CircleAvatar(
            radius: 16,
            backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80'),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Rhea', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              Text('● Online', style: TextStyle(fontSize: 10, color: FriendLoopColors.onlineGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFF0D4), borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.phone, size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text('4c/m', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: FriendLoopColors.violet, borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.videocam, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text('16c/m', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert, color: FriendLoopColors.plum), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: FriendLoopColors.lavender,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.graphic_eq, size: 16, color: FriendLoopColors.violet),
              SizedBox(width: 6),
              Text('Party Room #104', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.violet)),
              SizedBox(width: 6),
              Icon(Icons.circle, size: 6, color: FriendLoopColors.onlineGreen),
              SizedBox(width: 4),
              Text('6 Friends Listening', style: TextStyle(fontSize: 11, color: FriendLoopColors.plum)),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2D6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD180)),
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text('$_coins', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.brown)),
              const SizedBox(width: 2),
              const Icon(Icons.add, size: 12, color: Colors.brown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMimicStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6F5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: FriendLoopColors.onlineGreen),
                SizedBox(width: 6),
                Text('TOM IS MIMICKING RHEA! 🎙️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tomSpeech,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.plum, height: 1.3),
          ),
          const SizedBox(height: 4),
          const Text('Pitch: +72% Helium Squeak', style: TextStyle(fontSize: 10, color: FriendLoopColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTomStage() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Circular Glowing Stage Background
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    FriendLoopColors.lavender.withValues(alpha: 0.8),
                    const Color(0xFFEDE4FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Animated Cat Character
            ScaleTransition(
              scale: _bounceController.isAnimating
                  ? _bounceController
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8C52FF).withValues(alpha: 0.15),
                  border: Border.all(color: FriendLoopColors.brightViolet, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎧', style: TextStyle(fontSize: 22)),
                      const Text('🐱', style: TextStyle(fontSize: 48)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: FriendLoopColors.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('VIP DJ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Floating Reactions around Tom
            Positioned(top: 10, right: 10, child: _buildFloatingEmoji('😂')),
            Positioned(bottom: 10, right: 10, child: _buildFloatingEmoji('🤣')),
            Positioned(top: 25, right: 0, child: _buildFloatingEmoji('😻')),
            Positioned(top: 70, right: 0, child: _buildFloatingEmoji('💖')),
          ],
        ),
        const SizedBox(height: 6),
        Text(_tomMood, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FriendLoopColors.violet)),
        const SizedBox(height: 8),

        // Interactive Touch Buttons: Poke, Pet, Scratch
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStageTouchButton('👉 Poke Belly', () => _pokeTom('poke', '😹 Tom giggles: Haha tickles!')),
            const SizedBox(width: 8),
            _buildStageTouchButton('🐱 Pet Ears', () => _pokeTom('pet', '😻 Purrr... Tom loves your petting!')),
            const SizedBox(width: 8),
            _buildStageTouchButton('❤️ Scratch Chin', () => _pokeTom('chin', '😸 Prrrr! Tom is purring happily!')),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingEmoji(String emoji) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildStageTouchButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDD5EE)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
      ),
    );
  }

  Widget _buildFiltersAndSliders() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('🎙️ Voice Mimic Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FriendLoopColors.plum)),
              Text('5 FX Ready', style: TextStyle(fontSize: 10, color: FriendLoopColors.violet, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_filters.length, (idx) {
              final f = _filters[idx];
              final isSel = _selectedFilter == idx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = idx),
                  child: Container(
                    margin: EdgeInsets.only(right: idx < 2 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSel ? FriendLoopColors.violet : const Color(0xFFF6F3FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? FriendLoopColors.violet : Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        Text(f['icon'], style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(f['title'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? Colors.white : FriendLoopColors.plum), maxLines: 1),
                        Text(f['sub'], style: TextStyle(fontSize: 8, color: isSel ? Colors.white70 : FriendLoopColors.textMuted), maxLines: 1),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Sliders: Pitch & Speed
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pitch: +${(_pitch * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                      child: Slider(
                        value: _pitch,
                        onChanged: (v) => setState(() => _pitch = v),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Speed: ${_speed.toStringAsFixed(2)}x', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                      child: Slider(
                        value: _speed,
                        min: 0.8,
                        max: 2.0,
                        onChanged: (v) => setState(() => _speed = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPrivate = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: !_isPrivate ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isPrivate ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                ),
                child: const Text('🌶️ Room Broadcast', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPrivate = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _isPrivate ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isPrivate ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                ),
                child: const Text('🔒 Private (Rhea Only)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceWaveAndRecordButton() {
    return Column(
      children: [
        // Waveform Animation bars
        SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(16, (i) {
              final factor = math.sin((i / 16) * math.pi * 2 + _waveController.value * math.pi * 2).abs();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3,
                height: 6 + factor * 18,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.redAccent : FriendLoopColors.violet,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),

        // Big Glowing Mic Button
        GestureDetector(
          onTap: _triggerMimicSpeech,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF9D4EDD), FriendLoopColors.violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: FriendLoopColors.violet.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, color: Colors.white, size: 28),
                Text('HOLD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Hold to Speak & Mimic',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FriendLoopColors.plum),
        ),
        const Text(
          'Tom repeats instantly in helium high (Max 15s)',
          style: TextStyle(fontSize: 10, color: FriendLoopColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildBanterComments() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.chat_bubble_outline, size: 14, color: FriendLoopColors.violet),
              SizedBox(width: 6),
              Text('Room Banter & Reactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: FriendLoopColors.plum)),
              Spacer(),
              Icon(Icons.circle, size: 6, color: FriendLoopColors.onlineGreen),
              SizedBox(width: 4),
              Text('Live', style: TextStyle(fontSize: 10, color: FriendLoopColors.onlineGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          _buildBanterRow('Rhea', '“Omg that squeaky voice is hilarious! 💀😂”', 'Just now'),
          const SizedBox(height: 6),
          _buildBanterRow('Rohan', '“Bro challenge him to say Bollywood dialogues!”', '1m ago'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Text('🎁 Priya gifted Laughing Cat to Tom (+1 coin tip)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanterRow(String user, String msg, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 10, child: Text(user[0], style: const TextStyle(fontSize: 9))),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$user: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: FriendLoopColors.plum)),
                TextSpan(text: msg, style: const TextStyle(fontSize: 10, color: Colors.black87)),
              ],
            ),
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 9, color: FriendLoopColors.textMuted)),
      ],
    );
  }

  Widget _buildSoundboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Party SFX Soundboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: FriendLoopColors.plum)),
            Text('1-Tap Live FX', style: TextStyle(fontSize: 10, color: FriendLoopColors.violet, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildSfxButton('🎺 Horn', () => _playSfx('Party Horn 🎺')),
            const SizedBox(width: 6),
            _buildSfxButton('🥁 Rimshot', () => _playSfx('Drum Rimshot 🥁')),
            const SizedBox(width: 6),
            _buildSfxButton('💥 Scratch', () => _playSfx('DJ Scratch 💥')),
            const SizedBox(width: 6),
            _buildSfxButton('💋 Muah Kiss', () => _playSfx('Muah Kiss 💋')),
          ],
        ),
      ],
    );
  }

  Widget _buildSfxButton(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD5EE)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
        ),
      ),
    );
  }

  Widget _buildCheerGifts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Cheer Tom & The Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: FriendLoopColors.plum)),
            Text('Instant Cheer', style: TextStyle(fontSize: 10, color: Colors.pink, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildGiftItem('🐟', 'Cat Fish', 1),
            const SizedBox(width: 6),
            _buildGiftItem('🥛', 'Milk Bowl', 2),
            const SizedBox(width: 6),
            _buildGiftItem('🧶', 'Yarn Ball', 5),
            const SizedBox(width: 6),
            _buildGiftItem('👑', 'Gold Collar', 20),
          ],
        ),
      ],
    );
  }

  Widget _buildGiftItem(String icon, String name, int cost) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _sendGift(name, cost),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD1DC)),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              Text(name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              Text('${cost}c', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.pink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEDE8F7)))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 20), onPressed: () => _sendGift('Mystery Box', 10)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF6F3FA), borderRadius: BorderRadius.circular(20)),
              child: const Text('Type a warm message...', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
          ),
          IconButton(icon: const Icon(Icons.sentiment_satisfied_alt, color: FriendLoopColors.plum, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.mic, color: FriendLoopColors.violet, size: 20), onPressed: () {}),
        ],
      ),
    );
  }
}
