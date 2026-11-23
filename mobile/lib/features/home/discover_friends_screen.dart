import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/constants/indian_states.dart';
import '../../shared/widgets/demo_banner.dart';

class DiscoverFriendsScreen extends ConsumerStatefulWidget {
  const DiscoverFriendsScreen({super.key});

  @override
  ConsumerState<DiscoverFriendsScreen> createState() => _DiscoverFriendsScreenState();
}

class _DiscoverFriendsScreenState extends ConsumerState<DiscoverFriendsScreen> {
  int _currentProfileIndex = 0;
  String _selectedCity = 'All Cities';
  String _selectedLanguage = 'All Languages';

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  static const List<Map<String, dynamic>> _allProfiles = [
    {
      'id': 'user-ananya',
      'name': 'Ananya Reddy, 26',
      'displayName': 'Ananya Reddy',
      'age': 26,
      'gender': 'Female',
      'location': 'Hyderabad',
      'state': 'Telangana',
      'city': 'Hyderabad',
      'languages': 'Telugu, English, Hindi',
      'bio': 'Techie, foodie and a movie lover. I enjoy meaningful conversations and making new friends.',
      'lookingFor': 'Friendly chats, voice hangouts and like-minded friends.',
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-aman',
      'name': 'Aman, 27',
      'displayName': 'Aman Gupta',
      'age': 27,
      'gender': 'Male',
      'location': 'Bengaluru',
      'state': 'Karnataka',
      'city': 'Bengaluru',
      'languages': 'Hindi, English, Kannada',
      'bio': 'Software engineer exploring startup ideas, filter coffee enthusiast, and weekend cyclist.',
      'lookingFor': 'Networking, tech discussions, and friendly chats.',
      'photo': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-rahul',
      'name': 'Rahul Varma, 27',
      'displayName': 'Rahul Varma',
      'age': 27,
      'gender': 'Male',
      'location': 'Mumbai',
      'state': 'Maharashtra',
      'city': 'Mumbai',
      'languages': 'Marathi, Hindi, English',
      'bio': 'Music producer, cricket fanatic, and street food lover.',
      'lookingFor': 'Music lovers, hangout buddies, and late night calls.',
      'photo': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-priya',
      'name': 'Priya Nair, 25',
      'displayName': 'Priya Nair',
      'age': 25,
      'gender': 'Female',
      'location': 'Chennai',
      'state': 'Tamil Nadu',
      'city': 'Chennai',
      'languages': 'Tamil, English, Malayalam',
      'bio': 'Doctor and classical dancer. Love long beach walks, books, and deep conversations.',
      'lookingFor': 'Kind friends, thoughtful conversations, and sharing daily stories.',
      'photo': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-kiran',
      'name': 'Kiran Kumar, 29',
      'displayName': 'Kiran Kumar',
      'age': 29,
      'gender': 'Male',
      'location': 'Hyderabad',
      'state': 'Telangana',
      'city': 'Hyderabad',
      'languages': 'Telugu, Hindi, English',
      'bio': 'Architect and photography geek. Love heritage walks and exploring cafes.',
      'lookingFor': 'Creative friends and coffee dates.',
      'photo': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-neha',
      'name': 'Neha Jain, 24',
      'displayName': 'Neha Jain',
      'age': 24,
      'gender': 'Female',
      'location': 'Delhi NCR',
      'state': 'Delhi (NCR)',
      'city': 'Delhi NCR',
      'languages': 'Hindi, English, Punjabi',
      'bio': 'Digital marketer and foodie who loves exploring Old Delhi eateries.',
      'lookingFor': 'Fun people for weekend meetups and reel making.',
      'photo': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-rohit',
      'name': 'Rohit Sharma, 26',
      'displayName': 'Rohit Sharma',
      'age': 26,
      'gender': 'Male',
      'location': 'Pune',
      'state': 'Maharashtra',
      'city': 'Pune',
      'languages': 'Marathi, Hindi, English',
      'bio': 'Mechanical engineer and road tripper across the Western Ghats.',
      'lookingFor': 'Travel buddies and genuine friends.',
      'photo': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-meghana',
      'name': 'Meghana S, 24',
      'displayName': 'Meghana S',
      'age': 24,
      'gender': 'Female',
      'location': 'Visakhapatnam',
      'state': 'Andhra Pradesh',
      'city': 'Visakhapatnam',
      'languages': 'Telugu, English',
      'bio': 'Marine biology student. Sunsets, coffee, and acoustic guitar.',
      'lookingFor': 'Friendly chats and good vibes.',
      'photo': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-arjun',
      'name': 'Arjun Mehta, 28',
      'displayName': 'Arjun Mehta',
      'age': 28,
      'gender': 'Male',
      'location': 'Ahmedabad',
      'state': 'Gujarat',
      'city': 'Ahmedabad',
      'languages': 'Gujarati, Hindi, English',
      'bio': 'Product designer. Passionate about minimalism, typography, and Gujarati snacks.',
      'lookingFor': 'Design friends and thoughtful conversations.',
      'photo': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-pooja',
      'name': 'Pooja Sen, 25',
      'displayName': 'Pooja Sen',
      'age': 25,
      'gender': 'Female',
      'location': 'Kolkata',
      'state': 'West Bengal',
      'city': 'Kolkata',
      'languages': 'Bengali, Hindi, English',
      'bio': 'Literature graduate and tea lover. Big fan of indie cinema and theatre.',
      'lookingFor': 'Book lovers and artistic souls.',
      'photo': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-sriram',
      'name': 'Sriram Reddy, 28',
      'displayName': 'Sriram Reddy',
      'age': 28,
      'gender': 'Male',
      'location': 'Hyderabad',
      'state': 'Telangana',
      'city': 'Hyderabad',
      'languages': 'Telugu, Hindi, English',
      'bio': 'Tech consultant, badminton player, and Biryani connoisseur.',
      'lookingFor': 'Active lifestyle friends and weekend sports.',
      'photo': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void dispose() {
    _cityController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredProfiles() {
    final cityQuery = _cityController.text.trim().toLowerCase();
    final langQuery = _languageController.text.trim().toLowerCase();

    return _allProfiles.where((p) {
      // 1. City check
      if (cityQuery.isNotEmpty) {
        final loc = (p['location'] as String).toLowerCase();
        final city = (p['city'] as String? ?? '').toLowerCase();
        final state = (p['state'] as String? ?? '').toLowerCase();
        if (!loc.contains(cityQuery) && !city.contains(cityQuery) && !state.contains(cityQuery)) {
          return false;
        }
      } else if (_selectedCity != 'All Cities') {
        final loc = (p['location'] as String).toLowerCase();
        final city = (p['city'] as String? ?? '').toLowerCase();
        final target = _selectedCity.toLowerCase();
        if (!loc.contains(target) && !city.contains(target)) {
          return false;
        }
      }

      // 2. Language check
      if (langQuery.isNotEmpty) {
        final langs = (p['languages'] as String).toLowerCase();
        if (!langs.contains(langQuery)) {
          return false;
        }
      } else if (_selectedLanguage != 'All Languages') {
        final langs = (p['languages'] as String).toLowerCase();
        if (!langs.contains(_selectedLanguage.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUserProfile;
    final coins = user?.coins ?? 120;
    final filteredProfiles = _getFilteredProfiles();

    if (_currentProfileIndex >= filteredProfiles.length && filteredProfiles.isNotEmpty) {
      _currentProfileIndex = 0;
    }

    final currentCard = filteredProfiles.isNotEmpty ? filteredProfiles[_currentProfileIndex] : null;

    // Build city dropdown items with 'All Cities' + IndianData.allCities
    final cityOptions = ['All Cities', ...IndianData.allCities];
    if (!cityOptions.contains(_selectedCity)) {
      cityOptions.add(_selectedCity);
    }

    // Build language dropdown items with 'All Languages' + IndianData.allLanguages
    final langOptions = ['All Languages', ...IndianData.allLanguages];
    if (!langOptions.contains(_selectedLanguage)) {
      langOptions.add(_selectedLanguage);
    }

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            const DemoModeBanner(),
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/friendloop_logo.png',
                    height: 38,
                    errorBuilder: (_, __, ___) => const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.all_inclusive_rounded, color: FriendLoopColors.violet, size: 32),
                        SizedBox(width: 6),
                        Text(
                          'FriendLoop',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
                        ),
                      ],
                    ),
                  ),
                  // Coin balance pill
                  GestureDetector(
                    onTap: () => context.push('/wallet'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FriendLoopColors.lavender),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: FriendLoopColors.goldGradient,
                            ),
                            child: const Center(
                              child: Text(
                                '🪙',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$coins',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: FriendLoopColors.plum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      'Discover Friends',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: FriendLoopColors.plum,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Find and connect with friendly people across India',
                      style: TextStyle(
                        fontSize: 13,
                        color: FriendLoopColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Filter Dropdowns Row (Select from all Indian cities & languages)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FriendLoopColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCity,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                menuMaxHeight: 360,
                                items: cityOptions.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedCity = v;
                                      _cityController.clear();
                                      _currentProfileIndex = 0;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FriendLoopColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                menuMaxHeight: 360,
                                items: langOptions.map((l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(l, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedLanguage = v;
                                      _languageController.clear();
                                      _currentProfileIndex = 0;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Enter City and Enter Language Custom Text Input Fields Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FriendLoopColors.border),
                            ),
                            child: TextField(
                              controller: _cityController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter city...',
                                hintStyle: const TextStyle(fontSize: 12, color: FriendLoopColors.textMuted),
                                prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: FriendLoopColors.violet),
                                suffixIcon: _cityController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 14),
                                        onPressed: () {
                                          setState(() {
                                            _cityController.clear();
                                            _currentProfileIndex = 0;
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _currentProfileIndex = 0;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FriendLoopColors.border),
                            ),
                            child: TextField(
                              controller: _languageController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter language...',
                                hintStyle: const TextStyle(fontSize: 12, color: FriendLoopColors.textMuted),
                                prefixIcon: const Icon(Icons.language_outlined, size: 16, color: FriendLoopColors.violet),
                                suffixIcon: _languageController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 14),
                                        onPressed: () {
                                          setState(() {
                                            _languageController.clear();
                                            _currentProfileIndex = 0;
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _currentProfileIndex = 0;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Profile Card Carousel with Left/Right Arrows or Empty State
                    if (currentCard != null) ...[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.push(
                                '/friend-profile/${currentCard['id']}',
                                extra: FriendItem(
                                  friendshipId: currentCard['id'],
                                  friendId: currentCard['id'],
                                  displayName: currentCard['displayName'] ?? currentCard['name'],
                                  avatarUrl: currentCard['photo'],
                                  city: currentCard['city'] ?? currentCard['location'],
                                  state: currentCard['state'] ?? 'India',
                                  age: currentCard['age'] ?? 25,
                                  gender: currentCard['gender'] ?? 'Female',
                                  bio: currentCard['bio'],
                                  images: [currentCard['photo']],
                                ),
                              );
                            },
                            child: Container(
                              height: 280,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      currentCard['photo'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/telegram/wallpaper_sample.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Gradient Overlay
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.8),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    // Text info on card
                                    Positioned(
                                      bottom: 16,
                                      left: 16,
                                      right: 60,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentCard['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, color: Colors.white70, size: 14),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${currentCard['location']} • ${currentCard['languages']}',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Add Friend floating action button on bottom right of card
                                    Positioned(
                                      bottom: 14,
                                      right: 14,
                                      child: FloatingActionButton.small(
                                        heroTag: 'addFriendBtn_${currentCard['id']}',
                                        backgroundColor: FriendLoopColors.violet,
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Friend request sent to ${currentCard['displayName'] ?? currentCard['name']}!'),
                                              backgroundColor: FriendLoopColors.success,
                                            ),
                                          );
                                        },
                                        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Left Arrow Button (if more than 1 profile)
                          if (filteredProfiles.length > 1)
                            Positioned(
                              left: 8,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white.withValues(alpha: 0.85),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left, color: FriendLoopColors.plum, size: 20),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      _currentProfileIndex = (_currentProfileIndex - 1 + filteredProfiles.length) % filteredProfiles.length;
                                    });
                                  },
                                ),
                              ),
                            ),

                          // Right Arrow Button (if more than 1 profile)
                          if (filteredProfiles.length > 1)
                            Positioned(
                              right: 8,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white.withValues(alpha: 0.85),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right, color: FriendLoopColors.plum, size: 20),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      _currentProfileIndex = (_currentProfileIndex + 1) % filteredProfiles.length;
                                    });
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Dots Pagination
                      if (filteredProfiles.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(filteredProfiles.length, (idx) {
                            final isActive = idx == _currentProfileIndex;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? FriendLoopColors.violet : FriendLoopColors.lavender,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                    ] else ...[
                      // Empty state when filter matches no profiles
                      Container(
                        height: 220,
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: FriendLoopColors.lavender),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search_outlined, size: 48, color: FriendLoopColors.violet),
                            const SizedBox(height: 10),
                            const Text(
                              'No friends found for this filter',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try searching another Indian city or clear the filter',
                              style: TextStyle(fontSize: 12, color: FriendLoopColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCity = 'All Cities';
                                  _selectedLanguage = 'All Languages';
                                  _cityController.clear();
                                  _languageController.clear();
                                  _currentProfileIndex = 0;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: FriendLoopColors.violet),
                                foregroundColor: FriendLoopColors.violet,
                              ),
                              child: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Coin Use Notice Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: FriendLoopColors.lavender.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FriendLoopColors.lavender),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🪙', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Calls and chat use coins',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: FriendLoopColors.plum,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3 Quick Action Shortcuts (Friends, Random Connect, Recent Calls)
                    Row(
                      children: [
                        _buildQuickAction(
                          context,
                          icon: Icons.people_outline,
                          label: 'Friends',
                          onTap: () => context.push('/friends'),
                        ),
                        const SizedBox(width: 10),
                        _buildQuickAction(
                          context,
                          icon: Icons.shuffle_rounded,
                          label: 'Random Connect',
                          onTap: () => context.push('/random-connect'),
                        ),
                        const SizedBox(width: 10),
                        _buildQuickAction(
                          context,
                          icon: Icons.phone_outlined,
                          label: 'Recent Calls',
                          onTap: () => context.push('/recent-calls'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FriendLoopColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: FriendLoopColors.violet, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FriendLoopColors.plum,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
