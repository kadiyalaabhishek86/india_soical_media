import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteProfile {
  final String id;
  final String name;
  final String displayName;
  final int age;
  final String location;
  final String? city;
  final String? state;
  final String photo;
  final List<String> photos;
  final String lookingFor;
  final bool isOnline;
  final String? bio;
  final String? languages;
  final String distance;
  final String height;
  final String orientation;
  final String pets;
  final String drinking;
  final String smoking;
  final String workouts;
  final String socialMedia;
  final String zodiac;
  final String education;
  final String familyPlan;
  final String communicationStyle;
  final String loveStyle;
  final List<String> interests;

  FavoriteProfile({
    required this.id,
    required this.name,
    required this.displayName,
    required this.age,
    required this.location,
    this.city,
    this.state,
    required this.photo,
    required this.photos,
    required this.lookingFor,
    this.isOnline = true,
    this.bio,
    this.languages,
    this.distance = '84 miles away',
    this.height = '168 cm',
    this.orientation = 'Straight',
    this.pets = 'Dog lover 🐶',
    this.drinking = 'Socially 🍷',
    this.smoking = 'Non-smoker 🚭',
    this.workouts = 'Regular workouts 💪',
    this.socialMedia = 'Active on Instagram 📱',
    this.zodiac = 'Scorpio ♏',
    this.education = 'Masters Graduate 🎓',
    this.familyPlan = 'Wants children 👶',
    this.communicationStyle = 'Big texter & calls 💬',
    this.loveStyle = 'Quality time & affirmations 💜',
    this.interests = const ['Long walks with photography 📷', 'Biryani 🍛', 'Harry Potter ⚡'],
  });
}

class FavoritesNotifier extends StateNotifier<List<FavoriteProfile>> {
  FavoritesNotifier() : super([]);

  bool isFavorite(String id) => state.any((p) => p.id == id);

  void toggleFavorite(Map<String, dynamic> p) {
    final id = p['id'] as String;
    if (isFavorite(id)) {
      state = state.where((item) => item.id != id).toList();
    } else {
      final List<String> photos = (p['photos'] as List?)?.map((e) => e.toString()).toList() ??
          [p['photo']?.toString() ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80'];
      final List<String> interests = (p['interests'] as List?)?.map((e) => e.toString()).toList() ??
          ['Long walks with photography 📷', 'Biryani 🍛', 'Harry Potter ⚡'];

      final fav = FavoriteProfile(
        id: id,
        name: p['name'] ?? p['displayName'] ?? 'Friend',
        displayName: p['displayName'] ?? p['name'] ?? 'Friend',
        age: p['age'] ?? 25,
        location: p['location'] ?? 'Bengaluru',
        city: p['city'] ?? p['location'] ?? 'Bengaluru',
        state: p['state'] ?? 'Karnataka',
        photo: p['photo'] ?? (photos.isNotEmpty ? photos.first : ''),
        photos: photos,
        lookingFor: p['lookingFor'] ?? 'Long-term relationship',
        isOnline: p['isOnline'] ?? true,
        bio: p['bio'],
        languages: p['languages'],
        distance: p['distance'] ?? '84 miles away',
        height: p['height'] ?? '168 cm',
        orientation: p['orientation'] ?? 'Straight',
        pets: p['pets'] ?? 'Dog lover 🐶',
        drinking: p['drinking'] ?? 'Socially 🍷',
        smoking: p['smoking'] ?? 'Non-smoker 🚭',
        workouts: p['workouts'] ?? 'Regular workouts 💪',
        socialMedia: p['socialMedia'] ?? 'Active on Instagram 📱',
        zodiac: p['zodiac'] ?? 'Scorpio ♏',
        education: p['education'] ?? 'Masters Graduate 🎓',
        familyPlan: p['familyPlan'] ?? 'Wants children 👶',
        communicationStyle: p['communicationStyle'] ?? 'Big texter & calls 💬',
        loveStyle: p['loveStyle'] ?? 'Quality time & affirmations 💜',
        interests: interests,
      );
      state = [fav, ...state];
    }
  }

  void removeFavorite(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<FavoriteProfile>>((ref) {
  return FavoritesNotifier();
});
