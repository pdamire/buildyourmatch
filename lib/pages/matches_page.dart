import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/points_costs.dart';
import '../../services/points_service.dart';
import '../../services/challenge_service.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late final SupabaseClient _client;
  late final PointsService _pointsService;
  late final ChallengeService _challengeService;

  String? _userId;

  bool _loading = true;
  bool _readyForMatching = false; // NEW: has user answered >= 20 core questions?
  String? _error;

  int? _currentPoints;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _pointsService = PointsService(_client);
    _challengeService = ChallengeService(_client, _pointsService);
    _userId = _client.auth.currentUser?.id;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) {
      setState(() {
        _loading = false;
        _readyForMatching = false;
        _error = 'No logged-in user.';
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // 0) Check if user has completed initial 20 core psychology questions
      final ready =
          await _challengeService.hasCompletedInitialQuestionSet(_userId!);

      if (!ready) {
        setState(() {
          _loading = false;
          _readyForMatching = false;
          _error =
              'Answer at least 20 relationship questions so we can build your match profile.';
        });
        return;
      }

      // If we get here, user is ready to be in the matching pool
      _readyForMatching = true;

      // 1) Load current points
      final pointsRow = await _client
          .from('user_points')
          .select('available_points')
          .eq('user_id', _userId!)
          .maybeSingle();

      final availablePoints = (pointsRow?['available_points'] as int?) ?? 0;

      // 2) Load conversations where current user is A or B
      final convoRows = await _client
          .from('conversations')
          .select('id,user_a_uuid,user_b_uuid,photo_unlocked,created_at')
          .or('user_a_uuid.eq.${_userId!},user_b_uuid.eq.${_userId!}')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> matches = [];

      for (final row in convoRows as List) {
        final String userA = row['user_a_uuid'] as String;
        final String userB = row['user_b_uuid'] as String;

        final String otherUserId =
            userA == _userId! ? userB : userA; // pick the "other" person

        // Fetch basic info about the other user.
        // 🔧 NOTE: adjust column names to match your "users" table.
        final userRow = await _client
            .from('users')
            .select('id, full_name, avatar_url, bio')
            .eq('id', otherUserId)
            .maybeSingle();

        matches.add({
          'conversationId': row['id'],
          'photoUnlocked': row['photo_unlocked'] as bool? ?? false,
          'otherUserId': otherUserId,
          'name': userRow?['full_name'] ?? 'Someone',
          'avatarUrl': userRow?['avatar_url'],
          'bio': userRow?['bio'] ?? '',
        });
      }

      setState(() {
        _currentPoints = availablePoints;
        _matches = matches;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        // If they got here, they were ready for matching but loading failed
        _readyForMatching = true;
        _error = 'Failed to load matches: $e';
      });
    }
  }

  Future<bool> _spendPoints(int cost) async {
    if (_userId == null) return false;

    try {
      final row = await _client
          .from('user_points')
          .select('available_points')
          .eq('user_id', _userId!)
          .single();

      final current = row['available_points'] as int? ?? 0;
      if (current < cost) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough points to unlock.')),
          );
        }
        return false;
      }

      final updated = current - cost;

      await _client
          .from('user_points')
          .update({'available_points': updated})
          .eq('user_id', _userId!);

      if (mounted) {
        setState(() {
          _currentPoints = updated;
        });
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error spending points: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _unlockPhoto(Map<String, dynamic> match) async {
    final convoId = match['conversationId'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock photo?'),
        content: Text(
          'Spend ${PointsCosts.unlockImage} points to unlock this match\'s photo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _spendPoints(PointsCosts.unlockImage);
    if (!ok) return;

    try {
      await _client
          .from('conversations')
          .update({'photo_unlocked': true})
          .eq('id', convoId);

      if (mounted) {
        setState(() {
          final idx = _matches.indexOf(match);
          if (idx != -1) {
            _matches[idx] = {
              ..._matches[idx],
              'photoUnlocked': true,
            };
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo unlocked!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update conversation: $e')),
        );
      }
    }
  }

  Widget _buildAvatar(Map<String, dynamic> match) {
    final unlocked = match['photoUnlocked'] as bool? ?? false;
    final avatarUrl = match['avatarUrl'] as String?;

    if (!unlocked) {
      // Locked state: generic avatar + lock
      return Stack(
        alignment: Alignment.center,
        children: [
          const CircleAvatar(
            radius: 28,
            child: Icon(Icons.person),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.lock,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Unlocked state: show actual avatar if available
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    return const CircleAvatar(
      radius: 28,
      child: Icon(Icons.person),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1) Still loading
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Matches'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Not ready for matching yet (has < 20 core questions)
    if (!_readyForMatching) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Matches'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ??
                      'Answer at least 20 relationship questions to unlock your matches.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: replace with your actual navigation
                    // to the main questions / daily challenges page.
                    //
                    // Example if you have a route:
                    // Navigator.pushNamed(context, '/challenges');
                  },
                  child: const Text('Start answering questions'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3) Ready for matching but an error occurred loading matches
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Matches'),
          centerTitle: true,
        ),
        body: Center(child: Text(_error!)),
      );
    }

    // 4) Ready for matching, no error – show matches list
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Matches'),
        centerTitle: true,
      ),
      body: _matches.isEmpty
          ? const Center(
              child: Text(
                'No matches yet.\nKeep answering questions and we\'ll keep looking.',
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                if (_currentPoints != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Your points: $_currentPoints',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      final unlocked =
                          match['photoUnlocked'] as bool? ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: _buildAvatar(match),
                          title: Text(match['name'] as String),
                          subtitle:
                              Text(match['bio'] as String? ?? 'No bio yet.'),
                          trailing: unlocked
                              ? const Icon(
                                  Icons.lock_open,
                                  color: Colors.green,
                                )
                              : TextButton(
                                  onPressed: () => _unlockPhoto(match),
                                  child: Text(
                                      'Unlock\n${PointsCosts.unlockImage} pts'),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
