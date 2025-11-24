import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/challenge.dart';
import 'daily_dice_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../data/supabase_client.dart';
import '../../auth/auth_gate.dart';
import '../../services/points_service.dart';
import '../../services/daily_dice_service.dart';
import '../../services/challenge_service.dart';
import '../../services/match_service.dart';
import '../models/challenge.dart';
import '../progress/widgets/gm_progress_ring.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SupabaseClient _client;
  late final PointsService _pointsService;
  late final DailyDiceService _dailyDiceService;
  late final ChallengeService _challengeService;
  late final MatchService _matchService;

  String? _userId;
  int? _balance;

  /// Today’s challenges future
  late Future<List<Challenge>> fut;

  @override
  void initState() {
    super.initState();

    // Supabase client
    _client = Supabase.instance.client;

    // Services
    _pointsService = PointsService(_client);
    _dailyDiceService = DailyDiceService(_client, _pointsService);
    _challengeService = ChallengeService(_client, _pointsService);
    _matchService = MatchService(_client);

    // Load today’s challenges
    fut = _challengeService.fetchDailyChallenges();

    // Load balance
    _userId = _client.auth.currentUser?.id;
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    if (_userId == null) return;
    final b = await _pointsService.getBalance(_userId!);
    if (!mounted) return;
    setState(() => _balance = b); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Build Your Match'),
  actions: [
    IconButton(
      icon: const Icon(Icons.person),
      tooltip: 'Profile',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
        );
      },
    ),
  ],
),
          IconButton(
            onPressed: () => context.push('/store'),
            icon: const Icon(Icons.bolt),
          ),
          IconButton(
            onPressed: () => context.push('/admin'),
            icon: const Icon(Icons.admin_panel_settings),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header card
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const GmProgressRing(value: 0.3),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grow first. Then meet.',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Streak: 3 days   XP: 75',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.push('/challenge'),
                          child: const Text('Play a Mini-Game'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Daily dice
          const DailyDiceCard(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              "Today's Challenges",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),

          // Today's challenges list
          FutureBuilder<List<Challenge>>(
            future: fut,
            builder: (context, snap) {
              final items = snap.data ?? [];

              return Column(
                children: items.map((c) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite),
                      title: Text(c.title),
                      subtitle: Text(c.promptText),
                      trailing: const Icon(Icons.chevron_right, color: Colors.pink),
                      onTap: () => context.push('/challenge', extra: c),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              context.push('/progress');
              break;
            case 2:
              context.push('/coach');
              break;
            case 3:
              context.push('/match');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.stacked_line_chart_outlined),
            selectedIcon: Icon(Icons.stacked_line_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Match',
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers
  final TextEditingController _dobController = TextEditingController();

  // Supabase
  late final SupabaseClient _supabase;
  String? _userId;

  // Profile fields
  List<String> selectedGenders = [];
  List<String> selectedOrientations = [];
  List<String> selectedRaces = [];
  List<String> selectedEthnicities = [];
  List<String> selectedLanguages = [];

  // Image
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _userId = _supabase.auth.currentUser?.id;
  }

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  // ---------------------
  // AGE CALCULATOR
  // ---------------------
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

  // ---------------------
  // IMAGE PICK + UPLOAD
  // ---------------------
  Future<void> _pickAndUploadImage() async {
    try {
      final image =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isUploading = true);

      final bytes = await image.readAsBytes();
      final filePath = '${_userId}/profile.jpg';

      // Upload to Supabase Storage bucket named: profile_images
      await _supabase.storage.from('profile_images').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl =
          _supabase.storage.from('profile_images').getPublicUrl(filePath);

      setState(() {
        _imageUrl = publicUrl;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      debugPrint('Upload error: $e');
    }
  }

  // ---------------------
  // SAVE PROFILE
  // ---------------------
  Future<void> _onSavePressed() async {
    final dobText = _dobController.text.trim();
    final age = _calculateAgeFromDobString(dobText);

    // Reject under 21
    if (age == null || age < 21) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('You must be at least 21 years old to use Build Your Match.'),
        ),
      );
      return;
    }

    await _supabase.from('users').update({
      'dob': dobText,
      'gender': selectedGenders,
      'orientation': selectedOrientations,
      'race': selectedRaces,
      'ethnicity': selectedEthnicities,
      'languages': selectedLanguages,
      'profile_image': _imageUrl,
    }).eq('id', _userId!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved!')),
    );
  }

  // ---------------------
  // UI
  // ---------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Center(
              child: GestureDetector(
                onTap: _pickAndUploadImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                  child: _imageUrl == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Basic Info
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // DOB
            TextField(
              controller: _dobController,
              decoration: const InputDecoration(
                labelText: 'Date of birth (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Location
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Languages
            const Text(
              'Languages you speak',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Languages (e.g., English, Farsi, Spanish)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Photo rules
            const Text(
              'Photo Rules:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '- No nude photos.\n'
              '- No photos of other people Photoshopped as you.\n'
              '- Photos must be clear and not blurry.\n'
              '- No harmful, abusive, or illegal content.\n'
              '- You must have the right to share these photos.',
              style: TextStyle(fontSize: 13),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSavePressed,
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
