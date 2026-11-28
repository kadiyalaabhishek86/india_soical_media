import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class TruthOrDareGameView extends StatefulWidget {
  final VoidCallback? onBack;
  final Map<String, dynamic>? roomData;
  final bool isPublicViewer;
  final void Function(String winnerName, String summary)? onGameFinished;

  const TruthOrDareGameView({
    super.key,
    this.onBack,
    this.roomData,
    this.isPublicViewer = false,
    this.onGameFinished,
  });

  @override
  State<TruthOrDareGameView> createState() => _TruthOrDareGameViewState();
}

class _TruthOrDareGameViewState extends State<TruthOrDareGameView> with SingleTickerProviderStateMixin {
  int _categoryIndex = 1; // 0 = Casual Chill, 1 = Flirt & Crush, 2 = Wild Dares
  int _decisionChoice = 0; // 0 = TRUTH, 1 = DARE
  int _round = 4;
  int _targetPlayerIndex = 0; // 0: Rhea, 1: Kabir, 2: Priya, 3: You, 4: Rohan, 5: Ananya
  int _secondsLeft = 9;
  int _coins = 40;
  bool _isSpinning = false;
  bool _hasEnded = false;

  late AnimationController _bottleController;
  late Animation<double> _bottleAnimation;
  double _currentBottleAngle = -math.pi / 2; // pointing upwards to Rhea

