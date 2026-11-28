import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class CarromClashGameView extends StatefulWidget {
  final VoidCallback? onBack;
  final Map<String, dynamic>? roomData;
  final bool isPublicViewer;
  final void Function(String winnerName, String summary)? onGameFinished;

  const CarromClashGameView({
    super.key,
    this.onBack,
    this.roomData,
    this.isPublicViewer = false,
    this.onGameFinished,
  });

  @override
  State<CarromClashGameView> createState() => _CarromClashGameViewState();
}

class _CarromClashGameViewState extends State<CarromClashGameView> with SingleTickerProviderStateMixin {
  double _strikerPosition = 0.45; // 0.0 to 1.0 baseline position
  double _flickPower = 0.75; // 0.0 to 1.0 flick power
  double _aimAngle = -math.pi / 2.3; // Aim angle in radians
  int _userScore = 15;
  int _rheaScore = 10;
  int _secondsLeft = 14;
  bool _isStriking = false;
  bool _hasEnded = false;
  String _activeBanter = '😏 Queen is mine!';
  late AnimationController _strikeController;
  late Animation<double> _strikeAnim;

  // Carrom piece positions (relative to board center: 0,0)
  List<_CarromCoin> _coins = [
    _CarromCoin(type: _CoinType.queen, x: 0, y: 0),
    _CarromCoin(type: _CoinType.black, x: -0.15, y: -0.05),
    _CarromCoin(type: _CoinType.black, x: 0.12, y: 0.08),
    _CarromCoin(type: _CoinType.black, x: -0.08, y: 0.14),
    _CarromCoin(type: _CoinType.white, x: 0.14, y: -0.1),
    _CarromCoin(type: _CoinType.white, x: -0.02, y: -0.16),
    _CarromCoin(type: _CoinType.white, x: 0.06, y: 0.18),
  ];

  @override
  void initState() {
    super.initState();
    _strikeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _strikeAnim = CurvedAnimation(parent: _strikeController, curve: Curves.easeOutQuad);
  }

  @override
  void dispose() {
    _strikeController.dispose();
    super.dispose();
  }

