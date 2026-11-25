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
  DateTime _selectedDob = DateTime(2000, 1, 1);
  bool _isAdultConfirmed = true;
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

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob.isAfter(maxDate) ? maxDate : _selectedDob,
      firstDate: DateTime(1930),
      lastDate: maxDate,
      helpText: 'Select your birth date (Strictly 18+)',
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
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

    final age = _calculateAge(_selectedDob);
    if (age < 18) {
      setState(() => _errorMessage = 'FriendLoop is strictly for adults (18+). Minors are not permitted to register.');
      return;
    }

    if (!_isAdultConfirmed) {
      setState(() => _errorMessage = 'Please confirm that you are at least 18 years old to proceed.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final formattedDob =
          '${_selectedDob.year.toString().padLeft(4, '0')}-${_selectedDob.month.toString().padLeft(2, '0')}-${_selectedDob.day.toString().padLeft(2, '0')}';
      final lookingForString = _selectedLookingFor.join(', ');
      await ref.read(authProvider.notifier).createProfile(
        displayName: name,
        dob: formattedDob,
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
              const SizedBox(height: 14),

              // Date of Birth Field (Strict 18+ enforcement)
              GestureDetector(
                onTap: _pickDob,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FriendLoopColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, size: 20, color: FriendLoopColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date of Birth (Strictly 18+)',
                              style: TextStyle(fontSize: 11, color: FriendLoopColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedDob.day.toString().padLeft(2, '0')}/${_selectedDob.month.toString().padLeft(2, '0')}/${_selectedDob.year} (${_calculateAge(_selectedDob)} years)',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: FriendLoopColors.plum),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 18, color: FriendLoopColors.violet),
                    ],
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
              const SizedBox(height: 24),

              // 18+ Declaration & Safety Standards Checkbox
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAdultConfirmed ? FriendLoopColors.lavender : FriendLoopColors.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isAdultConfirmed,
                        activeColor: FriendLoopColors.violet,
                        onChanged: (val) {
                          setState(() => _isAdultConfirmed = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'I confirm that I am 18 years of age or older. I understand that FriendLoop strictly restricts minor access and requires all users to be adults (18+).',
                        style: TextStyle(
                          fontSize: 12,
                          color: FriendLoopColors.plum.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
