import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/points_costs.dart';

class ChatPage extends StatefulWidget {
  /// Optionally pass a conversationId + other user's name.
  final int? conversationId;
  final String? otherUserName;

  const ChatPage({
    super.key,
    this.conversationId,
    this.otherUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final SupabaseClient _client;
  String? _userId;
  int? _currentPoints;
  bool _loadingPoints = true;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _userId = _client.auth.currentUser?.id;
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    if (_userId == null) {
      setState(() {
        _loadingPoints = false;
      });
      return;
    }

    try {
      final row = await _client
          .from('user_points')
          .select('available_points')
          .eq('user_id', _userId!)
          .maybeSingle();

      setState(() {
        _currentPoints = (row?['available_points'] as int?) ?? 0;
        _loadingPoints = false;
      });
    } catch (e) {
      setState(() {
        _loadingPoints = false;
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
            const SnackBar(content: Text('Not enough points for video call.')),
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

  Future<void> _handleVideoCallPressed() async {
    if (widget.conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Conversation not loaded yet. Pass a conversationId to ChatPage.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start video call?'),
        content: Text(
          'Start a video call with this match for '
          '${PointsCosts.videoCall} points?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _spendPoints(PointsCosts.videoCall);
    if (!ok) return;

    try {
      // Mark this conversation as having video unlocked (optional)
      await _client
          .from('conversations')
          .update({'video_unlocked': true})
          .eq('id', widget.conversationId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Points spent! TODO: integrate real video call (Agora / Jitsi).',
          ),
        ),
      );

      // 🔧 This is where you will integrate actual video call logic.
      // For example: Navigator.pushNamed(context, '/videoCall', arguments: ...);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update conversation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.otherUserName ?? 'Chat';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _handleVideoCallPressed,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loadingPoints)
            const LinearProgressIndicator(minHeight: 2)
          else if (_currentPoints != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Your points: $_currentPoints',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const Expanded(
            child: Center(
              child: Text(
                'Chat UI coming soon.\n'
                'This screen is ready to be connected to your messages stream.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Later: message input field goes here.
        ],
      ),
    );
  }
}