  void _triggerStrike() {
    if (widget.isPublicViewer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Public viewers can watch, comment & send gifts.')),
      );
      return;
    }
    if (_isStriking || _hasEnded) return;
    setState(() => _isStriking = true);
    _strikeController.forward(from: 0).then((_) {
      _strikeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _isStriking = false;
          _userScore += 10;
          _activeBanter = '🎯 Outstanding strike!';
          if (_coins.length > 2) {
            _coins.removeLast(); // simulate pocketing
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ POCKETED WHITE COIN! +10 Points! 🎯'),
            backgroundColor: FriendLoopColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        if (_userScore >= 25 && !_hasEnded) {
          _hasEnded = true;
          widget.onGameFinished?.call(
            'You',
            'Won Carrom Clash $_userScore - $_rheaScore (20 Coin Pot)!',
          );
        }
      });
    });
  }

  void _sendCheer(String gift, int cost) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎁 Sent $gift to Rhea! (-$cost coins)'),
        backgroundColor: FriendLoopColors.brightViolet,
        duration: const Duration(seconds: 2),
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
            // Top Header Bar
            _buildTopBar(context),

            // Game Header (Match pot & Status)
            _buildMatchBanner(),

            // Turn Countdown & Players Score
            _buildScoreBoard(),

            // Coin Legend
            _buildCoinLegend(),

            // Carrom Board Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: [
                        // Custom Painted Carrom Board
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _strikeAnim,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _CarromBoardPainter(
                                  strikerBaseline: _strikerPosition,
                                  flickPower: _flickPower,
                                  strikeProgress: _strikeAnim.value,
                                  aimAngle: _aimAngle,
                                  coins: _coins,
                                ),
                              );
                            },
                          ),
                        ),

                        // Speech bubble over board
                        if (_activeBanter.isNotEmpty)
                          Positioned(
                            top: 40,
                            right: 40,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                _activeBanter,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Interactive Controls (hidden for public viewers)
            if (!widget.isPublicViewer) _buildControls(),

            // Quick Banter & Gifts
            _buildBanterAndCheer(),

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
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0D4),
              borderRadius: BorderRadius.circular(14),
            ),
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
            decoration: BoxDecoration(
              color: FriendLoopColors.violet,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.videocam, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text('16c/m', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: FriendLoopColors.plum),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6F5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FriendLoopColors.lavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('Carrom Clash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.violet)),
                    Icon(Icons.arrow_drop_down, size: 18, color: FriendLoopColors.violet),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('MATCH #408', style: TextStyle(fontSize: 10, color: FriendLoopColors.textMuted, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2D6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD180)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.monetization_on, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('20 COIN POT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.brown)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.circle, color: FriendLoopColors.onlineGreen, size: 8),
              SizedBox(width: 6),
              Text('Connected with Rhea', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FriendLoopColors.plum)),
              Spacer(),
              Icon(Icons.signal_cellular_alt, size: 14, color: FriendLoopColors.violet),
              SizedBox(width: 8),
              Text('4c/m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.textSecondary)),
              SizedBox(width: 8),
              Icon(Icons.mic, size: 14, color: FriendLoopColors.violet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left player: You
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80'),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FriendLoopColors.plum)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: FriendLoopColors.lavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$_userScore pts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FriendLoopColors.violet)),
                  ),
                ],
              ),
            ],
          ),

          // Center: Countdown & Turn
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: FriendLoopColors.violet,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('YOUR TURN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 2),
              Text('${_secondsLeft}s', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: FriendLoopColors.plum)),
              const Text('First to 25 pts', style: TextStyle(fontSize: 9, color: FriendLoopColors.textMuted)),
            ],
          ),

          // Right player: Rhea
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Rhea ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FriendLoopColors.plum)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$_rheaScore pts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80'),
                onBackgroundImageError: (_, __) {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.circle, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text('White: 10 pts', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
          SizedBox(width: 12),
          Icon(Icons.circle, size: 10, color: Colors.black87),
          SizedBox(width: 3),
          Text('Black: 5 pts', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
          SizedBox(width: 12),
          Icon(Icons.circle, size: 10, color: Colors.red),
          SizedBox(width: 3),
          Text('Queen: 25 pts (In Play)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('STRIKER BASELINE POSITION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.textMuted)),
              Text('Center (${(_strikerPosition * 100).round()}%)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.violet)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: FriendLoopColors.violet,
              inactiveTrackColor: Colors.black12,
              thumbColor: FriendLoopColors.violet,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _strikerPosition,
              onChanged: (v) => setState(() => _strikerPosition = v),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('⚡ FLICK POWER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.textMuted)),
                        Text('${(_flickPower * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: Colors.deepOrange,
                        inactiveTrackColor: Colors.black12,
                        thumbColor: Colors.deepOrange,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _flickPower,
                        onChanged: (v) => setState(() => _flickPower = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Big Strike Button
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _triggerStrike,
                  icon: const Icon(Icons.sports_esports, color: Colors.white, size: 18),
                  label: const Text('RELEASE & STRIKE >>', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanterAndCheer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildBanterChip('Good shot! 👏'),
              const SizedBox(width: 6),
              _buildBanterChip('Rematch ready? 😏'),
              const SizedBox(width: 6),
              _buildBanterChip('Queen is mine! 🔴'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Cheer Rhea: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              _buildCheerButton('🌹 1c', () => _sendCheer('Rose', 1)),
              const SizedBox(width: 6),
              _buildCheerButton('☕ 5c', () => _sendCheer('Coffee', 5)),
              const SizedBox(width: 6),
              _buildCheerButton('❤️ 10c', () => _sendCheer('Heart', 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanterChip(String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeBanter = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2DCF0)),
          ),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
        ),
      ),
    );
  }

  Widget _buildCheerButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD1DC)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink)),
      ),
    );
  }

  Widget _buildBottomMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDE8F7))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 20),
            onPressed: () => _sendCheer('Special Gift', 15),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Type a warm message...', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt, color: FriendLoopColors.plum, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: FriendLoopColors.violet, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

enum _CoinType { white, black, queen }

class _CarromCoin {
  final _CoinType type;
  double x;
  double y;

  _CarromCoin({required this.type, required this.x, required this.y});
}

class _CarromBoardPainter extends CustomPainter {
  final double strikerBaseline;
  final double flickPower;
  final double strikeProgress;
  final double aimAngle;
  final List<_CarromCoin> coins;

  _CarromBoardPainter({
    required this.strikerBaseline,
    required this.flickPower,
    required this.strikeProgress,
    required this.aimAngle,
    required this.coins,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final boardRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Wooden frame
    final woodPaint = Paint()..color = const Color(0xFF4A2511);
    canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(16)), woodPaint);

