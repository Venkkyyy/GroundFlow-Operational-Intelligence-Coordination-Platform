import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gf_network_pill.dart';
import '../../core/network/data_usage_manager.dart';

class ChatScreen extends StatefulWidget {
  final String eventId;
  const ChatScreen({super.key, required this.eventId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _selectedChannel = '#media-all';
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _channels = [
    '#media-all',
    '#squad-alpha',
    '#dump-room',
    '#gear',
    '#building-auditorium',
    '#urgent',
  ];

  bool _announcementAcknowledged = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      id: 'm1',
      sender: 'Vinik Shah (Head)',
      text: 'Good morning everyone! Please check out your camera bundles from Room B-104 by 09:30 AM.',
      time: '09:02 AM',
      isMe: false,
      isAnnouncement: true,
      ackCount: 68,
      totalCount: 78,
    ),
    _ChatMessage(
      id: 'm2',
      sender: 'Arjun Mehta',
      text: 'Squad Alpha is geared up. We have Kit #1 and wireless mics at Hall 1.',
      time: '09:25 AM',
      isMe: false,
    ),
    _ChatMessage(
      id: 'm3',
      sender: 'Me',
      text: 'Confirmed. Audio checks are clean. Lighting looks ready for 10 AM opening.',
      time: '09:28 AM',
      isMe: true,
    ),
    _ChatMessage(
      id: 'm4',
      sender: 'Dump Room (Operator)',
      text: 'Dump Station B-204 is OPEN. High-speed card readers active for card drops.',
      time: '09:45 AM',
      isMe: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_selectedChannel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const Text('78 members • Low-Data Protocol', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos_rounded, color: AppColors.danger),
            tooltip: 'Emergency SOS',
            onPressed: () => _showSosDialog(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: GFNetworkPill(compact: true),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Communication Channels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Department-scoped & Travel Aware', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _channels.length,
                  itemBuilder: (ctx, i) {
                    final ch = _channels[i];
                    final isSel = ch == _selectedChannel;
                    final isUrgent = ch == '#urgent';
                    return ListTile(
                      leading: Icon(
                        isUrgent ? Icons.error_outline_rounded : Icons.tag_rounded,
                        color: isUrgent ? AppColors.danger : (isSel ? AppColors.primary : Colors.grey),
                        size: 20,
                      ),
                      title: Text(
                        ch,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isUrgent ? AppColors.danger : (isSel ? AppColors.primary : null),
                          fontSize: 14,
                        ),
                      ),
                      selected: isSel,
                      selectedTileColor: AppColors.primary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        setState(() => _selectedChannel = ch);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Announcement Banner (Needs Acknowledge)
          if (!_announcementAcknowledged)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.amber.withOpacity(0.12),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'All-Hands: Attendance Round 2 opens at 12:00 PM.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      setState(() => _announcementAcknowledged = true);
                      DataUsageManager().trackNetworkTransfer(upload: 120);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Read receipt acknowledged.')),
                      );
                    },
                    child: const Text('Acknowledge (68/78)'),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                return _MessageBubble(message: m);
              },
            ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_location_alt_outlined, color: Colors.blueGrey, size: 20),
                    tooltip: 'Share Pin',
                    onPressed: () {
                      _sendMessage('📍 Shared location: Building A, Ground Floor Hall');
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Message $_selectedChannel...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (txt) => _sendMessage(txt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(_msgController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          id: 'm-${DateTime.now().millisecondsSinceEpoch}',
          sender: 'Me',
          text: text.trim(),
          time: 'Just now',
          isMe: true,
        ),
      );
      _msgController.clear();
    });
    DataUsageManager().trackNetworkTransfer(upload: text.length + 80);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Broadcast SOS Ticket?'),
          ],
        ),
        content: const Text(
          'Sends high-priority distress signal with your GPS location to the Department Head, Security squad, and your Team Lead.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              _sendMessage('🚨 [SOS EMERGENCY] Need assistance at current location!');
            },
            child: const Text('Trigger SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String id, sender, text, time;
  final bool isMe, isAnnouncement;
  final int? ackCount, totalCount;

  _ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    this.isAnnouncement = false,
    this.ackCount,
    this.totalCount,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                message.sender[0],
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : (message.isAnnouncement ? Colors.amber.withOpacity(0.15) : Theme.of(context).cardColor),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isMe ? AppColors.primary : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.sender,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: message.isAnnouncement ? Colors.orange[800] : AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (message.ackCount != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${message.ackCount}/${message.totalCount} read',
                          style: TextStyle(fontSize: 10, color: Colors.orange[800]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