  static const List<Map<String, String>> _players = [
    {'name': 'Rhea, 24', 'role': 'Target', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Kabir', 'role': 'Challenger', 'image': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Priya', 'role': 'Friend', 'image': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80'},
    {'name': 'YOU (HOST) 👑', 'role': 'Host', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Rohan', 'role': 'Friend', 'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Ananya', 'role': 'Friend', 'image': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80'},
  ];

  static const List<String> _truthQuestions = [
    "\"What was your very first impression when you matched with someone in this room?\"",
    "\"What is the cutest romantic gesture anyone has ever done for you?\"",
    "\"Have you ever stalked your crush's social media for over an hour?\"",
    "\"Who in this room would you pick for a spontaneous late-night drive?\"",
  ];

  static const List<String> _dareChallenges = [
    "\"Sing the chorus of your favorite romantic Hindi song on live room mic! 🎤\"",
    "\"Send a voice note confessing your celebrity crush in a dramatic Bollywood voice!\"",
    "\"Do your best impression of someone in this room right now!\"",
  ];

  String _currentPrompt = "\"What was your very first impression when you matched with someone in this room?\"";

  @override
  void initState() {
    super.initState();
    _bottleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _bottleAnimation = CurvedAnimation(parent: _bottleController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _bottleController.dispose();
    super.dispose();
  }

  void _spinBottle() {
    if (widget.isPublicViewer || _isSpinning || _hasEnded) return;
    setState(() => _isSpinning = true);

    final randomTarget = math.Random().nextInt(_players.length);
    // Angles around circle for 6 players: -pi/2, -pi/2 + pi/3, etc.
    final targetAngle = -math.pi / 2 + (randomTarget * 2 * math.pi / _players.length) + (math.pi * 6); // 3 full spins

    final startAngle = _currentBottleAngle % (2 * math.pi);
    _bottleAnimation = Tween<double>(begin: startAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _bottleController, curve: Curves.easeOutCubic),
    );

    _bottleController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _isSpinning = false;
        _currentBottleAngle = targetAngle % (2 * math.pi);
        _targetPlayerIndex = randomTarget;
        _round += 1;
        _secondsLeft = 12;
        _currentPrompt = _decisionChoice == 0
            ? _truthQuestions[math.Random().nextInt(_truthQuestions.length)]
            : _dareChallenges[math.Random().nextInt(_dareChallenges.length)];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🍾 Bottle points to ${_players[randomTarget]['name']}!'),
          backgroundColor: FriendLoopColors.brightViolet,
        ),
      );
      if (_round >= 10 && !_hasEnded) {
        _hasEnded = true;
        widget.onGameFinished?.call(
          _players[randomTarget]['name'] ?? 'Rhea',
          'Truth or Dare Champion after 10 rounds!',
        );
      }
    });
  }

  void _sendReaction(String emoji) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reacted with $emoji!'),
        backgroundColor: FriendLoopColors.plum,
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  void _sendGift(String name, int cost) {
    if (_coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
      return;
    }
    setState(() => _coins -= cost);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎁 Sent $name to ${_players[_targetPlayerIndex]['name']}! (-$cost coins)'), backgroundColor: Colors.pink),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetPlayer = _players[_targetPlayerIndex];

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
                    _buildHeaderBanner(),
                    const SizedBox(height: 8),

                    // Category Filter Pills
                    _buildCategoryPills(),
                    const SizedBox(height: 12),

                    // Circular Stage with Players & Center Spinning Bottle
                    _buildCircularBottleStage(),
                    const SizedBox(height: 14),

                    // Decision Phase Card (Truth vs Dare)
                    _buildDecisionCard(targetPlayer),
                    const SizedBox(height: 12),

                    // Prompt Box (Question / Dare)
                    _buildPromptBox(targetPlayer),
                    const SizedBox(height: 12),

                    // Big Spin Button (hidden for public viewers)
                    if (!widget.isPublicViewer) ...[
                      _buildSpinButton(),
                      const SizedBox(height: 12),
                    ],

                    // Circle Chat & Banter
                    _buildCircleChat(),
                    const SizedBox(height: 12),

                    // Send Game Gifts
                    _buildGameGifts(targetPlayer),
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

  Widget _buildHeaderBanner() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: FriendLoopColors.lavender, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              Icon(Icons.psychology, size: 16, color: FriendLoopColors.violet),
              SizedBox(width: 6),
              Text('Party #104 • Truth or Dare 🍾', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.violet)),
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

  Widget _buildCategoryPills() {
    final categories = ['✨ Casual Chill', '🔥 Flirt & Crush', '😈 Wild Dares'];
    return Row(
      children: List.generate(categories.length, (idx) {
        final isSel = _categoryIndex == idx;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _categoryIndex = idx),
            child: Container(
              margin: EdgeInsets.only(right: idx < 2 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? FriendLoopColors.violet : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSel ? FriendLoopColors.violet : const Color(0xFFE2DCF0)),
              ),
              child: Text(
                categories[idx],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : FriendLoopColors.plum,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCircularBottleStage() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          final radius = constraints.maxHeight * 0.38;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Concentric Dashed Guide Circles
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _BottleGuidePainter(),
              ),

              // Player Avatars positioned in circle
              ...List.generate(_players.length, (idx) {
                final angle = -math.pi / 2 + (idx * 2 * math.pi / _players.length);
                final x = center.dx + radius * math.cos(angle) - 22;
                final y = center.dy + radius * math.sin(angle) - 22;
                final isTarget = _targetPlayerIndex == idx;

                return Positioned(
                  left: x,
                  top: y,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isTarget ? Colors.pinkAccent : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(_players[idx]['image']!),
                          onBackgroundImageError: (_, __) {},
                        ),
                      ),
                      Text(
                        _players[idx]['name']!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isTarget ? Colors.pinkAccent : FriendLoopColors.plum,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Center Spinning Bottle
              AnimatedBuilder(
                animation: _bottleAnimation,
                builder: (context, child) {
                  final angle = _isSpinning ? _bottleAnimation.value : _currentBottleAngle;
                  return Transform.rotate(
                    angle: angle,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: FriendLoopColors.violet,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: FriendLoopColors.violet.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🍾', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDecisionCard(Map<String, String> player) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6F5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🟣 ${player['name']}\'s Decision Phase',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.plum),
              ),
              Text('Round $_round of 10', style: const TextStyle(fontSize: 10, color: FriendLoopColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // TRUTH Tab
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _decisionChoice = 0;
                    _currentPrompt = _truthQuestions[math.Random().nextInt(_truthQuestions.length)];
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _decisionChoice == 0 ? FriendLoopColors.violet : const Color(0xFFF7F4FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _decisionChoice == 0 ? FriendLoopColors.violet : Colors.transparent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('TRUTH 🔒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _decisionChoice == 0 ? Colors.white : FriendLoopColors.plum)),
                            const Spacer(),
                            if (_decisionChoice == 0) const Icon(Icons.check_circle, color: Colors.white, size: 14),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Confess a sweet secret honestly', style: TextStyle(fontSize: 9, color: _decisionChoice == 0 ? Colors.white70 : FriendLoopColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // DARE Tab
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _decisionChoice = 1;
                    _currentPrompt = _dareChallenges[math.Random().nextInt(_dareChallenges.length)];
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _decisionChoice == 1 ? FriendLoopColors.violet : const Color(0xFFF7F4FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _decisionChoice == 1 ? FriendLoopColors.violet : Colors.transparent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('DARE 🔥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _decisionChoice == 1 ? Colors.white : FriendLoopColors.plum)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                              child: const Text('+10 XP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Live mic or selfie dare prompt', style: TextStyle(fontSize: 9, color: _decisionChoice == 1 ? Colors.white70 : FriendLoopColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptBox(Map<String, String> player) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🙈 Romance & Crush • Level 2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              Spacer(),
              Icon(Icons.mic, size: 12, color: Colors.deepOrange),
              SizedBox(width: 4),
              Text('Speaking...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentPrompt,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${player['name']} answering on live audio • 00:${_secondsLeft.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: Colors.brown),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => setState(() => _secondsLeft += 10),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Skip (5c)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('👏 Cheered and Passed!'))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FriendLoopColors.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Cheer & Pass!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _spinBottle,
            icon: const Text('🍾', style: TextStyle(fontSize: 18)),
            label: const Text('SPIN THE BOTTLE AGAIN 🔄', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: FriendLoopColors.violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text('Host privileges: You can pass spin priority or spin for the room', style: TextStyle(fontSize: 9, color: FriendLoopColors.textMuted)),
      ],
    );
  }

  Widget _buildCircleChat() {
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
              Icon(Icons.forum_outlined, size: 14, color: FriendLoopColors.violet),
              SizedBox(width: 6),
              Text('Circle Chat & Reactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: FriendLoopColors.plum)),
              Spacer(),
              Icon(Icons.circle, size: 6, color: FriendLoopColors.onlineGreen),
              SizedBox(width: 4),
              Text('Live mic audio on', style: TextStyle(fontSize: 10, color: FriendLoopColors.onlineGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Rohan: “Haha Rhea don\'t dodge this one! Tell truth 😂”', style: TextStyle(fontSize: 10, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Rhea: “Omg blushing so hard rn... wait turning on mic 🙈🪻”', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Emoji reactions bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['🍾', '🔥', '🙈', '🤣', '💖', '🌶️'].map((emoji) {
              return GestureDetector(
                onTap: () => _sendReaction(emoji),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF7F4FB), borderRadius: BorderRadius.circular(10)),
                  child: Text(emoji, style: const TextStyle(fontSize: 16)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGifts(Map<String, String> player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Send Game Gift to ${player['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: FriendLoopColors.plum)),
            const Text('View Store', style: TextStyle(fontSize: 10, color: Colors.pink, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildGiftItem('🧪', 'Truth Potion', 2),
            const SizedBox(width: 6),
            _buildGiftItem('🌶️', 'Dare Pepper', 5),
            const SizedBox(width: 6),
            _buildGiftItem('🌹', 'Rose Bloom', 10),
            const SizedBox(width: 6),
            _buildGiftItem('🪩', 'Disco Bottle', 25),
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
              Text(name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: FriendLoopColors.plum), maxLines: 1),
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
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 20), onPressed: () => _sendGift('Party Gift', 10)),
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

class _BottleGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * 0.38;

    final paint = Paint()
      ..color = const Color(0xFFE2DCF0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
