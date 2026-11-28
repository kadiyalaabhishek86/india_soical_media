import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class LudoPartyGameView extends StatefulWidget {
  final VoidCallback? onBack;
  final Map<String, dynamic>? roomData;
  final bool isPublicViewer;
  final void Function(String winnerName, String summary)? onGameFinished;

  const LudoPartyGameView({
    super.key,
    this.onBack,
    this.roomData,
    this.isPublicViewer = false,
    this.onGameFinished,
  });

  @override
  State<LudoPartyGameView> createState() => _LudoPartyGameViewState();
}

class _LudoPartyGameViewState extends State<LudoPartyGameView> with SingleTickerProviderStateMixin {
  int _diceNumber = 6;
  bool _isRolling = false;
  int _selectedPawn = 2; // 1 = Pawn #1, 2 = Pawn #2
  int _violetHome = 2;
  int _rivalsHome = 1;
  int _turnSeconds = 9;
  int _pawn2Step = 4; // track step
  int _pawn1Step = -1; // -1 = yard, >=0 = deployed
  int _coins = 40;
  String _activeBanter = 'Partner, protect me! 🛡️';
  bool _hasRolled = true;
  bool _hasEnded = false;

  late AnimationController _diceController;

  @override
  void initState() {
    super.initState();
    _diceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _diceController.dispose();
    super.dispose();
  }

