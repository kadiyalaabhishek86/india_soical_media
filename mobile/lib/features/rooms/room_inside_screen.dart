import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import 'games/carrom_clash_game_view.dart';
import 'games/voice_mimic_party_view.dart';
import 'games/truth_or_dare_game_view.dart';
import 'games/ludo_party_game_view.dart';

class RoomInsideScreen extends ConsumerStatefulWidget {
  final String roomId;
  final Map<String, dynamic>? initialRoomData;

  const RoomInsideScreen({
    super.key,
    required this.roomId,
    this.initialRoomData,
  });

  @override
  ConsumerState<RoomInsideScreen> createState() => _RoomInsideScreenState();
}

class _RoomInsideScreenState extends ConsumerState<RoomInsideScreen> {
  final ApiClient _client = ApiClient();
  Map<String, dynamic>? _room;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeaker = false;
  String _activeGame = 'none';
  int _viewMode = 0; // 0 = Game Arena, 1 = Room Stage

  final List<Map<String, dynamic>> _mockVideoParticipants = [
    {
      'name': 'Rahul Singh',
      'role': 'Host',
      'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      'isSpeaking': true,
    },
    {
      'name': 'Priya Nair',
      'role': 'Speaker',
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      'isSpeaking': false,
    },
    {
      'name': 'Karan Desai',
      'role': 'Speaker',
      'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
      'isSpeaking': false,
    },
    {
      'name': 'Ananya Gupta',
      'role': 'Speaker',
      'image': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
      'isSpeaking': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoomData;
    _activeGame = _room?['activity_type'] ?? 'none';
    if (_activeGame == 'carrom' || _activeGame == 'ludo' || _activeGame == 'truth_or_dare' || _activeGame == 'voice_mimic') {
      _viewMode = 0; // Default to Game Arena if a game activity is selected
    } else {
      _viewMode = 1; // Default to Room Stage for voice_lounge or video_stage
    }
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await _client.get('/rooms/${widget.roomId}');
      if (mounted && res is Map<String, dynamic>) {
        setState(() {
          _room = res;
          if (_activeGame == 'none') {
            _activeGame = res['activity_type'] ?? 'carrom';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _requestToSpeak() async {
    try {
      await _client.post('/rooms/${widget.roomId}/request-speak');
      setState(() => _isSpeaker = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now a speaker! 🎙️'), backgroundColor: FriendLoopColors.success),
      );
    } catch (_) {}
  }

  Future<void> _handleLeave() async {
    try {
      await _client.post('/rooms/${widget.roomId}/leave');
    } catch (_) {}
    if (mounted) context.pop();
  }

  void _showGameSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Party Game', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Text('🎯', style: TextStyle(fontSize: 26)),
              title: const Text('Carrom Clash', style: TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              subtitle: const Text('Pocket coins & queen for 20 coin pot'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _activeGame = 'carrom';
                  _viewMode = 0;
                });
              },
            ),
            ListTile(
              leading: const Text('🐱', style: TextStyle(fontSize: 26)),
              title: const Text('Voice Mimic (Talking Tom)', style: TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              subtitle: const Text('Helium pitch voice mimic & SFX soundboard'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _activeGame = 'voice_mimic';
                  _viewMode = 0;
                });
              },
            ),
            ListTile(
              leading: const Text('🍾', style: TextStyle(fontSize: 26)),
              title: const Text('Truth or Dare (Spin the Bottle)', style: TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              subtitle: const Text('Spin bottle, confess romance secrets or dares'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _activeGame = 'truth_or_dare';
                  _viewMode = 0;
                });
              },
            ),
            ListTile(
              leading: const Text('🎲', style: TextStyle(fontSize: 26)),
              title: const Text('Ludo 2v2 Arena', style: TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
              subtitle: const Text('2v2 team board game with 3D dice rolls'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _activeGame = 'ludo';
                  _viewMode = 0;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 16, left: 16, right: 16),
        child: SizedBox(
          height: 380,
          child: Column(
            children: [
              Text('Room Chat (${_room?['title'] ?? 'Party'})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(leading: CircleAvatar(child: Text('R')), title: Text('Rahul'), subtitle: Text('Welcome everyone to the room! 🎉')),
                    ListTile(leading: CircleAvatar(child: Text('P')), title: Text('Priya'), subtitle: Text('Hey all! Who is playing with us?')),
                    ListTile(leading: CircleAvatar(child: Text('K')), title: Text('Karan'), subtitle: Text('I am in! Let’s go! 🎯')),
                  ],
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Send message to room...',
                  suffixIcon: const Icon(Icons.send, color: FriendLoopColors.violet),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportRoomDialog() {
    final reasons = [
      'Inappropriate audio or video',
      'Underage participants (Minor safety)',
      'Harassment or abusive speech',
      'Spam or deceptive behavior',
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Room', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report "${_room?['title'] ?? 'Party Room'}" to 24/7 moderation:', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            ...reasons.map(
              (r) => ListTile(
                title: Text(r, style: const TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _client.post(
                      '/moderation/report',
                      body: {
                        'target_type': 'room',
                        'target_id': widget.roomId,
                        'reason': r,
                      },
                    );
                  } catch (_) {}
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Room reported. Our safety team is actively investigating.'),
                        backgroundColor: FriendLoopColors.violet,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlockHost() {
    final hostId = _room?['host_id'] ?? 'host_user';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Host?'),
        content: const Text('Are you sure you want to block the host of this room? You will leave the room and their content will be hidden from you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _client.post(
                  ApiEndpoints.block,
                  body: {'blocked_id': hostId},
                );
              } catch (_) {}
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Host has been blocked.'), backgroundColor: FriendLoopColors.rose),
                );
                _handleLeave();
              }
            },
            child: const Text('Block & Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _room?['title'] ?? 'Party Room';
    final isVideo = _room?['room_type'] == 'video';
    final count = _room?['active_count'] ?? 4;

    // Check if an interactive game is selected and user is in Game Arena mode
    final isGameActive = _activeGame == 'carrom' ||
        _activeGame == 'voice_mimic' ||
        _activeGame == 'truth_or_dare' ||
        _activeGame == 'ludo';

    if (_viewMode == 0 && isGameActive) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F7FC),
        body: Column(
          children: [
            // Mode Switcher Banner (Game Arena vs Stage)
            _buildViewModeToggle(),

            // Active Game Screen
            Expanded(
              child: _buildActiveGameView(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isVideo ? Colors.black : FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isVideo ? Colors.white : FriendLoopColors.plum),
          onPressed: _handleLeave,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isVideo ? Colors.white : FriendLoopColors.plum),
            ),
            Text(
              '${isVideo ? 'Video Stage' : 'Live Voice Room'} • $count in room',
              style: TextStyle(fontSize: 12, color: isVideo ? Colors.white70 : FriendLoopColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Game Controller icon to launch/switch games
          IconButton(
            icon: const Icon(Icons.sports_esports, color: FriendLoopColors.violet),
            tooltip: 'Choose Party Game',
            onPressed: _showGameSelector,
          ),
          IconButton(
            icon: Icon(Icons.person_add_alt, color: isVideo ? Colors.white : FriendLoopColors.plum),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite link copied!')));
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isVideo ? Colors.white : FriendLoopColors.plum),
            onSelected: (val) async {
              if (val == 'report') {
                _showReportRoomDialog();
              } else if (val == 'block') {
                _confirmBlockHost();
              } else if (val == 'safety') {
                final url = Uri.parse('${ApiEndpoints.rootUrl}/child-safety');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20, color: Colors.amber),
                    SizedBox(width: 10),
                    Text('Report Room'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: FriendLoopColors.rose),
                    SizedBox(width: 10),
                    Text('Block Host', style: TextStyle(color: FriendLoopColors.rose)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'safety',
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20, color: FriendLoopColors.violet),
                    SizedBox(width: 10),
                    Text('Child Safety (18+)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top toggle between Game Arena and Room Stage
            _buildViewModeToggle(),

            // Game Banner if game selected
            if (isGameActive)
              _buildGameBanner(),

            // Main Room Content
            Expanded(
              child: isVideo ? _buildVideoGrid() : _buildVoiceStage(),
            ),

            // Bottom Controller Bar
            _buildBottomControls(isVideo),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeGame == 'none') {
                  _activeGame = 'carrom';
                }
                setState(() => _viewMode = 0);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _viewMode == 0 ? FriendLoopColors.violet : const Color(0xFFF3EDFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_esports, size: 16, color: _viewMode == 0 ? Colors.white : FriendLoopColors.plum),
                    const SizedBox(width: 6),
                    Text(
                      '🎮 Game Arena',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 0 ? Colors.white : FriendLoopColors.plum),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _viewMode == 1 ? FriendLoopColors.violet : const Color(0xFFF3EDFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, size: 16, color: _viewMode == 1 ? Colors.white : FriendLoopColors.plum),
                    const SizedBox(width: 6),
                    Text(
                      '🎙️ Room Stage',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 1 ? Colors.white : FriendLoopColors.plum),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.tune, color: FriendLoopColors.violet, size: 20),
            tooltip: 'Switch Game',
            onPressed: _showGameSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGameView() {
    switch (_activeGame) {
      case 'carrom':
        return CarromClashGameView(onBack: _handleLeave, roomData: _room);
      case 'voice_mimic':
        return VoiceMimicPartyView(onBack: _handleLeave, roomData: _room);
      case 'truth_or_dare':
        return TruthOrDareGameView(onBack: _handleLeave, roomData: _room);
      case 'ludo':
        return LudoPartyGameView(onBack: _handleLeave, roomData: _room);
      default:
        return CarromClashGameView(onBack: _handleLeave, roomData: _room);
    }
  }

  Widget _buildGameBanner() {
    String gameTitle = 'Party Game Active';
    String gameDesc = 'Tap to play in full screen';
    IconData icon = Icons.sports_esports;

    if (_activeGame == 'carrom') {
      gameTitle = 'Carrom Clash 🎯';
      gameDesc = 'Match #408 • 20 Coin Pot • Striker Ready!';
      icon = Icons.adjust;
    } else if (_activeGame == 'voice_mimic') {
      gameTitle = 'Voice Mimic Party 🐱';
      gameDesc = 'Party #104 • Talking Tom Squeak Active!';
      icon = Icons.record_voice_over;
    } else if (_activeGame == 'truth_or_dare') {
      gameTitle = 'Truth or Dare 🍾';
      gameDesc = 'Party #104 • Flirt & Crush • Spin the Bottle!';
      icon = Icons.psychology;
    } else if (_activeGame == 'ludo') {
      gameTitle = 'Ludo 2v2 Arena 🎲';
      gameDesc = 'Table #12 • Team Violet vs Rivals • Roll a 6!';
      icon = Icons.casino;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FriendLoopColors.plum,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FriendLoopColors.gold),
      ),
      child: Row(
        children: [
          Icon(icon, color: FriendLoopColors.gold, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gameTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(gameDesc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() => _viewMode = 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: FriendLoopColors.gold,
              foregroundColor: FriendLoopColors.plum,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Text('Play Arena >>', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _mockVideoParticipants.length,
        itemBuilder: (ctx, idx) {
          final p = _mockVideoParticipants[idx];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(p['image'], fit: BoxFit.cover),
                if (p['isSpeaking'] == true)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: FriendLoopColors.brightViolet, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (p['role'] == 'Host') const Text('👑 ', style: TextStyle(fontSize: 10)),
                        Expanded(
                          child: Text(
                            p['name'],
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(p['isSpeaking'] == true ? Icons.mic : Icons.mic_off, color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoiceStage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Host Section
          const Text('👑 Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildVoiceParticipantCircle(
                name: 'Vamshi K',
                avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
                isSpeaking: true,
                badge: 'Host',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Speakers Section
          const Text('🎙️ Speakers (2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildVoiceParticipantCircle(
                name: 'Ananya R',
                avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
                isSpeaking: false,
              ),
              const SizedBox(width: 16),
              _buildVoiceParticipantCircle(
                name: 'Karthik M',
                avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
                isSpeaking: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Listeners Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🎧 Listeners (24)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(color: FriendLoopColors.violet, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _buildListenerAvatar('Pooja S'),
              _buildListenerAvatar('Rohit V'),
              _buildListenerAvatar('Divya K'),
              _buildListenerAvatar('Arjun P'),
            ],
          ),
          const SizedBox(height: 24),

          // Request to Speak Button
          if (!_isSpeaker)
            Center(
              child: SizedBox(
                width: 220,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _requestToSpeak,
                  icon: const Icon(Icons.pan_tool_outlined, color: FriendLoopColors.violet),
                  label: const Text('Request to Speak', style: TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.violet)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: FriendLoopColors.violet, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceParticipantCircle({required String name, required String avatar, required bool isSpeaking, String? badge}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSpeaking ? FriendLoopColors.onlineGreen : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(avatar),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: FriendLoopColors.onlineGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FriendLoopColors.plum)),
      ],
    );
  }

  Widget _buildListenerAvatar(String name) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: FriendLoopColors.lavender,
          child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 11, color: FriendLoopColors.textSecondary)),
      ],
    );
  }

  Widget _buildBottomControls(bool isVideo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isVideo ? Colors.grey[900] : Colors.white,
        border: const Border(top: BorderSide(color: FriendLoopColors.border, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? FriendLoopColors.rose : FriendLoopColors.violet),
            onPressed: () => setState(() => _isMuted = !_isMuted),
          ),
          if (isVideo)
            IconButton(
              icon: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam, color: _isCameraOff ? FriendLoopColors.rose : FriendLoopColors.violet),
              onPressed: () => setState(() => _isCameraOff = !_isCameraOff),
            ),
          IconButton(
            icon: const Icon(Icons.sports_esports, color: FriendLoopColors.violet),
            tooltip: 'Choose Party Game',
            onPressed: _showGameSelector,
          ),
          IconButton(
            icon: const Badge(
              label: Text('12'),
              child: Icon(Icons.chat_bubble_outline, color: FriendLoopColors.violet),
            ),
            onPressed: _showChatDialog,
          ),
          ElevatedButton.icon(
            onPressed: _handleLeave,
            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 16),
            label: const Text('Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: FriendLoopColors.rose,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
