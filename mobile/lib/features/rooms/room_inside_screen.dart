import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';

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
  bool _showGameOverlay = false;
  String _activeGame = 'none';

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
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await _client.get('/rooms/${widget.roomId}');
      if (mounted) {
        setState(() {
          _room = res;
          _activeGame = res['activity_type'] ?? _activeGame;
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
              Text('Room Chat (${widget.initialRoomData?['title'] ?? 'Party'})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(leading: CircleAvatar(child: Text('R')), title: Text('Rahul'), subtitle: Text('Welcome everyone to the room! 🎉')),
                    ListTile(leading: CircleAvatar(child: Text('P')), title: Text('Priya'), subtitle: Text('Hey all! Who is playing Ludo?')),
                    ListTile(leading: CircleAvatar(child: Text('K')), title: Text('Karan'), subtitle: Text('I am in! Let’s roll! 🎲')),
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

  @override
  Widget build(BuildContext context) {
    final title = _room?['title'] ?? 'Party Room';
    final isVideo = _room?['room_type'] == 'video';
    final count = _room?['active_count'] ?? 4;

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
              '${isVideo ? 'Video' : 'Live Voice Room'} • $count in room',
              style: TextStyle(fontSize: 12, color: isVideo ? Colors.white70 : FriendLoopColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Activity / Game Button toggle
          if (_activeGame != 'none' && _activeGame != 'voice_lounge' && _activeGame != 'video_stage')
            IconButton(
              icon: const Icon(Icons.casino_outlined, color: FriendLoopColors.gold),
              onPressed: () => setState(() => _showGameOverlay = !_showGameOverlay),
            ),
          IconButton(
            icon: Icon(Icons.person_add_alt, color: isVideo ? Colors.white : FriendLoopColors.plum),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite link copied!')));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Game Arena Banner if game active
            if (_showGameOverlay || _activeGame == 'ludo' || _activeGame == 'carrom' || _activeGame == 'truth_or_dare' || _activeGame == 'voice_mimic')
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

  Widget _buildGameBanner() {
    String gameTitle = 'Party Game Active';
    String gameDesc = 'Tap to roll dice or pick card';
    IconData icon = Icons.sports_esports;

    if (_activeGame == 'ludo') {
      gameTitle = 'Ludo 2v2 Arena 🎲';
      gameDesc = 'Rahul & Priya vs Karan & Ananya';
      icon = Icons.casino;
    } else if (_activeGame == 'carrom') {
      gameTitle = 'Carrom Clash 🎯';
      gameDesc = 'White: 4 | Black: 5 | Queen in center';
      icon = Icons.adjust;
    } else if (_activeGame == 'truth_or_dare') {
      gameTitle = 'Truth or Dare 🎭';
      gameDesc = 'Turn: Karan Desai — Question: What was your most embarrassing moment?';
      icon = Icons.psychology;
    } else if (_activeGame == 'voice_mimic') {
      gameTitle = 'Voice Mimic Party 🐱';
      gameDesc = 'Pitch modifier active (+4 semitones)';
      icon = Icons.record_voice_over;
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Action taken in $gameTitle! 🎯'), backgroundColor: FriendLoopColors.success),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FriendLoopColors.gold,
              foregroundColor: FriendLoopColors.plum,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Text('Play Turn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                // Speaking indicator border
                if (p['isSpeaking'] == true)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: FriendLoopColors.brightViolet, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                // Name & Role tag
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
                        if (p['role'] == 'Host') ...[
                          const Text('👑 ', style: TextStyle(fontSize: 10)),
                        ],
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
          const SizedBox(height: 32),

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
          // Mic Toggle
          IconButton(
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? FriendLoopColors.rose : FriendLoopColors.violet),
            onPressed: () => setState(() => _isMuted = !_isMuted),
          ),
          // Camera Toggle (if Video)
          if (isVideo)
            IconButton(
              icon: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam, color: _isCameraOff ? FriendLoopColors.rose : FriendLoopColors.violet),
              onPressed: () => setState(() => _isCameraOff = !_isCameraOff),
            ),
          // In-Room Chat
          IconButton(
            icon: const Badge(
              label: Text('12'),
              child: Icon(Icons.chat_bubble_outline, color: FriendLoopColors.violet),
            ),
            onPressed: _showChatDialog,
          ),
          // Leave Button
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
