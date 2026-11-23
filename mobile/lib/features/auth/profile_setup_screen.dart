import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController(text: 'Ananya Sharma');
  String _selectedCity = 'Bengaluru';
  final Set<String> _selectedLanguages = {'Hindi', 'English'};
  final Set<String> _selectedLookingFor = {'Friends', 'Call buddies'};
  String? _avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _cities = [
    'Bengaluru',
    'Mumbai',
    'Hyderabad',
    'Delhi NCR',
    'Pune',
    'Chennai',
    'Kolkata',
    'Ahmedabad',
    'Jaipur',
    'Visakhapatnam',
  ];

  static const List<String> _availableLanguages = [
    'Hindi',
    'English',
    'Tamil',
    'Telugu',
    'Bengali',
    'Marathi',
  ];

  static const List<String> _lookingForOptions = [
    'Friends',
    'Call buddies',
    'Chat buddies',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600);
      if (file != null) {
        setState(() {
          _avatarUrl = file.path;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }
    if (_selectedLanguages.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one language');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final lookingForString = _selectedLookingFor.join(', ');
      await ref.read(authProvider.notifier).createProfile(
        displayName: name,
        dob: '2000-01-01',
        stateName: 'Karnataka',
        city: _selectedCity,
        languages: _selectedLanguages.toList(),
        lookingFor: 'Looking for $lookingForString across India.',
        images: [_avatarUrl ?? 'assets/telegram/anand_avatar.png'],
      );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Set up profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: FriendLoopColors.plum,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle with camera badge
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: FriendLoopColors.violet.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            _avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/telegram/anand_avatar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: FriendLoopColors.lavender,
                                child: const Icon(Icons.person, size: 48, color: FriendLoopColors.violet),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: FriendLoopColors.violet,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: FriendLoopColors.rose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FriendLoopColors.rose),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: FriendLoopColors.rose, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: FriendLoopColors.textSecondary),
                    hintText: 'Your name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // City Dropdown Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: FriendLoopColors.textSecondary),
                    items: _cities.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: FriendLoopColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(c, style: const TextStyle(fontSize: 15, color: FriendLoopColors.plum)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCity = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Languages Section
              const Row(
                children: [
                  Icon(Icons.language, size: 18, color: FriendLoopColors.plum),
                  SizedBox(width: 6),
                  Text(
                    'Languages (select)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableLanguages.map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return FilterChip(
                    label: Text(lang),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLanguages.add(lang);
                        } else {
                          if (_selectedLanguages.length > 1) {
                            _selectedLanguages.remove(lang);
                          }
                        }
                      });
                    },
                    selectedColor: FriendLoopColors.lavender,
                    backgroundColor: Colors.white,
                    checkmarkColor: FriendLoopColors.violet,
                    labelStyle: TextStyle(
                      color: isSelected ? FriendLoopColors.violet : FriendLoopColors.plum,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Looking for Section
              const Row(
                children: [
                  Icon(Icons.people_outline, size: 18, color: FriendLoopColors.plum),
                  SizedBox(width: 6),
                  Text(
                    'Looking for (select)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: FriendLoopColors.plum,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _lookingForOptions.map((opt) {
                  final isSelected = _selectedLookingFor.contains(opt);
                  return FilterChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLookingFor.add(opt);
                        } else {
                          if (_selectedLookingFor.length > 1) {
                            _selectedLookingFor.remove(opt);
                          }
                        }
                      });
                    },
                    selectedColor: FriendLoopColors.lavender,
                    backgroundColor: Colors.white,
                    checkmarkColor: FriendLoopColors.violet,
                    labelStyle: TextStyle(
                      color: isSelected ? FriendLoopColors.violet : FriendLoopColors.plum,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save profile button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