    // Inner board surface
    final innerBoardRect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    final surfacePaint = Paint()..color = const Color(0xFFF3E7C9); // ivory / wood board surface
    canvas.drawRRect(RRect.fromRectAndRadius(innerBoardRect, const Radius.circular(8)), surfacePaint);

    // 2. Corner pockets
    final pocketPaint = Paint()..color = const Color(0xFF1A1A1A);
    final pocketRadius = size.width * 0.07;
    canvas.drawCircle(Offset(22, 22), pocketRadius, pocketPaint);
    canvas.drawCircle(Offset(size.width - 22, 22), pocketRadius, pocketPaint);
    canvas.drawCircle(Offset(22, size.height - 22), pocketRadius, pocketPaint);
    canvas.drawCircle(Offset(size.width - 22, size.height - 22), pocketRadius, pocketPaint);

    // 3. Baselines & Circles
    final linePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Center circular rings
    canvas.drawCircle(center, size.width * 0.16, linePaint);
    canvas.drawCircle(center, size.width * 0.05, linePaint);

    // Bottom baseline where striker sits
    final baselineY = size.height * 0.78;
    canvas.drawLine(Offset(size.width * 0.18, baselineY), Offset(size.width * 0.82, baselineY), linePaint);
    canvas.drawLine(Offset(size.width * 0.18, baselineY + 12), Offset(size.width * 0.82, baselineY + 12), linePaint);

    // Baseline red endpoint circles
    final endpointPaint = Paint()..color = Colors.redAccent.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(size.width * 0.18, baselineY + 6), 6, endpointPaint);
    canvas.drawCircle(Offset(size.width * 0.82, baselineY + 6), 6, endpointPaint);

    // 4. Carrom Coins
    for (final coin in coins) {
      final coinPos = Offset(
        center.dx + coin.x * (size.width * 0.6),
        center.dy + coin.y * (size.height * 0.6),
      );
      final coinRadius = size.width * 0.038;

      Paint coinPaint = Paint();
      if (coin.type == _CoinType.queen) {
        coinPaint.color = Colors.red;
      } else if (coin.type == _CoinType.white) {
        coinPaint.color = Colors.white;
      } else {
        coinPaint.color = const Color(0xFF262626);
      }

      // Shadow
      canvas.drawCircle(coinPos.translate(1, 1), coinRadius, Paint()..color = Colors.black26);
      canvas.drawCircle(coinPos, coinRadius, coinPaint);
      canvas.drawCircle(coinPos, coinRadius * 0.5, linePaint);
      if (coin.type == _CoinType.queen) {
        canvas.drawCircle(coinPos, coinRadius * 0.25, Paint()..color = Colors.amber);
      }
    }

    // 5. Striker Position
    final strikerStartX = size.width * 0.18 + strikerBaseline * (size.width * 0.64);
    final strikerStartY = baselineY + 6;

    // If striking, animate towards center
    final strikeDist = size.height * 0.45 * flickPower * strikeProgress;
    final strikerCurrentX = strikerStartX + math.cos(aimAngle) * strikeDist;
    final strikerCurrentY = strikerStartY + math.sin(aimAngle) * strikeDist;
    final strikerPos = Offset(strikerCurrentX, strikerCurrentY);

    // Striker Aim Trajectory Line (dashed)
    if (strikeProgress == 0) {
      final aimPaint = Paint()
        ..color = Colors.deepPurpleAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final targetX = strikerStartX + math.cos(aimAngle) * (size.height * 0.5);
      final targetY = strikerStartY + math.sin(aimAngle) * (size.height * 0.5);
      canvas.drawLine(strikerPos, Offset(targetX, targetY), aimPaint);
      canvas.drawCircle(Offset(targetX, targetY), 5, Paint()..color = Colors.amber);
    }

    // Striker Body (Electric Purple with Lightning)
    final strikerRadius = size.width * 0.055;
    canvas.drawCircle(strikerPos.translate(2, 2), strikerRadius, Paint()..color = Colors.black38);
    final strikerPaint = Paint()..color = FriendLoopColors.violet;
    canvas.drawCircle(strikerPos, strikerRadius, strikerPaint);
    canvas.drawCircle(strikerPos, strikerRadius * 0.75, Paint()..color = Colors.white.withValues(alpha: 0.3));
    canvas.drawCircle(strikerPos, strikerRadius * 0.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CarromBoardPainter oldDelegate) => true;
}
