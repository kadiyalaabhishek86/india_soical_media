import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/constants/indian_states.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/profile_image_view.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;

  const EditProfileSheet({
    super.key,
    required this.profile,
  });

  static Future<void> show(BuildContext context, UserProfile profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AaraColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _lookingForController;

  DateTime? _selectedDob;
  late String _selectedGender;
  late String _selectedState;
  late List<String> _photos; // Exactly 3 slots (may contain empty strings)

  bool _isSaving = false;
  String? _errorMessage;
  String? _phoneValidationError;

  // Curated sample avatar presets for quick testing
  static const List<Map<String, String>> _samplePresets = [
    {
      'label': 'Anand Kumar (Hero)',
      'url': 'assets/telegram/anand_profile_hero.jpg',
    },
    {
      'label': 'Aarav (Mumbai)',
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Priya (Bengaluru)',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Kabir (Delhi)',
      'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Ananya (Pune)',
      'url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Rohan (Hyderabad)',
      'url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.displayName);
    _cityController = TextEditingController(text: p.city ?? '');
    _lookingForController = TextEditingController(text: p.lookingFor ?? '');

    // Initialize DOB if present or fallback
    if (p.dob != null && p.dob!.isNotEmpty) {
      try {
        _selectedDob = DateTime.parse(p.dob!);
      } catch (_) {}
    }

    _selectedGender = p.gender.isNotEmpty ? p.gender : 'Male';
    _selectedState = p.state.isNotEmpty ? p.state : 'Maharashtra';

    // Ensure 3 slots
    _photos = List<String>.filled(3, '');
    for (int i = 0; i < p.images.length && i < 3; i++) {
      _photos[i] = p.images[i];
    }

    _lookingForController.addListener(_validateLookingForField);
  }

  @override
  void dispose() {
    _lookingForController.removeListener(_validateLookingForField);
    _nameController.dispose();
    _cityController.dispose();
    _lookingForController.dispose();
    super.dispose();
  }

  /// Strict phone number detection to preserve privacy and prevent contact sharing
  void _validateLookingForField() {
    final text = _lookingForController.text;
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    final phonePattern = RegExp(
      r'(?:(?:\+|00)91[\s.-]*)?[6-9]\d{2}[\s.-]?\d{3}[\s.-]?\d{4}|(?:\d[\s.-]*){10,}|\b\d{10}\b|\b\d{5}[\s.-]\d{5}\b',
      caseSensitive: false,
    );

    if (phonePattern.hasMatch(text) || digitsOnly.length >= 10) {
      if (_phoneValidationError == null) {
        setState(() {
          _phoneValidationError =
              '⚠️ Phone numbers are strictly not allowed in Looking For to protect your privacy.';
        });
      }
    } else {
      if (_phoneValidationError != null) {
        setState(() {
          _phoneValidationError = null;
        });
      }
    }
  }

  Future<void> _pickImageFromSource(int slotIndex, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _photos[slotIndex] = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access image: ${e.toString()}'),
            backgroundColor: AaraColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker(int slotIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AaraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Photo (Slot ${slotIndex + 1} of 3)',
                  style: AaraTypography.titleMedium,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AaraColors.champagneLight),
                  title: const Text('Choose from Gallery / Mobile Files',
                      style: TextStyle(color: AaraColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageFromSource(slotIndex, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AaraColors.champagneLight),
                  title: const Text('Take Photo with Camera',
                      style: TextStyle(color: AaraColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageFromSource(slotIndex, ImageSource.camera);
                  },
                ),
                const Divider(color: AaraColors.border),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 6.0, bottom: 8.0),
                  child: Text(
                    'Or Select Sample Profile Photo:',
                    style: AaraTypography.labelSmall.copyWith(color: AaraColors.textMuted),
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _samplePresets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, idx) {
                      final item = _samplePresets[idx];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _photos[slotIndex] = item['url']!;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AaraColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AaraColors.champagne.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(item['url']!),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item['label']!,
                                style: const TextStyle(
                                  color: AaraColors.champagneLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        );
      },
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    // 18+ limit: latest eligible birth date is 18 years ago today
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final initial = _selectedDob ?? DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(maxDate) ? initial : maxDate,
      firstDate: DateTime(1930),
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AaraColors.champagne,
              onPrimary: AaraColors.background,
              surface: AaraColors.surfaceCard,
              onSurface: AaraColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  int? get _computedAge {
    if (_selectedDob == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDob!.year;
    if (now.month < _selectedDob!.month ||
        (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _saveProfile() async {
    _validateLookingForField();
    if (_phoneValidationError != null) {
      setState(() {
        _errorMessage = 'Please remove any phone numbers from your bio before saving.';
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Phone Number Not Allowed'),
            ],
          ),
          content: const Text('Phone numbers and contact info are strictly not accepted in Looking For. Please remove the phone number before saving.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (_nameController.text.trim().length < 2) {
      setState(() => _errorMessage = 'Display name must be at least 2 characters.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Filter out empty photo slots
      final validImages = _photos.where((p) => p.trim().isNotEmpty).toList();

      final dobStr = _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : null;

      await ref.read(authProvider.notifier).updateProfile(
            displayName: _nameController.text.trim(),
            dob: dobStr,
            gender: _selectedGender,
            lookingFor: _lookingForController.text.trim().isNotEmpty
                ? _lookingForController.text.trim()
                : null,
            images: validImages,
            stateName: _selectedState,
            city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! ✨'),
            backgroundColor: AaraColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, color: AaraColors.champagneLight, size: 26),
                      const SizedBox(width: 8),
                      Text('Edit Profile', style: AaraTypography.displayMedium.copyWith(fontSize: 22)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AaraColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Update your photos, details, and conversation interests.',
                style: AaraTypography.bodyMedium.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 18),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AaraColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AaraColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AaraColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AaraColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. Photo Slots Section (Must put 3 images)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile Photos (3 Slots)',
                    style: AaraTypography.labelLarge.copyWith(color: AaraColors.champagneLight),
                  ),
                  Text(
                    '${_photos.where((p) => p.isNotEmpty).length}/3 added',
                    style: const TextStyle(color: AaraColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Upload up to 3 photos. Tap any slot to upload from mobile or select preset.',
                style: AaraTypography.labelSmall.copyWith(color: AaraColors.textMuted),
              ),
              const SizedBox(height: 12),

              Row(
                children: List.generate(3, (index) {
                  final img = _photos[index];
                  final hasPhoto = img.trim().isNotEmpty;

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 5,
                        right: index == 2 ? 0 : 5,
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              InkWell(
                                onTap: () => _showImageSourcePicker(index),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AaraColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: hasPhoto
                                          ? AaraColors.champagne
                                          : AaraColors.border,
                                      width: hasPhoto ? 1.5 : 1,
                                    ),
                                  ),
                                  child: hasPhoto
                                      ? ProfileImageView(
                                          imageUrl: img,
                                          borderRadius: BorderRadius.circular(13),
                                          width: double.infinity,
                                          height: 120,
                                        )
                                      : Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo_outlined,
                                                color: AaraColors.champagneLight.withOpacity(0.7),
                                                size: 28,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                index == 0 ? 'Main Photo' : 'Photo ${index + 1}',
                                                style: const TextStyle(
                                                  color: AaraColors.textMuted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              if (hasPhoto)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _photos[index] = '';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Slot ${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasPhoto ? AaraColors.champagneLight : AaraColors.textMuted,
                              fontWeight: hasPhoto ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // 2. Display Name
              Text('Display Name', style: AaraTypography.labelLarge.copyWith(color: AaraColors.champagneLight)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AaraColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AaraColors.surface,
                  hintText: 'e.g. Aarav Sharma',
                  hintStyle: const TextStyle(color: AaraColors.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AaraColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AaraColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AaraColors.champagne)),
                  prefixIcon: const Icon(Icons.person_outline, color: AaraColors.champagneLight, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Date of Birth & Age
              Text('Date of Birth (Must be 18+)', style: AaraTypography.labelLarge.copyWith(color: AaraColors.champagneLight)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDateOfBirth,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AaraColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AaraColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: AaraColors.champagneLight, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDob != null
                              ? '${DateFormat('yyyy-MM-dd').format(_selectedDob!)}  (${_computedAge ?? 18} years old)'
                              : 'Select Date of Birth (Adult 18+)',
                          style: TextStyle(
                            color: _selectedDob != null ? AaraColors.textPrimary : AaraColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_month, color: AaraColors.champagneLight, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '🔒 Exact birth date remains strictly private. Only your age is shown to friends.',
                style: AaraTypography.labelSmall.copyWith(color: AaraColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 18),

              // 4. Gender (Male, Female, Others)
              Text('Gender', style: AaraTypography.labelLarge.copyWith(color: AaraColors.champagneLight)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: ['Male', 'Female', 'Others', 'Prefer not to say'].map((g) {
                  final isSelected = _selectedGender == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    selectedColor: AaraColors.champagne,
                    backgroundColor: AaraColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AaraColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AaraColors.champagne : AaraColors.border,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedGender = g);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // 5. State & City
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('State', style: AaraTypography.labelLarge.copyWith(color: AaraColors.champagneLight)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AaraColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AaraColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedState,
                              dropdownColor: AaraColors.surfaceCard,
                              isExpanded: true,
                              style: const TextStyle(color: AaraColors.textPrimary, fontSize: 13),
                              items: IndianData.statesAndUTs.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedState = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('City', style: AaraTypography.labelLarge.copyWith(color: AaraColors.champagneLight)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cityController,
                          style: const TextStyle(color: AaraColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AaraColors.surface,
                            hintText: 'City (optional)',
                            hintStyle: const TextStyle(color: AaraColors.textMuted, fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AaraColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AaraColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AaraColors.champagne)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 6. Looking For (Bio) with Strict Phone Number Privacy Check
              Row(
                children: [
                  const Icon(Icons.format_quote, color: AaraColors.champagneLight, size: 20),
                  const SizedBox(width: 6),
                  Text('Looking For (Bio / Note)', style: AaraTypography.labelLarge.copyWith(color: AaraColors.champagneLight)),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lookingForController,
                maxLines: 3,
                style: const TextStyle(color: AaraColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AaraColors.surface,
                  hintText: 'Describe yourself and what kind of conversations or friends you want to meet...',
                  hintStyle: const TextStyle(color: AaraColors.textMuted, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AaraColors.border)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _phoneValidationError != null ? AaraColors.error : AaraColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _phoneValidationError != null ? AaraColors.error : AaraColors.champagne,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Warning Alert: Only shown when phone number is entered into Looking For
              if (_phoneValidationError != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AaraColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AaraColors.error.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AaraColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _phoneValidationError!,
                          style: const TextStyle(color: AaraColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AaraColors.champagne,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    _isSaving ? 'Saving Changes...' : 'Save Profile',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