  void _rollDice() {
    if (widget.isPublicViewer || _isRolling || _hasEnded) return;
    setState(() => _isRolling = true);
    _diceController.forward(from: 0).then((_) {
      if (!mounted) return;
      final roll = math.Random().nextInt(6) + 1;
      setState(() {
        _isRolling = false;
        _diceNumber = roll;
        _hasRolled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎲 You rolled a $roll! ✨'),
          backgroundColor: FriendLoopColors.brightViolet,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  void _advancePawn() {
    if (widget.isPublicViewer || _hasEnded) return;
    setState(() {
      if (_selectedPawn == 1) {
        if (_diceNumber == 6 && _pawn1Step == -1) {
          _pawn1Step = 0; // deployed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚀 Pawn #1 deployed onto the board! ⭐'),
              backgroundColor: FriendLoopColors.success,
              duration: Duration(seconds: 1),
            ),
          );
        } else if (_pawn1Step >= 0) {
          _pawn1Step = (_pawn1Step + _diceNumber) % 52;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🚀 Pawn #1 advanced by $_diceNumber steps! ⭐'),
              backgroundColor: FriendLoopColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        _pawn2Step = (_pawn2Step + _diceNumber) % 52;
        if (_pawn2Step == 0 || _pawn2Step == 6) {
          _violetHome += 1;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚀 Pawn #2 advanced by $_diceNumber steps into Safe Zone! ⭐'),
            backgroundColor: FriendLoopColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
    if (_violetHome >= 4 && !_hasEnded) {
      _hasEnded = true;
      widget.onGameFinished?.call(
        'Team Violet (You & Priya)',
        'All pawns reached Home ($_violetHome/4)!',
      );
    }
  }

  void _sendGift(String name, int cost) {
    if (_coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
      return;
    }
    setState(() => _coins -= cost);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎁 Sent $name to the Ludo Table! (-$cost coins)'), backgroundColor: Colors.pink),
    );
  }

  List<Map<String, dynamic>> _getPlayers() {
    final participants = widget.roomData?['participants'] as List?;
    if (participants != null && participants.length >= 4) {
      return [
        {
          'name': participants[0]['name'] ?? 'Rhea',
          'avatar': participants[0]['image'] ?? participants[0]['avatar'],
          'color': const Color(0xFFEF4444),
          'team': 'TEAM VIOLET',
          'teamSub': 'Team Red & Yellow',
          'dots': '🔴🟡',
          'isTurn': true,
        },
        {
          'name': participants[1]['name'] ?? 'Rohan',
          'avatar': participants[1]['image'] ?? participants[1]['avatar'],
          'color': const Color(0xFF22C55E),
          'team': 'RIVALS',
          'teamSub': 'Team Green & Blue',
          'dots': '🟢🔵',
          'isTurn': false,
        },
        {
          'name': participants[2]['name'] ?? 'Ananya',
          'avatar': participants[2]['image'] ?? participants[2]['avatar'],
          'color': const Color(0xFF3B82F6),
          'team': 'RIVALS',
          'teamSub': 'Team Green & Blue',
          'dots': '🟢🔵',
          'isTurn': false,
        },
        {
          'name': participants[3]['name'] ?? 'Priya',
          'avatar': participants[3]['image'] ?? participants[3]['avatar'],
          'color': const Color(0xFFF59E0B),
          'team': 'TEAM VIOLET',
          'teamSub': 'Team Red & Yellow',
          'dots': '🔴🟡',
          'isTurn': false,
        },
      ];
    }
    return [
      {
        'name': 'Rhea',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        'color': const Color(0xFFEF4444),
        'team': 'TEAM VIOLET',
        'teamSub': 'Team Red & Yellow',
        'dots': '🔴🟡',
        'isTurn': true,
      },
      {
        'name': 'Rohan',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        'color': const Color(0xFF22C55E),
        'team': 'RIVALS',
        'teamSub': 'Team Green & Blue',
        'dots': '🟢🔵',
        'isTurn': false,
      },
      {
        'name': 'Ananya',
        'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
        'color': const Color(0xFF3B82F6),
        'team': 'RIVALS',
        'teamSub': 'Team Green & Blue',
        'dots': '🟢🔵',
        'isTurn': false,
      },
      {
        'name': 'Priya',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
        'color': const Color(0xFFF59E0B),
        'team': 'TEAM VIOLET',
        'teamSub': 'Team Red & Yellow',
        'dots': '🔴🟡',
        'isTurn': false,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final players = _getPlayers();

    return Container(
      color: const Color(0xFFF7F2FD), // Lavender canvas matching mockup
      child: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildTopNavBar(context),

            // Scrollable Content to prevent any overflow on 320px
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    // Header: "Ludo with Friends" & "Table 12 • 2 vs 2"
                    _buildGameHeader(),
                    const SizedBox(height: 10),

                    // Top Two Players (Seats above the board)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: _buildPlayerSeat(
                            player: players[0],
                            isTop: true,
                            isLeft: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: _buildPlayerSeat(
                            player: players[1],
                            isTop: true,
                            isLeft: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Square Ludo Board (Full 4-yard classic board)
                    _buildLudoBoardContainer(),
                    const SizedBox(height: 10),

                    // Bottom Two Players (Seats below the board)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: _buildPlayerSeat(
                            player: players[2],
                            isTop: false,
                            isLeft: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: _buildPlayerSeat(
                            player: players[3],
                            isTop: false,
                            isLeft: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (!widget.isPublicViewer) ...[
                      // Next Action Panel (Matching Mockup with 3D dice, text, and primary action button)
                      _buildActionPanel(),
                      const SizedBox(height: 12),

                      // Pawn Selection Cards (Deploy Pawn #1 / Move Pawn #2)
                      _buildPawnActionCards(),
                      const SizedBox(height: 12),
                    ],

                    // Voice Chat Pill
                    _buildVoiceChatBar(),
                    const SizedBox(height: 12),

                    // Quick Table Banter
                    _buildTableBanter(),
                    const SizedBox(height: 10),

                    // Send Gifts Row
                    _buildSendGiftRow(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
                onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              Image.asset(
                'assets/images/friendloop_logo.png',
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Row(
                  children: [
                    Icon(Icons.all_inclusive_rounded, color: FriendLoopColors.violet, size: 22),
                    SizedBox(width: 6),
                    Text('FriendLoop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined, color: FriendLoopColors.plum, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite friend link copied! 🔗')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: FriendLoopColors.plum, size: 22),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader() {
    return Column(
      children: [
        const Text(
          'Ludo with Friends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: FriendLoopColors.plum,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE9DCF8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'TABLE #12 • 2 vs 2',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: FriendLoopColors.plum,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSeat({
    required Map<String, dynamic> player,
    required bool isTop,
    required bool isLeft,
  }) {
    final bool isTurn = player['isTurn'] == true;
    final Color ringColor = player['color'] as Color;
    final String name = player['name'] as String;
    final String team = player['team'] as String;
    final String teamSub = player['teamSub'] as String;
    final String dots = player['dots'] as String;
    final String? avatarUrl = player['avatar'] as String?;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with colored team ring
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 2.8),
            boxShadow: isTurn
                ? [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitialsAvatar(name, ringColor),
                  )
                : _buildInitialsAvatar(name, ringColor),
          ),
        ),
        const SizedBox(width: 8),

        // Name, Team, and Turn Badge
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: FriendLoopColors.plum,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dots, style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      isLeft && isTop ? team : teamSub,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: FriendLoopColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (isTurn) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: FriendLoopColors.violet,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Your turn',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String name, Color color) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildLudoBoardContainer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep board square and properly bounded for narrow screens
        final double maxAvailable = math.min(constraints.maxWidth, 360.0);
        final double boardSize = maxAvailable > 270.0 ? maxAvailable : 270.0;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDDD2F3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(
                painter: _ClassicLudoBoardPainter(
                  pawn1Step: _pawn1Step,
                  pawn2Step: _pawn2Step,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionPanel() {
    final bool canDeploy = _diceNumber == 6 && _pawn1Step == -1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9DCF8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3D White Animated Dice
          GestureDetector(
            onTap: _rollDice,
            child: AnimatedBuilder(
              animation: _diceController,
              builder: (context, child) {
                final rot = _diceController.value * math.pi * 2;
                return Transform.rotate(
                  angle: rot,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDDD2F3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: FriendLoopColors.violet.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getDiceDots(_diceNumber),
                        style: const TextStyle(
                          fontSize: 34,
                          color: FriendLoopColors.violet,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),

          // Action Texts and Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hasRolled ? 'You rolled a $_diceNumber' : 'Your turn to roll 🎲',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: FriendLoopColors.plum,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canDeploy
                      ? 'Tap a pawn to bring it onto the board'
                      : 'Choose a pawn to advance on the board',
                  style: const TextStyle(
                    fontSize: 11,
                    color: FriendLoopColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Primary Button
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FriendLoopColors.violet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () {
                      if (!_hasRolled) {
                        _rollDice();
                      } else {
                        _advancePawn();
                      }
                    },
                    child: Text(
                      !_hasRolled
                          ? 'Roll dice 🎲'
                          : (canDeploy && _selectedPawn == 1
                              ? 'Deploy pawn • ADVANCE PAWN'
                              : 'DEPLOY / ADVANCE PAWN'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPawnActionCards() {
    return Row(
      children: [
        // Pawn #1 Card (Deploy)
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPawn = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedPawn == 1 ? FriendLoopColors.lavender : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedPawn == 1 ? FriendLoopColors.violet : const Color(0xFFE2DCF0),
                  width: _selectedPawn == 1 ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  _buildPawnBadge('1', isDeployed: _pawn1Step >= 0),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deploy Pawn #1',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _pawn1Step == -1 ? 'In Yard (Needs 6)' : 'On Track (Step $_pawn1Step)',
                          style: const TextStyle(fontSize: 9, color: FriendLoopColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Pawn #2 Card (Move)
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPawn = 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedPawn == 2 ? FriendLoopColors.lavender : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedPawn == 2 ? FriendLoopColors.violet : const Color(0xFFE2DCF0),
                  width: _selectedPawn == 2 ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  _buildPawnBadge('2', isDeployed: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Move Pawn #2',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Track Step #$_pawn2Step (Safe)',
                          style: const TextStyle(fontSize: 9, color: FriendLoopColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPawnBadge(String num, {required bool isDeployed}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          num,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildVoiceChatBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: FriendLoopColors.violet,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '4 friends in voice chat • 4/4 Live Voice',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: FriendLoopColors.plum,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.graphic_eq, color: FriendLoopColors.violet, size: 20),
        ],
      ),
    );
  }

  Widget _buildTableBanter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'QUICK TABLE BANTER: $_activeBanter',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Text('✏️ Tap to send', style: TextStyle(fontSize: 9, color: FriendLoopColors.violet, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildBanterChip('Partner, protect me! 🛡️'),
            const SizedBox(width: 6),
            _buildBanterChip('Kill that token! ⚔️'),
            const SizedBox(width: 6),
            _buildBanterChip('Unbelievable! 🍀'),
          ],
        ),
      ],
    );
  }

  Widget _buildBanterChip(String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeBanter = text);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent: $text'), duration: const Duration(seconds: 1)));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD5EE)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildSendGiftRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SEND GIFT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.textMuted)),
            Text('Balance: ${_coins}c', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildGiftItem('🌹', 'Rose', 1),
            const SizedBox(width: 6),
            _buildGiftItem('☕', 'Chai', 5),
            const SizedBox(width: 6),
            _buildGiftItem('🍅', 'Tomato', 2),
            const SizedBox(width: 6),
            _buildGiftItem('🏆', 'Trophy', 10),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('${cost}c', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.pink)),
            ],
          ),
        ),
      ),
    );
  }

  String _getDiceDots(int num) {
    switch (num) {
      case 1:
        return '⚀';
      case 2:
        return '⚁';
      case 3:
        return '⚂';
      case 4:
        return '⚃';
      case 5:
        return '⚄';
      default:
        return '⚅';
    }
  }
}

/// CustomPainter that renders the complete, authentic 15x15 classic Ludo Board
class _ClassicLudoBoardPainter extends CustomPainter {
  final int pawn1Step;
  final int pawn2Step;

  _ClassicLudoBoardPainter({
    required this.pawn1Step,
    required this.pawn2Step,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 15.0;

    final redColor = const Color(0xFFEF4444);
    final greenColor = const Color(0xFF22C55E);
    final blueColor = const Color(0xFF3B82F6);
    final yellowColor = const Color(0xFFEAB308);

    final borderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Draw 15x15 Track Grid
    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 15; c++) {
        // Skip yard areas and center 3x3 to paint separately
        if ((r < 6 && c < 6) ||
            (r < 6 && c > 8) ||
            (r > 8 && c < 6) ||
            (r > 8 && c > 8) ||
            (r >= 6 && r <= 8 && c >= 6 && c <= 8)) {
          continue;
        }

        final cellRect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);

        // Check if home paths or starting squares
        Color fillColor = Colors.white;

        // Red track
        if (r == 7 && c >= 1 && c <= 5) fillColor = redColor;
        if (r == 6 && c == 1) fillColor = const Color(0xFFFCA5A5); // Red start

        // Green track
        if (c == 7 && r >= 1 && r <= 5) fillColor = greenColor;
        if (r == 1 && c == 8) fillColor = const Color(0xFF86EFAC); // Green start

        // Yellow track
        if (r == 7 && c >= 9 && c <= 13) fillColor = yellowColor;
        if (r == 8 && c == 13) fillColor = const Color(0xFFFDE047); // Yellow start

        // Blue track
        if (c == 7 && r >= 9 && r <= 13) fillColor = blueColor;
        if (r == 13 && c == 6) fillColor = const Color(0xFF93C5FD); // Blue start

        canvas.drawRect(cellRect, Paint()..color = fillColor);
        canvas.drawRect(cellRect, borderPaint);
      }
    }

    // 2. Draw 4 Yards
    _drawYard(canvas, 0, 0, 6 * cellSize, redColor, const [true, true, true, false]);
    _drawYard(canvas, 9 * cellSize, 0, 6 * cellSize, greenColor, const [false, false, false, false]);
    _drawYard(canvas, 0, 9 * cellSize, 6 * cellSize, blueColor, const [false, false, false, false]);
    _drawYard(canvas, 9 * cellSize, 9 * cellSize, 6 * cellSize, yellowColor, const [false, false, false, false]);

    // 3. Draw Center 3x3 Triangles
    final centerRect = Rect.fromLTWH(6 * cellSize, 6 * cellSize, 3 * cellSize, 3 * cellSize);
    final centerPoint = Offset(centerRect.left + centerRect.width / 2, centerRect.top + centerRect.height / 2);

    // Left triangle: Red
    final redPath = Path()
      ..moveTo(centerRect.left, centerRect.top)
      ..lineTo(centerRect.left, centerRect.bottom)
      ..lineTo(centerPoint.dx, centerPoint.dy)
      ..close();
    canvas.drawPath(redPath, Paint()..color = redColor);

    // Top triangle: Green
    final greenPath = Path()
      ..moveTo(centerRect.left, centerRect.top)
      ..lineTo(centerRect.right, centerRect.top)
      ..lineTo(centerPoint.dx, centerPoint.dy)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = greenColor);

    // Right triangle: Yellow
    final yellowPath = Path()
      ..moveTo(centerRect.right, centerRect.top)
      ..lineTo(centerRect.right, centerRect.bottom)
      ..lineTo(centerPoint.dx, centerPoint.dy)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = yellowColor);

    // Bottom triangle: Blue
    final bluePath = Path()
      ..moveTo(centerRect.left, centerRect.bottom)
      ..lineTo(centerRect.right, centerRect.bottom)
      ..lineTo(centerPoint.dx, centerPoint.dy)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = blueColor);

    canvas.drawRect(centerRect, borderPaint);

    // 4. Draw Active Deployed Pawns
    // Red Pawn #2 on Red starting square or track
    final pawn2Offset = Offset(1.5 * cellSize, 6.5 * cellSize);
    _drawPawnOnTrack(canvas, pawn2Offset, redColor, '2', isSelected: true);
  }

  void _drawYard(Canvas canvas, double x, double y, double size, Color color, List<bool> hasPawns) {
    final yardRect = Rect.fromLTWH(x, y, size, size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(yardRect, const Radius.circular(16)),
      Paint()..color = color,
    );

    final innerPadding = size * 0.16;
    final innerRect = Rect.fromLTWH(
      x + innerPadding,
      y + innerPadding,
      size - innerPadding * 2,
      size - innerPadding * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(14)),
      Paint()..color = Colors.white,
    );

    // 4 circular spots
    final spotRadius = size * 0.11;
    final spots = [
      Offset(innerRect.left + innerRect.width * 0.28, innerRect.top + innerRect.height * 0.28),
      Offset(innerRect.right - innerRect.width * 0.28, innerRect.top + innerRect.height * 0.28),
      Offset(innerRect.left + innerRect.width * 0.28, innerRect.bottom - innerRect.height * 0.28),
      Offset(innerRect.right - innerRect.width * 0.28, innerRect.bottom - innerRect.height * 0.28),
    ];

    for (int i = 0; i < 4; i++) {
      final spot = spots[i];
      canvas.drawCircle(
        spot,
        spotRadius,
        Paint()..color = color.withValues(alpha: 0.25),
      );

      // If yard has pawn, draw glossy pawn
      if (i < hasPawns.length && hasPawns[i]) {
        _drawPawnPiece(canvas, spot, color, (i + 1).toString());
      }
    }
  }

  void _drawPawnPiece(Canvas canvas, Offset center, Color color, String label) {
    // Halo shadow
    canvas.drawCircle(
      center.translate(0, 2),
      12,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    // 3D glossy pawn body
    final grad = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [Colors.white, color, Color.lerp(color, Colors.black, 0.4)!],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawCircle(
      center,
      11,
      Paint()..shader = grad.createShader(Rect.fromCircle(center: center, radius: 11)),
    );

    // Highlight dot
    canvas.drawCircle(
      center.translate(-3, -3),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  void _drawPawnOnTrack(Canvas canvas, Offset center, Color color, String label, {bool isSelected = false}) {
    // Glowing halo for selected active pawn
    if (isSelected) {
      canvas.drawCircle(
        center,
        18,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    _drawPawnPiece(canvas, center, color, label);
  }

  @override
  bool shouldRepaint(covariant _ClassicLudoBoardPainter oldDelegate) {
    return oldDelegate.pawn1Step != pawn1Step || oldDelegate.pawn2Step != pawn2Step;
  }
}
