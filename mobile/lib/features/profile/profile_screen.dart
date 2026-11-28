import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/nav_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ApiClient _client = ApiClient();
  int _selectedGalleryTab = 0; // 0 = Photos, 1 = Videos
  late final PageController _heroPageController;
  Timer? _autoScrollTimer;
  int _currentHeroIndex = 0;

  final List<String> _galleryPhotos = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1511884642898-4c92249e20b6?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=800&q=80',
  ];

  final List<String> _galleryVideos = [
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
  ];

  String _lookingFor = 'Long-term relationship';
  String _distance = '84 miles away';
  String _height = 'Height: 168 cm';
  String _city = 'Bengaluru';
  String _orientation = 'Straight';

  String _pets = 'Pets: Dog lover 🐶';
  String _drinking = 'Drinking: Socially 🍷';
  String _smoking = 'Smoking: Non-smoker 🚭';
  String _workouts = 'Workouts: Regular workouts 💪';
  String _socialMedia = 'Social media: Active on Instagram 📱';

  String _zodiac = 'Zodiac: Scorpio ♏';
  String _education = 'Education: Masters Graduate 🎓';
  String _familyPlan = 'Family plan: Wants children 👶';
  String _commStyle = 'Communication style: Big texter & calls 💬';
  String _loveStyle = 'Love style: Quality time & words of affirmation 💜';

  List<String> _interests = [
    'Long walks with photography 📷',
    'Biryani 🍛',
    'Harry Potter ⚡',
  ];

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_heroPageController.hasClients) return;
      final next = (_currentHeroIndex + 1) % 3;
      _heroPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo captured from live camera! 📸'), backgroundColor: FriendLoopColors.success),
        );
      }
    } catch (_) {}
  }

  Future<void> _openGalleryUploadSheet() async {
    final captionCtrl = TextEditingController(text: 'Trekking in the Himalayas ⛰️');
    int mediaType = 0; // 0 = Photo, 1 = Video
    String access = 'Plus members only';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload to My Gallery',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Upload a file', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setModalState(() => mediaType = 0),
                          icon: const Icon(Icons.photo_outlined),
                          label: const Text('Photo'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: mediaType == 0 ? FriendLoopColors.lavender : Colors.white,
                            side: BorderSide(color: mediaType == 0 ? FriendLoopColors.violet : FriendLoopColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setModalState(() => mediaType = 1),
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('Video'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: mediaType == 1 ? FriendLoopColors.lavender : Colors.white,
                            side: BorderSide(color: mediaType == 1 ? FriendLoopColors.violet : FriendLoopColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Media Preview Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Caption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: captionCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FriendLoopColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: access,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Plus members only', child: Text('🔒 Plus members only')),
                          DropdownMenuItem(value: 'Public', child: Text('🌐 Public')),
                        ],
                        onChanged: (v) => setModalState(() => access = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: FriendLoopColors.textMuted),
                      SizedBox(width: 6),
                      Text('Your profile photo and bio stay public', style: TextStyle(fontSize: 12, color: FriendLoopColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _galleryPhotos.insert(0, 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80');
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Published to your gallery! 📷'), backgroundColor: FriendLoopColors.success),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.violet),
                      child: const Text('Publish to gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openEditSectionSheet(String title) {
    final user = ref.read(authProvider).currentUserProfile;
    final distCtrl = TextEditingController(text: _distance);
    final heightCtrl = TextEditingController(text: _height.replaceFirst('Height: ', ''));
    final cityCtrl = TextEditingController(text: user?.city ?? _city);
    String tempOrientation = _orientation;

    String tempPets = _pets.replaceFirst('Pets: ', '');
    String tempDrink = _drinking.replaceFirst('Drinking: ', '');
    String tempSmoke = _smoking.replaceFirst('Smoking: ', '');
    String tempWorkouts = _workouts.replaceFirst('Workouts: ', '');
    String tempSocial = _socialMedia.replaceFirst('Social media: ', '');

    String tempZodiac = _zodiac.replaceFirst('Zodiac: ', '');
    String tempEdu = _education.replaceFirst('Education: ', '');
    String tempFamily = _familyPlan.replaceFirst('Family plan: ', '');
    String tempComm = _commStyle.replaceFirst('Communication style: ', '');
    String tempLove = _loveStyle.replaceFirst('Love style: ', '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget content;
            if (title == 'Looking for') {
              final options = [
                'Long-term relationship',
                'Friendly chats',
                'Dating & Romance',
                'Casual hangouts',
                'Networking',
              ];
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((opt) {
                  final isSelected = _lookingFor == opt;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? FriendLoopColors.violet : Colors.grey,
                    ),
                    title: Text(opt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: FriendLoopColors.plum)),
                    trailing: isSelected ? const Icon(Icons.check, color: FriendLoopColors.violet) : null,
                    onTap: () {
                      setState(() => _lookingFor = opt);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated Looking for to "$opt"! ✨'), backgroundColor: FriendLoopColors.success),
                      );
                    },
                  );
                }).toList(),
              );
            } else if (title == 'Interests') {
              final available = [
                'Long walks with photography 📷',
                'Biryani 🍛',
                'Harry Potter ⚡',
                'Coffee Lover ☕',
                'Trekking ⛰️',
                'Music 🎵',
                'Anime 🍿',
                'Road Trips 🚗',
              ];
              content = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: available.map((item) {
                    final isSelected = _interests.contains(item);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(item),
                      selectedColor: FriendLoopColors.lavender,
                      checkmarkColor: FriendLoopColors.violet,
                      onSelected: (val) {
                        setSheetState(() {
                          setState(() {
                            if (val) {
                              _interests.add(item);
                            } else {
                              _interests.remove(item);
                            }
                          });
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            } else if (title == 'Essentials') {
              const orientations = ['Straight', 'Gay', 'Lesbian', 'Bisexual', 'Asexual', 'Prefer not to say'];

              content = SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Distance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.plum)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: distCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Height', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.plum)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: heightCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. 168 cm',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.plum)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cityCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Orientation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.plum)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: orientations.contains(tempOrientation) ? tempOrientation : orientations.first,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: orientations.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) => setSheetState(() => tempOrientation = v ?? tempOrientation),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FriendLoopColors.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final newHeight = heightCtrl.text.trim();
                          final newCity = cityCtrl.text.trim();
                          setState(() {
                            if (distCtrl.text.trim().isNotEmpty) _distance = distCtrl.text.trim();
                            if (newHeight.isNotEmpty) {
                              _height = newHeight.startsWith('Height:') ? newHeight : 'Height: $newHeight';
                            }
                            if (newCity.isNotEmpty) _city = newCity;
                            _orientation = tempOrientation;
                          });
                          if (newCity.isNotEmpty) {
                            ref.read(authProvider.notifier).updateProfile(city: newCity).catchError((_) {});
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Essentials updated! ✨'), backgroundColor: FriendLoopColors.success),
                          );
                        },
                        child: const Text('Save Essentials', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            } else if (title == 'Lifestyle') {
              const petsOpts = ['Dog lover 🐶', 'Cat lover 🐱', 'All pets 🐾', 'No pets'];
              const drinkOpts = ['Socially 🍷', 'Never', 'Frequently', 'Sober'];
              const smokeOpts = ['Non-smoker 🚭', 'Social smoker', 'Smoker'];
              const workoutOpts = ['Regular workouts 💪', 'Daily gym', 'Yoga & walks 🧘', 'Sometimes'];
              const socialOpts = ['Active on Instagram 📱', 'Occasional', 'Off social media'];

              content = SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetDropdown('Pets', tempPets, petsOpts, (v) => setSheetState(() => tempPets = v)),
                    _buildSheetDropdown('Drinking', tempDrink, drinkOpts, (v) => setSheetState(() => tempDrink = v)),
                    _buildSheetDropdown('Smoking', tempSmoke, smokeOpts, (v) => setSheetState(() => tempSmoke = v)),
                    _buildSheetDropdown('Workouts', tempWorkouts, workoutOpts, (v) => setSheetState(() => tempWorkouts = v)),
                    _buildSheetDropdown('Social media', tempSocial, socialOpts, (v) => setSheetState(() => tempSocial = v)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FriendLoopColors.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            _pets = 'Pets: $tempPets';
                            _drinking = 'Drinking: $tempDrink';
                            _smoking = 'Smoking: $tempSmoke';
                            _workouts = 'Workouts: $tempWorkouts';
                            _socialMedia = 'Social media: $tempSocial';
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lifestyle updated! ✨'), backgroundColor: FriendLoopColors.success),
                          );
                        },
                        child: const Text('Save Lifestyle', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            } else if (title == 'Basics') {
              const zodiacOpts = ['Aries ♈', 'Taurus ♉', 'Gemini ♊', 'Cancer ♋', 'Leo ♌', 'Virgo ♍', 'Libra ♎', 'Scorpio ♏', 'Sagittarius ♐', 'Capricorn ♑', 'Aquarius ♒', 'Pisces ♓'];
              const eduOpts = ['Masters Graduate 🎓', 'Bachelors Graduate', 'Doctorate / PhD', 'In College', 'High School'];
              const familyOpts = ['Wants children 👶', 'Open to children', 'No children', 'Not sure yet'];
              const commOpts = ['Big texter & calls 💬', 'Calls & deep chats 📞', 'Video calls 📹', 'In-person hangouts'];
              const loveOpts = ['Quality time & words of affirmation 💜', 'Acts of service', 'Gift giving', 'Physical touch', 'Quality time'];

              content = SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetDropdown('Zodiac', tempZodiac, zodiacOpts, (v) => setSheetState(() => tempZodiac = v)),
                    _buildSheetDropdown('Education', tempEdu, eduOpts, (v) => setSheetState(() => tempEdu = v)),
                    _buildSheetDropdown('Family plan', tempFamily, familyOpts, (v) => setSheetState(() => tempFamily = v)),
                    _buildSheetDropdown('Communication style', tempComm, commOpts, (v) => setSheetState(() => tempComm = v)),
                    _buildSheetDropdown('Love style', tempLove, loveOpts, (v) => setSheetState(() => tempLove = v)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FriendLoopColors.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            _zodiac = 'Zodiac: $tempZodiac';
                            _education = 'Education: $tempEdu';
                            _familyPlan = 'Family plan: $tempFamily';
                            _commStyle = 'Communication style: $tempComm';
                            _loveStyle = 'Love style: $tempLove';
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Basics updated! ✨'), backgroundColor: FriendLoopColors.success),
                          );
                        },
                        child: const Text('Save Basics', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              content = Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Customize your $title details in Account Settings.', style: const TextStyle(color: FriendLoopColors.textSecondary)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                        label: Text('Open Settings to Edit $title', style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FriendLoopColors.violet,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/settings');
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    Flexible(child: content),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetDropdown(
    String label,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final effectiveOptions = options.contains(currentValue) ? options : [currentValue, ...options];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.plum)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: currentValue,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: effectiveOptions
                .map((opt) => DropdownMenuItem(
                      value: opt,
                      child: Text(opt, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUserProfile;
    final displayName = user?.displayName ?? 'Ananya Sharma';
    final bio = user?.lookingFor ?? 'Travel lover, hiker and photographer. Sharing my journeys here.';
    final isPlus = user?.isPlusSubscriber ?? false;
    final coins = user?.coins ?? 120;

    final heroImages = (user?.images != null && user!.images.isNotEmpty)
        ? user.images
        : const [
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
          ];

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => safePop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined, color: FriendLoopColors.violet),
            tooltip: 'Live Camera',
            onPressed: _openCamera,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: FriendLoopColors.plum),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Photo Horizontal Carousel (Auto-scrolls without buttons)
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _heroPageController,
                        itemCount: heroImages.length,
                        onPageChanged: (idx) => setState(() => _currentHeroIndex = idx),
                        itemBuilder: (ctx, idx) {
                          return Image.network(
                            heroImages[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset('assets/telegram/wallpaper_sample.png', fit: BoxFit.cover),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Edit Photo badge
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: _openCamera,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Edit Photo',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Name & Status
                      Positioned(
                        bottom: 14,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                                if (isPlus) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FriendLoopColors.brightViolet,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('PLUS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text('last seen recently', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Edit Profile & Bio Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: FriendLoopColors.violet),
                  label: const Text(
                    'Edit Profile & Bio',
                    style: TextStyle(color: FriendLoopColors.violet, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: FriendLoopColors.violet),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Bio Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FriendLoopColors.textMuted)),
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: const Text('Edit', style: TextStyle(color: FriendLoopColors.violet, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(bio, style: const TextStyle(fontSize: 14, color: FriendLoopColors.plum, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Looking for Card
              _buildSectionCard(
                title: 'Looking for',
                icon: Icons.favorite_outline_rounded,
                onEdit: () => _openEditSectionSheet('Looking for'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EBFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FriendLoopColors.violet.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16, color: FriendLoopColors.violet),
                      const SizedBox(width: 8),
                      Text(
                        _lookingFor,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FriendLoopColors.plum),
                      ),
                    ],
                  ),
                ),
              ),

              // Essentials Card
              _buildSectionCard(
                title: 'Essentials',
                icon: Icons.person_pin_circle_outlined,
                onEdit: () => _openEditSectionSheet('Essentials'),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.near_me_outlined, _distance),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.height_rounded, _height),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.location_city_outlined, user?.city ?? _city),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.transgender_outlined, _orientation),
                  ],
                ),
              ),

              // Lifestyle Card
              _buildSectionCard(
                title: 'Lifestyle',
                icon: Icons.spa_outlined,
                onEdit: () => _openEditSectionSheet('Lifestyle'),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.pets_outlined, _pets),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.local_bar_outlined, _drinking),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.smoke_free_outlined, _smoking),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.fitness_center_outlined, _workouts),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.camera_alt_outlined, _socialMedia),
                  ],
                ),
              ),

              // Basics Card
              _buildSectionCard(
                title: 'Basics',
                icon: Icons.info_outline_rounded,
                onEdit: () => _openEditSectionSheet('Basics'),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.auto_awesome_outlined, _zodiac),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.school_outlined, _education),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.child_care_outlined, _familyPlan),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.chat_bubble_outline_rounded, _commStyle),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.favorite_border_rounded, _loveStyle),
                  ],
                ),
              ),

              // Interests Card
              _buildSectionCard(
                title: 'Interests',
                icon: Icons.interests_outlined,
                onEdit: () => _openEditSectionSheet('Interests'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interests
                      .map((interest) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4EBFC),
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                              border: Border.fromBorderSide(BorderSide(color: Color(0x406E13D8))),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: FriendLoopColors.plum,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // My Favorites Section (Favorited from Discover Friends)
              Consumer(
                builder: (context, ref, _) {
                  final favorites = ref.watch(favoritesProvider);
                  if (favorites.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: FriendLoopColors.lavender),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.star_rounded, color: FriendLoopColors.gold, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'My Favorites',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: FriendLoopColors.plum,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: FriendLoopColors.lavender,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${favorites.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: FriendLoopColors.violet,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 105,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: favorites.length,
                            itemBuilder: (ctx, idx) {
                              final fav = favorites[idx];
                              return GestureDetector(
                                onTap: () {
                                  context.push(
                                    '/friend-profile/${fav.id}',
                                    extra: FriendItem(
                                      friendshipId: fav.id,
                                      friendId: fav.id,
                                      displayName: fav.displayName,
                                      avatarUrl: fav.photo,
                                      city: fav.city,
                                      state: fav.state ?? 'India',
                                      age: fav.age,
                                      bio: fav.bio,
                                      lookingFor: fav.lookingFor,
                                      languages: fav.languages,
                                      images: fav.photos,
                                      distance: fav.distance,
                                      height: fav.height,
                                      orientation: fav.orientation,
                                      pets: fav.pets,
                                      drinking: fav.drinking,
                                      smoking: fav.smoking,
                                      workouts: fav.workouts,
                                      socialMedia: fav.socialMedia,
                                      zodiac: fav.zodiac,
                                      education: fav.education,
                                      familyPlan: fav.familyPlan,
                                      communicationStyle: fav.communicationStyle,
                                      loveStyle: fav.loveStyle,
                                      interests: fav.interests,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor: FriendLoopColors.lavender,
                                            backgroundImage: NetworkImage(fav.photo),
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.star_rounded, color: FriendLoopColors.gold, size: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        fav.displayName.split(' ').first,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: FriendLoopColors.plum,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),

              // Action Buttons Row (Wallet & Plus)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/wallet'),
                      icon: const Text('🪙'),
                      label: Text('$coins Coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: FriendLoopColors.violet),
                        foregroundColor: FriendLoopColors.violet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/plus'),
                      icon: const Icon(Icons.star, color: Colors.white, size: 18),
                      label: Text(isPlus ? 'Plus Active' : 'Get Plus', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FriendLoopColors.plum,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // My Gallery Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Gallery',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: FriendLoopColors.plum),
                  ),
                  // Tabs: Photos / Videos
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FriendLoopColors.border),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedGalleryTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedGalleryTab == 0 ? FriendLoopColors.lavender : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedGalleryTab == 0 ? FontWeight.bold : FontWeight.normal,
                                color: _selectedGalleryTab == 0 ? FriendLoopColors.violet : FriendLoopColors.plum,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedGalleryTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedGalleryTab == 1 ? FriendLoopColors.lavender : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Videos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedGalleryTab == 1 ? FontWeight.bold : FontWeight.normal,
                                color: _selectedGalleryTab == 1 ? FriendLoopColors.violet : FriendLoopColors.plum,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4-grid Gallery Tiles
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _selectedGalleryTab == 0 ? _galleryPhotos.length : _galleryVideos.length,
                itemBuilder: (ctx, idx) {
                  final url = _selectedGalleryTab == 0 ? _galleryPhotos[idx] : _galleryVideos[idx];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: FriendLoopColors.lavender,
                            child: const Icon(Icons.image, color: FriendLoopColors.violet),
                          ),
                        ),
                        if (_selectedGalleryTab == 1)
                          const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // + Upload photo or video Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openGalleryUploadSheet,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Upload photo or video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Plus banner card
              GestureDetector(
                onTap: () => context.push('/plus'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FriendLoopColors.lavender),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.all_inclusive, color: FriendLoopColors.violet, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Plus • ₹350/month',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: FriendLoopColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE6F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: FriendLoopColors.lavender.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: FriendLoopColors.violet),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onEdit ?? () => context.push('/settings'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EBF9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 13, color: FriendLoopColors.violet),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: FriendLoopColors.violet,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  static Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: FriendLoopColors.violet),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: FriendLoopColors.plum,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
