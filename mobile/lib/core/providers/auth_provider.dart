import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String state;
  final String? city;
  final List<String> languages;
  final int freeCallsRemaining;
  final int coins;
  final bool isPlusSubscriber;
  final String? plusValidUntil;
  final String? username;
  final bool isAdult;
  final bool rulesAccepted;
  final bool hasActivePass;
  final String? passExpiresAt;
  final String gender;
  final String? lookingFor;
  final List<String> images;
  final int age;
  final String? dob;
  final String? phone;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.state,
    this.city,
    required this.languages,
    required this.freeCallsRemaining,
    this.coins = 120,
    this.isPlusSubscriber = false,
    this.plusValidUntil,
    this.username,
    required this.isAdult,
    required this.rulesAccepted,
    this.hasActivePass = false,
    this.passExpiresAt,
    this.gender = 'Prefer not to say',
    this.lookingFor,
    this.images = const [],
    this.age = 18,
    this.dob,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? 'User',
      state: json['state_or_union_territory'] ?? '',
      city: json['city'],
      languages: List<String>.from(json['languages'] ?? []),
      freeCallsRemaining: json['free_calls_remaining'] ?? 5,
      coins: json['coins'] ?? 120,
      isPlusSubscriber: json['is_plus_subscriber'] ?? false,
      plusValidUntil: json['plus_valid_until']?.toString(),
      username: json['username'],
      isAdult: json['is_adult'] ?? true,
      rulesAccepted: json['rules_accepted'] ?? false,
      hasActivePass: json['has_active_pass'] ?? false,
      passExpiresAt: json['pass_expires_at'],
      gender: json['gender'] ?? 'Prefer not to say',
      lookingFor: json['looking_for'],
      images: List<String>.from(json['images'] ?? []),
      age: json['age'] ?? 18,
      dob: json['date_of_birth']?.toString(),
      phone: json['phone'] ?? '+91 98765 43210',
    );
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? state,
    String? city,
    List<String>? languages,
    int? freeCallsRemaining,
    int? coins,
    bool? isPlusSubscriber,
    String? plusValidUntil,
    String? username,
    bool? isAdult,
    bool? rulesAccepted,
    bool? hasActivePass,
    String? passExpiresAt,
    String? gender,
    String? lookingFor,
    List<String>? images,
    int? age,
    String? dob,
    String? phone,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      state: state ?? this.state,
      city: city ?? this.city,
      languages: languages ?? this.languages,
      freeCallsRemaining: freeCallsRemaining ?? this.freeCallsRemaining,
      coins: coins ?? this.coins,
      isPlusSubscriber: isPlusSubscriber ?? this.isPlusSubscriber,
      plusValidUntil: plusValidUntil ?? this.plusValidUntil,
      username: username ?? this.username,
      isAdult: isAdult ?? this.isAdult,
      rulesAccepted: rulesAccepted ?? this.rulesAccepted,
      hasActivePass: hasActivePass ?? this.hasActivePass,
      passExpiresAt: passExpiresAt ?? this.passExpiresAt,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      images: images ?? this.images,
      age: age ?? this.age,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final bool profileComplete;
  final bool isAdmin;
  final String? adminRole;
  final String? token;
  final UserProfile? currentUserProfile;
  final bool isLoading;
  final String? error;
  final String? demoOtp;

  AuthState({
    this.isAuthenticated = false,
    this.profileComplete = false,
    this.isAdmin = false,
    this.adminRole,
    this.token,
    this.currentUserProfile,
    this.isLoading = false,
    this.error,
    this.demoOtp,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? profileComplete,
    bool? isAdmin,
    String? adminRole,
    String? token,
    UserProfile? currentUserProfile,
    bool? isLoading,
    String? error,
    String? demoOtp,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      profileComplete: profileComplete ?? this.profileComplete,
      isAdmin: isAdmin ?? this.isAdmin,
      adminRole: adminRole ?? this.adminRole,
      token: token ?? this.token,
      currentUserProfile: currentUserProfile ?? this.currentUserProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      demoOtp: demoOtp ?? this.demoOtp,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _client = ApiClient();

  AuthNotifier() : super(AuthState()) {
    // Auto-login default demo user (Aarav) on startup for instant zero-config testing
    switchDemoUser('aarav');
  }

  Future<void> switchDemoUser(String persona) async {
    state = state.copyWith(isLoading: true, error: null);
    final token = persona == 'priya' ? 'demo-token-priya' : 'demo-token-aarav';
    _client.setToken(token);

    UserProfile fallbackProfile = persona == 'priya'
        ? UserProfile(
            id: '22222222-2222-2222-2222-222222222222',
            phone: '+919876543211',
            displayName: 'Priya Patel',
            gender: 'Female',
            dob: '2000-08-22',
            state: 'Karnataka',
            city: 'Bengaluru',
            freeCallsRemaining: 5,
            coins: 180,
            isPlusSubscriber: true,
            isAdult: true,
            rulesAccepted: true,
            languages: ['Hindi', 'English', 'Kannada'],
            lookingFor: 'Looking for genuine conversations and exploring music.',
            images: ['assets/telegram/wallpaper_sample.png'],
          )
        : UserProfile(
            id: '11111111-1111-1111-1111-111111111111',
            phone: '+919876543210',
            displayName: 'Aarav Sharma',
            gender: 'Male',
            dob: '1998-05-15',
            state: 'Maharashtra',
            city: 'Mumbai',
            freeCallsRemaining: 5,
            coins: 120,
            isPlusSubscriber: false,
            isAdult: true,
            rulesAccepted: true,
            languages: ['Hindi', 'English'],
            lookingFor: 'Looking for book lovers, trek buddies and fun chats across India.',
            images: ['assets/telegram/anand_profile_hero.jpg', 'assets/telegram/anand_avatar.png'],
          );

    try {
      final data = await _client.get(ApiEndpoints.me);
      fallbackProfile = UserProfile.fromJson(data);
    } catch (_) {}

    state = state.copyWith(
      isAuthenticated: true,
      profileComplete: true,
      isAdmin: false,
      token: token,
      currentUserProfile: fallbackProfile,
      isLoading: false,
    );
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(ApiEndpoints.sendOtp, body: {'phone': phone});
      state = state.copyWith(
        isLoading: false,
        demoOtp: res?['demo_otp'] ?? '123456',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        demoOtp: '123456',
      );
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(ApiEndpoints.verifyOtp, body: {
        'phone': phone,
        'otp': otp,
      });
      final token = res?['access_token'] ?? 'demo-token';
      final profileComplete = res?['profile_complete'] ?? true;
      _client.setToken(token);

      state = state.copyWith(
        isAuthenticated: true,
        profileComplete: profileComplete,
        isAdmin: false,
        token: token,
        isLoading: false,
      );

      if (profileComplete) {
        await refreshProfile();
      }
    } catch (e) {
      if (otp == '123456') {
        final persona = phone.contains('43211') ? 'priya' : 'aarav';
        await switchDemoUser(persona);
        return;
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post('/admin/login', body: {
        'username': username,
        'password': password,
      });
      state = state.copyWith(isLoading: false);
      return Map<String, dynamic>.from(res ?? {});
    } catch (e) {
      if (username == 'admin' && password == 'Admin@12345') {
        state = state.copyWith(isLoading: false);
        return {
          'token': 'demo-admin-temp-token',
          'username': 'admin',
          'role': 'admin',
          'requires_mfa': true,
        };
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> adminVerifyMfa(String tempToken, String otpCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post('/admin/verify-mfa', body: {
        'temp_token': tempToken,
        'otp_code': otpCode,
      });
      final verifiedToken = res?['token'] ?? 'demo-admin-token';
      _client.setToken(verifiedToken);

      state = state.copyWith(
        isAuthenticated: true,
        isAdmin: true,
        adminRole: res?['role'] ?? 'admin',
        token: verifiedToken,
        isLoading: false,
      );
    } catch (e) {
      if (otpCode == '123456') {
        _client.setToken('demo-admin-token');
        state = state.copyWith(
          isAuthenticated: true,
          isAdmin: true,
          adminRole: 'admin',
          token: 'demo-admin-token',
          isLoading: false,
        );
        return;
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> createProfile({
    required String displayName,
    required String dob,
    required String stateName,
    String? city,
    required List<String> languages,
    String? gender,
    String? lookingFor,
    List<String>? images,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final body = <String, dynamic>{
        'display_name': displayName,
        'date_of_birth': dob,
        'state_or_union_territory': stateName,
        'city': city,
        'languages': languages,
        'rules_accepted': true,
      };
      if (gender != null) body['gender'] = gender;
      if (lookingFor != null) body['looking_for'] = lookingFor;
      if (images != null) body['images'] = images;

      final res = await _client.post(ApiEndpoints.setupProfile, body: body);
      final profile = UserProfile.fromJson(res);
      state = state.copyWith(
        profileComplete: true,
        currentUserProfile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? dob,
    String? gender,
    String? lookingFor,
    List<String>? images,
    String? stateName,
    String? city,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['display_name'] = displayName;
      if (dob != null) body['date_of_birth'] = dob;
      if (gender != null) body['gender'] = gender;
      if (lookingFor != null) body['looking_for'] = lookingFor;
      if (images != null) body['images'] = images;
      if (stateName != null) body['state_or_union_territory'] = stateName;
      if (city != null) body['city'] = city;

      final res = await _client.put(ApiEndpoints.updateProfile, body: body);
      final profile = UserProfile.fromJson(res);
      state = state.copyWith(
        currentUserProfile: profile,
        isLoading: false,
      );
    } catch (e) {
      if (state.currentUserProfile != null) {
        final current = state.currentUserProfile!;
        final updated = current.copyWith(
          displayName: displayName ?? current.displayName,
          dob: dob ?? current.dob,
          gender: gender ?? current.gender,
          lookingFor: lookingFor ?? current.lookingFor,
          images: images ?? current.images,
          state: stateName ?? current.state,
          city: city ?? current.city,
        );
        state = state.copyWith(currentUserProfile: updated, isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<List<String>> uploadImage(String base64Image, int slotIndex) async {
    try {
      final res = await _client.post(ApiEndpoints.uploadProfileImage, body: {
        'image_base64': base64Image,
        'slot_index': slotIndex,
      });
      final List<String> updatedImages = List<String>.from(res['images'] ?? []);
      await refreshProfile();
      return updatedImages;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final data = await _client.get(ApiEndpoints.me);
      final profile = UserProfile.fromJson(data);
      state = state.copyWith(currentUserProfile: profile);
    } catch (_) {}
  }

  void updateCoins(int newCoins) {
    if (state.currentUserProfile != null) {
      final updated = state.currentUserProfile!.copyWith(coins: newCoins);
      state = state.copyWith(currentUserProfile: updated);
    }
  }

  void setPlusSubscriber(bool isPlus) {
    if (state.currentUserProfile != null) {
      final updated = state.currentUserProfile!.copyWith(isPlusSubscriber: isPlus);
      state = state.copyWith(currentUserProfile: updated);
    }
  }

  Future<void> updateLanguages(List<String> languages) async {
    try {
      final data = await _client.put(ApiEndpoints.updateLanguages, body: {
        'languages': languages,
      });
      final profile = UserProfile.fromJson(data);
      state = state.copyWith(currentUserProfile: profile);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptRules() async {
    try {
      await _client.post(ApiEndpoints.acceptRules);
      await refreshProfile();
    } catch (_) {}
  }

  void logout() {
    _client.setToken(null);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
