import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _otherLanguagesController = TextEditingController();

  File? _pickedImageFile;
  String? _existingImageUrl;

  bool _isSaving = false;
  bool _isLoading = true;

  // Multi-select sets
  Set<String> _selectedGenders = {};
  Set<String> _selectedOrientations = {};
  Set<String> _selectedRaces = {};
  Set<String> _selectedEthnicities = {};
  Set<String> _selectedLanguages = {};

  // --- Options (you can customize/expand these) ---

  static const List<String> genderOptions = [
    'Woman',
    'Man',
    'Non-binary',
    'Transgender',
    'Genderqueer',
    'Prefer not to say',
    'Other',
  ];

  static const List<String> orientationOptions = [
    'Straight',
    'Gay',
    'Lesbian',
    'Bisexual',
    'Pansexual',
    'Asexual',
    'Questioning',
    'Other',
  ];

  static const List<String> raceOptions = [
    'Asian',
    'Black',
    'White',
    'Latino / Hispanic',
    'Middle Eastern / North African',
    'Native American / Indigenous',
    'Pacific Islander',
    'Mixed',
    'Other',
    'Prefer not to say',
  ];

  static const List<String> ethnicityOptions = [
    'Hispanic / Latino',
    'Non-Hispanic',
    'Persian / Iranian',
    'South Asian',
    'East Asian',
    'African',
    'European',
    'Middle Eastern',
    'Other',
    'Prefer not to say',
  ];

  static const List<String> languageOptions = [
    'English',
    'Spanish',
    'Farsi',
    'French',
    'Arabic',
    'Hindi',
    'Mandarin',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _dobController.dispose();
    _otherLanguagesController.dispose();
    super.dispose();
  }

  // -------------------------
  // LOAD PROFILE FROM SUPABASE
  // -------------------------

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logged in user.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final data = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // if maybeSingle isn't available, use .single()

      if (data != null) {
        // DOB
        final dobVal = data['dob'];
        if (dobVal != null) {
          _dobController.text = dobVal.toString().substring(0, 10); // YYYY-MM-DD
        }

        // Profile image URL
        final profileImage = data['profile_image_url'];
        if (profileImage is String && profileImage.isNotEmpty) {
          _existingImageUrl = profileImage;
        }

        // Helper to read column that might be text or array/json
        Set<String> _readMulti(dynamic value) {
          if (value == null) return {};
          if (value is List) {
            return value.map((e) => e.toString()).toSet();
          }
          if (value is String && value.isNotEmpty) {
            // Single stored string → make it a set
            return {value};
          }
          return {};
        }

        _selectedGenders = _readMulti(data['gender']);
        _selectedOrientations = _readMulti(data['orientation']);
        _selectedRaces = _readMulti(data['race']);
        _selectedEthnicities = _readMulti(data['ethnicity']);
        _selectedLanguages = _readMulti(data['languages']);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // -------------------------
  // DATE OF BIRTH / AGE CHECK
  // -------------------------

  Future<void> _pickDob() async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
    DateTime firstDate = DateTime(1920);
    DateTime lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      _dobController.text = picked.toIso8601String().substring(0, 10);
    }
  }

  int? _calculateAgeFromDobString(String dobText) {
    try {
      final dob = DateTime.parse(dobText.trim()); // expects YYYY-MM-DD
      final now = DateTime.now();
      int age = now.year - dob.year;

      final hasHadBirthdayThisYear =
          (now.month > dob.month) ||
          (now.month == dob.month && now.day >= dob.day);

      if (!hasHadBirthdayThisYear) {
        age -= 1;
      }
      return age;
    } catch (_) {
      return null; // invalid format
    }
  }

  // -------------------------
  // IMAGE PICK + UPLOAD
  // -------------------------

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      _pickedImageFile = File(picked.path);
    });
  }

  Future<String?> _uploadImageIfNeeded(String userId) async {
    // If user didn't pick a new image, keep existing URL
    if (_pickedImageFile == null) {
      return _existingImageUrl;
    }

    try {
      final bytes = await _pickedImageFile!.readAsBytes();
      final filePath = 'users/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Change 'profile-images' if your bucket is named differently
      await _supabase.storage.from('profile-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl =
          _supabase.storage.from('profile-images').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      if (!mounted) return _existingImageUrl;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return _existingImageUrl;
    }
  }

  // -------------------------
  // SAVE PROFILE
  // -------------------------

  Future<void> _onSavePressed() async {
    if (_isSaving) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged in user.')),
      );
      return;
    }

    final dobText = _dobController.text.trim();

    if (dobText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth.')),
      );
      return;
    }

    final age = _calculateAgeFromDobString(dobText);
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid date of birth format.')),
      );
      return;
    }

    if (age < 21) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be at least 21 years old to use Build Your Match.',
          ),
        ),
      );
      return;
    }

    if (_selectedGenders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one gender option.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final imageUrl = await _uploadImageIfNeeded(user.id);

      // Merge languages + custom "other" languages if any
      final languages = <String>{..._selectedLanguages};
      final otherLangRaw = _otherLanguagesController.text.trim();
      if (otherLangRaw.isNotEmpty) {
        languages.addAll(
          otherLangRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }

      final updateData = <String, dynamic>{
        'dob': dobText,
        // These fields assume your users table has these columns.
        // Adjust names/types if needed.
        'gender': _selectedGenders.toList(),
        'orientation': _selectedOrientations.toList(),
        'race': _selectedRaces.toList(),
        'ethnicity': _selectedEthnicities.toList(),
        'languages': languages.toList(),
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        updateData['profile_image_url'] = imageUrl;
      }

      await _supabase.from('users').update(updateData).eq('id', user.id);

      if (!mounted) return;
      setState(() {
        _existingImageUrl = imageUrl ?? _existingImageUrl;
        _pickedImageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // -------------------------
  // WIDGET HELPERS
  // -------------------------

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> options,
    required Set<String> selected,
    required void Function(Set<String>) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            final newSet = Set<String>.from(selected);
            if (value) {
              newSet.add(option);
            } else {
              newSet.remove(option);
            }
            onChanged(newSet);
          },
        );
      }).toList(),
    );
  }

  // -------------------------
  // BUILD
  // -------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Your Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _pickedImageFile != null
                                ? FileImage(_pickedImageFile!)
                                : (_existingImageUrl != null
                                    ? NetworkImage(_existingImageUrl!)
                                        as ImageProvider
                                    : null),
                            child: (_pickedImageFile == null &&
                                    _existingImageUrl == null)
                                ? const Icon(Icons.add_a_photo, size: 32)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Tap to change profile photo',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),

                      // DOB
                      _buildSectionTitle('Date of Birth'),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dobController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: 'YYYY-MM-DD',
                                border: OutlineInputBorder(),
                              ),
                              onTap: _pickDob,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickDob,
                          ),
                        ],
                      ),

                      // Gender
                      _buildSectionTitle('Gender Identity'),
                      _buildMultiSelectChips(
                        options: genderOptions,
                        selected: _selectedGenders,
                        onChanged: (set) =>
                            setState(() => _selectedGenders = set),
                      ),

                      // Orientation
                      _buildSectionTitle('Sexual Orientation'),
                      _buildMultiSelectChips(
                        options: orientationOptions,
                        selected: _selectedOrientations,
                        onChanged: (set) =>
                            setState(() => _selectedOrientations = set),
                      ),

                      // Race
                      _buildSectionTitle('Race'),
                      _buildMultiSelectChips(
                        options: raceOptions,
                        selected: _selectedRaces,
                        onChanged: (set) =>
                            setState(() => _selectedRaces = set),
                      ),

                      // Ethnicity
                      _buildSectionTitle('Ethnicity'),
                      _buildMultiSelectChips(
                        options: ethnicityOptions,
                        selected: _selectedEthnicities,
                        onChanged: (set) =>
                            setState(() => _selectedEthnicities = set),
                      ),

                      // Languages
                      _buildSectionTitle('Languages You Speak'),
                      _buildMultiSelectChips(
                        options: languageOptions,
                        selected: _selectedLanguages,
                        onChanged: (set) =>
                            setState(() => _selectedLanguages = set),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Other languages (comma-separated):',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _otherLanguagesController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. German, Italian',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _onSavePressed,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
