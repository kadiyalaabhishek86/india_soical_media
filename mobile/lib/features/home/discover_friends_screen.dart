import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/constants/indian_states.dart';
import '../../core/providers/favorites_provider.dart';
import '../../shared/widgets/demo_banner.dart';

class DiscoverFriendsScreen extends ConsumerStatefulWidget {
  const DiscoverFriendsScreen({super.key});

  @override
  ConsumerState<DiscoverFriendsScreen> createState() => _DiscoverFriendsScreenState();
}

class _DiscoverFriendsScreenState extends ConsumerState<DiscoverFriendsScreen> {
  int _currentProfileIndex = 0;
  int _currentPhotoIndex = 0;
  final PageController _photoPageController = PageController();

  String _selectedCity = 'All Cities';
  String _selectedLanguage = 'All Languages';
  String _selectedLookingFor = 'All Preferences';

  final Set<String> _likedProfileIds = {};
  final Set<String> _favoriteProfileIds = {};

  static const List<String> lookingForOptions = [
    'All Preferences',
    'Long-term relationship',
    'Friendly chats',
    'Dating & Romance',
    'Casual hangouts',
    'Networking',
  ];

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
      'bio': 'Techie, foodie and a movie lover. I enjoy meaningful conversations, cafe hopping and making genuine new friends.',
      'lookingFor': 'Long-term relationship',
      'isOnline': true,
      'distance': '84 miles away',
      'height': '168 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Regular workouts 💪',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Scorpio ♏',
      'education': 'Masters Graduate 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Quality time & affirmations 💜',
      'interests': [
        'Long walks with photography 📷',
        'Biryani 🍛',
        'Harry Potter ⚡',
      ],
      'photos': [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
      ],
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-aman',
      'name': 'Aman Gupta, 27',
      'displayName': 'Aman Gupta',
      'age': 27,
      'gender': 'Male',
      'location': 'Bengaluru',
      'state': 'Karnataka',
      'city': 'Bengaluru',
      'languages': 'Hindi, English, Kannada',
      'bio': 'Software engineer exploring startup ideas, filter coffee enthusiast, and weekend cyclist around Nandi Hills.',
      'lookingFor': 'Long-term relationship',
      'isOnline': true,
      'distance': '84 miles away',
      'height': '178 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Weekend cycling & gym 💪',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Aries ♈',
      'education': 'B.Tech Software Engineer 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Calls & deep chats 💬',
      'loveStyle': 'Quality time & acts of service 💜',
      'interests': [
        'Cycling 🚴',
        'Filter coffee ☕',
        'Tech startups 💡',
      ],
      'photos': [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
      ],
      'photo': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'user-priya',
      'name': 'Priya Nair, 25',
      'displayName': 'Priya Nair',
      'age': 25,
      'gender': 'Female',
      'location': 'Bengaluru',
      'state': 'Karnataka',
      'city': 'Bengaluru',
      'languages': 'Tamil, English, Malayalam',
      'bio': 'Doctor and classical dancer. Love long beach walks, classic literature, and thoughtful conversations.',
      'lookingFor': 'Long-term relationship',
      'isOnline': true,
      'distance': '84 miles away',
      'height': '168 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Regular workouts 💪',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Scorpio ♏',
      'education': 'Masters Graduate 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Quality time & affirmations 💜',
      'interests': [
        'Long walks with photography 📷',
        'Biryani 🍛',
        'Harry Potter ⚡',
      ],
      'photos': [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
      ],
      'photo': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
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
      'bio': 'Music producer, cricket fanatic, and street food lover. Looking for genuine connections.',
      'lookingFor': 'Friendly chats',
      'isOnline': false,
      'distance': '84 miles away',
      'height': '175 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Active / Gym 💪',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Leo ♌',
      'education': 'Sound Engineering 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Words of affirmation 💜',
      'interests': ['Music production 🎧', 'Street food 🍜', 'Cricket 🏏'],
      'photos': [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
      ],
      'photo': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
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
      'bio': 'Digital marketer and foodie who loves exploring Old Delhi eateries and weekend getaways.',
      'lookingFor': 'Dating & Romance',
      'isOnline': true,
      'distance': '84 miles away',
      'height': '165 cm',
      'orientation': 'Straight',
      'pets': 'Cat lover 🐱',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Yoga & Pilates 🧘',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Virgo ♍',
      'education': 'MBA Marketing 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Quality time & affirmations 💜',
      'interests': ['Food blogging 🍕', 'Weekend getaways 🚗', 'Photography 📸'],
      'photos': [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
      ],
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
      'bio': 'Mechanical engineer and road tripper across the Western Ghats. Sunsets and good vibes.',
      'lookingFor': 'Casual hangouts',
      'isOnline': false,
      'distance': '84 miles away',
      'height': '176 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Regular workouts 💪',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Gemini ♊',
      'education': 'Mechanical Engineering 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Voice calls 📞',
      'loveStyle': 'Quality time 💜',
      'interests': ['Road trips 🏍️', 'Trekking ⛰️', 'Sunset views 🌅'],
      'photos': [
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
      ],
      'photo': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=800&q=80',
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
      'bio': 'Architect and photography geek. Love heritage walks and exploring new cafes.',
      'lookingFor': 'Long-term relationship',
      'isOnline': true,
      'distance': '84 miles away',
      'height': '174 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Regular workouts 💪',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Scorpio ♏',
      'education': 'B.Arch Architecture 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Quality time & affirmations 💜',
      'interests': ['Architecture 🏛️', 'Photography 📷', 'Cafe hopping ☕'],
      'photos': [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
      ],
      'photo': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
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
      'lookingFor': 'Friendly chats',
      'isOnline': true,
      'distance': '84 miles away',
      'height': '164 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Swimming & Yoga 🧘',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Pisces ♓',
      'education': 'M.Sc Marine Biology 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Quality time & affirmations 💜',
      'interests': ['Acoustic guitar 🎸', 'Ocean walks 🌊', 'Coffee ☕'],
      'photos': [
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
      ],
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
      'lookingFor': 'Networking',
      'isOnline': false,
      'distance': '84 miles away',
      'height': '180 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Regular workouts 💪',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Taurus ♉',
      'education': 'Design Degree 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Quality time & affirmations 💜',
      'interests': ['Design 🎨', 'Typography ✒️', 'Gujarati snacks 🥟'],
      'photos': [
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
      ],
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
      'lookingFor': 'Long-term relationship',
      'isOnline': true,
      'distance': '84 miles away',
      'height': '166 cm',
      'orientation': 'Straight',
      'pets': 'Cat lover 🐱',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Regular walks & Yoga 🧘',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Cancer ♋',
      'education': 'Literature Masters 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Quality time & affirmations 💜',
      'interests': ['Indie cinema 🎬', 'Theatre 🎭', 'Reading 📚'],
      'photos': [
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
      ],
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
      'lookingFor': 'Long-term relationship',
      'isOnline': true,
      'distance': '84 miles away',
      'height': '177 cm',
      'orientation': 'Straight',
      'pets': 'Dog lover 🐶',
      'drinking': 'Socially 🍷',
      'smoking': 'Non-smoker 🚭',
      'workouts': 'Badminton & Gym 💪',
      'socialMedia': 'Active on Instagram 📱',
      'zodiac': 'Sagittarius ♐',
      'education': 'Tech Consultant 🎓',
      'familyPlan': 'Wants children 👶',
      'communicationStyle': 'Big texter & calls 💬',
      'loveStyle': 'Quality time & affirmations 💜',
      'interests': ['Badminton 🏸', 'Biryani 🍛', 'Gaming 🎮'],
      'photos': [
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
      ],
      'photo': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=800&q=80',
    },
  ];

  List<Map<String, dynamic>> _getFilteredProfiles() {
    return _allProfiles.where((p) {
      // 1. City check
      if (_selectedCity != 'All Cities') {
        final loc = (p['location'] as String).toLowerCase();
        final city = (p['city'] as String? ?? '').toLowerCase();
        final target = _selectedCity.toLowerCase();
        if (!loc.contains(target) && !city.contains(target)) {
          return false;
        }
      }

      // 2. Language check
      if (_selectedLanguage != 'All Languages') {
        final langs = (p['languages'] as String).toLowerCase();
        if (!langs.contains(_selectedLanguage.toLowerCase())) {
          return false;
        }
      }

      // 3. Looking for check
      if (_selectedLookingFor != 'All Preferences') {
        final pref = (p['lookingFor'] as String? ?? '').toLowerCase();
        if (!pref.contains(_selectedLookingFor.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _onPass(int totalProfiles) {
    if (totalProfiles == 0) return;
    setState(() {
      _currentProfileIndex = (_currentProfileIndex + 1) % totalProfiles;
      _currentPhotoIndex = 0;
    });
  }

  void _onLike(Map<String, dynamic> profile, int totalProfiles) {
    final id = profile['id'] as String;
    setState(() {
      _likedProfileIds.add(id);
      _currentProfileIndex = (_currentProfileIndex + 1) % totalProfiles;
      _currentPhotoIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You liked ${profile['displayName']}! 💜'),
        backgroundColor: FriendLoopColors.plum,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onToggleFavorite(Map<String, dynamic> profile) {
    final id = profile['id'] as String;
    final isFav = _favoriteProfileIds.contains(id) ||
        ref.read(favoritesProvider.notifier).isFavorite(id);

    setState(() {
      if (isFav) {
        _favoriteProfileIds.remove(id);
      } else {
        _favoriteProfileIds.add(id);
      }
    });

    ref.read(favoritesProvider.notifier).toggleFavorite(profile);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !isFav
              ? 'Added ${profile['displayName']} to Favorites! ⭐'
              : 'Removed from Favorites.',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: FriendLoopColors.plum,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1400),
        action: SnackBarAction(
          label: 'Undo',
          textColor: FriendLoopColors.gold,
          onPressed: () {
            setState(() {
              if (!isFav) {
                _favoriteProfileIds.remove(id);
              } else {
                _favoriteProfileIds.add(id);
              }
            });
            ref.read(favoritesProvider.notifier).toggleFavorite(profile);
          },
        ),
      ),
    );
  }

  void _openProfileDetails(Map<String, dynamic> card) {
    final List<String> photosList = (card['photos'] as List?)?.map((e) => e.toString()).toList() ??
        [card['photo']?.toString() ?? 'assets/telegram/wallpaper_sample.png'];

    context.push(
      '/friend-profile/${card['id']}',
      extra: FriendItem(
        friendshipId: card['id'],
        friendId: card['id'],
        displayName: card['displayName'] ?? card['name'],
        avatarUrl: card['photo'],
        city: card['city'] ?? card['location'],
        state: card['state'] ?? 'India',
        age: card['age'] ?? 25,
        gender: card['gender'] ?? 'Female',
        bio: card['bio'],
        lookingFor: card['lookingFor'],
        languages: card['languages'],
        images: photosList,
        distance: card['distance'] ?? '84 miles away',
        height: card['height'] ?? '168 cm',
        orientation: card['orientation'] ?? 'Straight',
        pets: card['pets'] ?? 'Dog lover 🐶',
        drinking: card['drinking'] ?? 'Socially 🍷',
        smoking: card['smoking'] ?? 'Non-smoker 🚭',
        workouts: card['workouts'] ?? 'Regular workouts 💪',
        socialMedia: card['socialMedia'] ?? 'Active on Instagram 📱',
        zodiac: card['zodiac'] ?? 'Scorpio ♏',
        education: card['education'] ?? 'Masters Graduate 🎓',
        familyPlan: card['familyPlan'] ?? 'Wants children 👶',
        communicationStyle: card['communicationStyle'] ?? 'Big texter & calls 💬',
        loveStyle: card['loveStyle'] ?? 'Quality time & affirmations 💜',
        interests: (card['interests'] as List?)?.map((e) => e.toString()).toList() ??
            ['Long walks with photography 📷', 'Biryani 🍛', 'Harry Potter ⚡'],
      ),
    );
  }

  void _onChat(Map<String, dynamic> card) {
    final userCoins = ref.read(authProvider).currentUserProfile?.coins ?? 120;
    if (userCoins < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient coins for Chat (5 coins required, you have $userCoins). Please recharge.'),
          backgroundColor: FriendLoopColors.plum,
          duration: const Duration(seconds: 2),
        ),
      );
      context.push('/wallet');
      return;
    }
    ref.read(authProvider.notifier).updateCoins(userCoins - 5);

    final List<String> photosList = (card['photos'] as List?)?.map((e) => e.toString()).toList() ??
        [card['photo']?.toString() ?? 'assets/telegram/wallpaper_sample.png'];

    context.push(
      '/chat/${card['id']}',
      extra: FriendItem(
        friendshipId: card['id'],
        friendId: card['id'],
        displayName: card['displayName'] ?? card['name'],
        avatarUrl: card['photo'],
        city: card['city'] ?? card['location'],
        state: card['state'] ?? 'India',
        age: card['age'] ?? 25,
        gender: card['gender'] ?? 'Female',
        bio: card['bio'],
        lookingFor: card['lookingFor'],
        languages: card['languages'],
        images: photosList,
      ),
    );
  }

  void _openFilterBottomSheet() {
    String tempCity = _selectedCity;
    String tempLanguage = _selectedLanguage;
    String tempLookingFor = _selectedLookingFor;

    final cityOptions = ['All Cities', ...IndianData.allCities];
    final langOptions = ['All Languages', ...IndianData.allLanguages];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FriendLoopColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Profiles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: FriendLoopColors.plum,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: FriendLoopColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 1. Location Filter
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FriendLoopColors.plum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FriendLoopColors.border, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempCity,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FriendLoopColors.violet),
                          style: const TextStyle(
                            color: FriendLoopColors.plum,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          menuMaxHeight: 320,
                          items: cityOptions
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(
                                        color: FriendLoopColors.plum,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => tempCity = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Language Filter
                    const Text(
                      'Language',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FriendLoopColors.plum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FriendLoopColors.border, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempLanguage,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FriendLoopColors.violet),
                          style: const TextStyle(
                            color: FriendLoopColors.plum,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          menuMaxHeight: 320,
                          items: langOptions
                              .map((l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(
                                      l,
                                      style: const TextStyle(
                                        color: FriendLoopColors.plum,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => tempLanguage = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Looking for Filter
                    const Text(
                      'Looking for',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FriendLoopColors.plum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lookingForOptions.map((opt) {
                        final isSelected = tempLookingFor == opt;
                        return ChoiceChip(
                          label: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : FriendLoopColors.plum,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: FriendLoopColors.violet,
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
                              width: 1.2,
                            ),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() => tempLookingFor = opt);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // Action Buttons: Reset & Apply
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: FriendLoopColors.border, width: 1.2),
                              foregroundColor: FriendLoopColors.plum,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              setSheetState(() {
                                tempCity = 'All Cities';
                                tempLanguage = 'All Languages';
                                tempLookingFor = 'All Preferences';
                              });
                            },
                            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700, color: FriendLoopColors.plum)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FriendLoopColors.violet,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedCity = tempCity;
                                _selectedLanguage = tempLanguage;
                                _selectedLookingFor = tempLookingFor;
                                _currentProfileIndex = 0;
                                _currentPhotoIndex = 0;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    final List<String> photos = currentCard != null
        ? ((currentCard['photos'] as List?)?.map((e) => e.toString()).toList() ??
            [currentCard['photo']?.toString() ?? 'assets/telegram/wallpaper_sample.png'])
        : [];

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas, // Light canvas palette (#F4EBFC)
      body: SafeArea(
        child: Column(
          children: [
            const DemoModeBanner(),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // FriendLoop Logo & Name
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: FriendLoopColors.lavender),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.all_inclusive_rounded, color: FriendLoopColors.violet, size: 22),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FriendLoop',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: FriendLoopColors.plum,
                        ),
                      ),
                    ],
                  ),

                  // Header Right: Filters Button & Coin Wallet
                  Row(
                    children: [
                      // Filters Button
                      GestureDetector(
                        onTap: _openFilterBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_selectedCity != 'All Cities' ||
                                    _selectedLanguage != 'All Languages' ||
                                    _selectedLookingFor != 'All Preferences')
                                ? FriendLoopColors.lavender
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (_selectedCity != 'All Cities' ||
                                      _selectedLanguage != 'All Languages' ||
                                      _selectedLookingFor != 'All Preferences')
                                  ? FriendLoopColors.violet
                                  : FriendLoopColors.border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color: (_selectedCity != 'All Cities' ||
                                        _selectedLanguage != 'All Languages' ||
                                        _selectedLookingFor != 'All Preferences')
                                    ? FriendLoopColors.violet
                                    : FriendLoopColors.plum,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Filters',
                                style: TextStyle(
                                  color: (_selectedCity != 'All Cities' ||
                                          _selectedLanguage != 'All Languages' ||
                                          _selectedLookingFor != 'All Preferences')
                                      ? FriendLoopColors.violet
                                      : FriendLoopColors.plum,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Coin Pill
                      GestureDetector(
                        onTap: () => context.push('/wallet'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                              const Text('🪙', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '$coins',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: FriendLoopColors.plum,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Subtitle & Active Filter Chips (Removable Chips)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discover Friends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Find and connect with friendly people across India',
                    style: TextStyle(
                      fontSize: 11,
                      color: FriendLoopColors.textSecondary,
                    ),
                  ),
                  if (_selectedCity != 'All Cities' ||
                      _selectedLanguage != 'All Languages' ||
                      _selectedLookingFor != 'All Preferences') ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedCity != 'All Cities') ...[
                            _buildFilterChip(
                              label: _selectedCity,
                              onClear: () => setState(() => _selectedCity = 'All Cities'),
                              onTap: _openFilterBottomSheet,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_selectedLanguage != 'All Languages') ...[
                            _buildFilterChip(
                              label: _selectedLanguage,
                              onClear: () => setState(() => _selectedLanguage = 'All Languages'),
                              onTap: _openFilterBottomSheet,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_selectedLookingFor != 'All Preferences') ...[
                            _buildFilterChip(
                              label: _selectedLookingFor,
                              onClear: () => setState(() => _selectedLookingFor = 'All Preferences'),
                              onTap: _openFilterBottomSheet,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Profile Card View or Empty State
            Expanded(
              child: currentCard != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: FriendLoopColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. Multi-photo Horizontal Swiper
                              GestureDetector(
                                onTap: () => _openProfileDetails(currentCard),
                                child: PageView.builder(
                                  controller: _photoPageController,
                                  itemCount: photos.length,
                                  onPageChanged: (idx) {
                                    setState(() => _currentPhotoIndex = idx);
                                  },
                                  itemBuilder: (context, pIdx) {
                                    final imgUrl = photos[pIdx];
                                    final isNet = imgUrl.startsWith('http://') || imgUrl.startsWith('https://');
                                    return isNet
                                        ? Image.network(
                                            imgUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Image.asset(
                                              'assets/telegram/wallpaper_sample.png',
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Image.asset(
                                            'assets/telegram/wallpaper_sample.png',
                                            fit: BoxFit.cover,
                                          );
                                  },
                                ),
                              ),

                              // 2. Photo Position Segmented Progress Indicators
                              if (photos.length > 1)
                                Positioned(
                                  top: 12,
                                  left: 14,
                                  right: 14,
                                  child: Row(
                                    children: List.generate(photos.length, (pIdx) {
                                      final isCur = pIdx == _currentPhotoIndex;
                                      return Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 2),
                                          height: 3.5,
                                          decoration: BoxDecoration(
                                            color: isCur ? Colors.white : Colors.white.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(2),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                              // 3. Online Status Badge (Top Right)
                              Positioned(
                                top: photos.length > 1 ? 24 : 14,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: currentCard['isOnline'] == true
                                              ? FriendLoopColors.onlineGreen
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        currentCard['isOnline'] == true ? 'Online' : 'Offline',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 4. Subtle Gradient Overlay for Text Readability
                              IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.15),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.85),
                                      ],
                                      stops: const [0.0, 0.45, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // 5. Profile Info Under Photo (Tappable to view details)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => _openProfileDetails(currentCard),
                                  behavior: HitTestBehavior.opaque,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Name & View Profile Label
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              currentCard['name'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                shadows: [
                                                  Shadow(color: Colors.black45, blurRadius: 4),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.22),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.white38),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'View profile',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(Icons.arrow_forward_ios_rounded,
                                                    color: Colors.white, size: 10),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),

                                      // Location & Languages Row
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${currentCard['city'] ?? currentCard['location']}, ${currentCard['state']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('•', style: TextStyle(color: Colors.white70)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              currentCard['languages'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Compact "Looking for" row
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: FriendLoopColors.violet.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: FriendLoopColors.lavender.withValues(alpha: 0.5)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.favorite_outline_rounded,
                                                color: FriendLoopColors.lavender, size: 13),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Looking for: ${currentCard['lookingFor'] ?? "Long-term relationship"}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: FriendLoopColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_search_rounded,
                                size: 54, color: FriendLoopColors.violet),
                            const SizedBox(height: 14),
                            const Text(
                              'No profiles match these filters',
                              style: TextStyle(
                                color: FriendLoopColors.plum,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try resetting filters or exploring other Indian cities to discover more people.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: FriendLoopColors.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FriendLoopColors.violet,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reset Filters',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                setState(() {
                                  _selectedCity = 'All Cities';
                                  _selectedLanguage = 'All Languages';
                                  _selectedLookingFor = 'All Preferences';
                                  _currentProfileIndex = 0;
                                  _currentPhotoIndex = 0;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            // Four Profile Actions: Pass, Like, Favorite, Chat
            if (currentCard != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. Pass
                    _buildActionButton(
                      label: 'Pass',
                      icon: Icons.close_rounded,
                      iconColor: FriendLoopColors.textMuted,
                      borderColor: FriendLoopColors.border,
                      onTap: () => _onPass(filteredProfiles.length),
                    ),

                    // 2. Like
                    _buildActionButton(
                      label: 'Like',
                      icon: _likedProfileIds.contains(currentCard['id'])
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: _likedProfileIds.contains(currentCard['id'])
                          ? FriendLoopColors.rose
                          : const Color(0xFFE53935),
                      borderColor: _likedProfileIds.contains(currentCard['id'])
                          ? FriendLoopColors.rose
                          : FriendLoopColors.border,
                      onTap: () => _onLike(currentCard, filteredProfiles.length),
                    ),

                    // 3. Favorite
                    _buildActionButton(
                      label: 'Favorite',
                      icon: (_favoriteProfileIds.contains(currentCard['id']) ||
                              ref.watch(favoritesProvider).any((f) => f.id == currentCard['id']))
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      iconColor: FriendLoopColors.gold,
                      borderColor: (_favoriteProfileIds.contains(currentCard['id']) ||
                              ref.watch(favoritesProvider).any((f) => f.id == currentCard['id']))
                          ? FriendLoopColors.gold
                          : FriendLoopColors.border,
                      onTap: () => _onToggleFavorite(currentCard),
                    ),

                    // 4. Chat
                    _buildActionButton(
                      label: 'Chat',
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: FriendLoopColors.violet,
                      borderColor: FriendLoopColors.lavender,
                      onTap: () => _onChat(currentCard),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onClear,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: FriendLoopColors.lavender,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FriendLoopColors.violet,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: FriendLoopColors.violet,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: FriendLoopColors.violet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: FriendLoopColors.plum,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
