import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/rooms_provider.dart';
import '../../core/providers/notifications_provider.dart';
import '../../core/utils/nav_helper.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _roomNameController = TextEditingController(text: 'Evening Hangout');
  String _selectedLanguage = 'Hindi';
  final String _roomType = 'voice';
  String _access = 'public'; // 'public' or 'invite_only'
  String _activityType = 'ludo';
  double _entryFee = 0;
  bool _isLoading = false;

  static const List<String> _languages = [
    'Hindi',
    'English',
    'Telugu',
    'Tamil',
    'Kannada',
    'Malayalam',
    'Marathi',
    'Bengali',
  ];

  static const List<Map<String, dynamic>> _activities = [
    {'id': 'ludo', 'title': 'Ludo 2v2 Arena', 'icon': Icons.casino_outlined, 'desc': '2v2 team board game'},
    {'id': 'carrom', 'title': 'Carrom Clash', 'icon': Icons.sports_esports_outlined, 'desc': 'Pocket the coins'},
    {'id': 'truth_or_dare', 'title': 'Truth or Dare', 'icon': Icons.psychology_outlined, 'desc': 'Fun party questions'},
    {'id': 'voice_mimic', 'title': 'Voice Mimic', 'icon': Icons.record_voice_over_outlined, 'desc': 'Talking Tom fun'},
  ];

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final title = _roomNameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room name'), backgroundColor: FriendLoopColors.rose),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final room = await ref.read(roomsProvider.notifier).createRoom(
        title: title,
        roomType: _roomType,
        activityType: _activityType,
        language: _selectedLanguage,
        accessType: _access,
        entryFeeCoins: _entryFee.round(),
        maxSeats: _roomType == 'video' ? 6 : 12,
      );
      ref.read(notificationsProvider.notifier).addFriendRoomOrGameNotification(
        friendName: 'You',
        roomTitle: room.title,
        roomId: room.id,
        isGame: true,
        roomData: room.toJson(),
      );
      if (!mounted) return;
      context.pushReplacement('/room/${room.id}', extra: {
        ...room.toJson(),
        'is_host': true,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: FriendLoopColors.rose),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          onPressed: () => safePop(context, fallbackRoute: '/rooms'),
        ),
        title: const Text(
          'Create Room',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Name
              const Text('Room Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: TextField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Evening Hangout',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Language Dropdown
              const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
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
                    items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Select Game Grid
              const Text('Select Game to Play', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _activities.length,
                itemBuilder: (ctx, idx) {
                  final act = _activities[idx];
                  final isSelected = _activityType == act['id'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activityType = act['id'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? FriendLoopColors.lavender : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(act['icon'] as IconData, color: isSelected ? FriendLoopColors.violet : FriendLoopColors.textSecondary, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSelected ? FriendLoopColors.violet : FriendLoopColors.plum,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  act['desc'],
                                  style: const TextStyle(fontSize: 10, color: FriendLoopColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Access (Public vs Invite Only)
              const Text('Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      label: 'Public',
                      icon: Icons.public,
                      isSelected: _access == 'public',
                      onTap: () => setState(() => _access = 'public'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToggleButton(
                      label: 'Invite only',
                      icon: Icons.lock_outline,
                      isSelected: _access == 'invite_only',
                      onTap: () => setState(() => _access = 'invite_only'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Entry Fee Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Entry Fee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
                  Text(
                    _entryFee == 0 ? 'Free' : '${_entryFee.round()} Coins',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.violet, fontSize: 14),
                  ),
                ],
              ),
              Slider(
                value: _entryFee,
                min: 0,
                max: 50,
                divisions: 5,
                activeColor: FriendLoopColors.violet,
                inactiveColor: FriendLoopColors.lavender,
                onChanged: (v) => setState(() => _entryFee = v),
              ),
              const SizedBox(height: 24),

              // Create Room Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? FriendLoopColors.lavender : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? FriendLoopColors.violet : FriendLoopColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? FriendLoopColors.violet : FriendLoopColors.plum,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
