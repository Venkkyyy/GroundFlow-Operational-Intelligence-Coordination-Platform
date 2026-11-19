import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- Mock Data ---
class _MockEvent {
  final String id;
  final String name;
  final String date;
  final String role;
  final int memberCount;
  final Color color;
  const _MockEvent({required this.id, required this.name, required this.date, required this.role, required this.memberCount, required this.color});
}

class _MockTask {
  final String title;
  final String location;
  final String time;
  final String status; // pending | in-progress | done
  const _MockTask({required this.title, required this.location, required this.time, required this.status});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color kPrimary = Color(0xFF3D5AFE);
  static const Color kDanger = Color(0xFFEF4444);

  bool _isOffline = false;
  bool _isRefreshing = false;

  final String _userName = 'Alex Johnson';
  final String _initials = 'AJ';

  final List<_MockEvent> _events = const [
    _MockEvent(id: '1', name: 'BCS Annual Fest 2024', date: 'Nov 22–24, 2024', role: 'Media Lead', memberCount: 487, color: Color(0xFF3D5AFE)),
    _MockEvent(id: '2', name: 'TechExpo Spring', date: 'Feb 10, 2025', role: 'Photographer', memberCount: 230, color: Color(0xFF7C3AED)),
    _MockEvent(id: '3', name: 'Alumni Day', date: 'Mar 5, 2025', role: 'Videographer', memberCount: 95, color: Color(0xFF059669)),
  ];

  final List<_MockTask> _tasks = const [
    _MockTask(title: 'Main Stage Photography', location: 'Auditorium A', time: '10:00 – 12:00', status: 'in-progress'),
    _MockTask(title: 'Behind-the-scenes Coverage', location: 'Backstage', time: '14:00 – 16:00', status: 'pending'),
    _MockTask(title: 'Gear Return & Handoff', location: 'Media Room', time: '17:30', status: 'pending'),
  ];

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(colorScheme),
            if (_isOffline) SliverToBoxAdapter(child: _buildOfflineBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Upcoming Events', Icons.event_rounded),
                  const SizedBox(height: 14),
                  _buildEventCards(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('My Tasks Today', Icons.task_alt_rounded),
                  const SizedBox(height: 14),
                  ..._tasks.asMap().entries.map((e) => _buildTaskCard(e.value, e.key)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: kPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimary, Color(0xFF1A237E)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0, duration: 500.ms),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      color: const Color(0xFFFEF2F2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'You\'re offline. Showing cached data.',
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _isOffline = false),
            child: const Text('Retry', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.qr_code_scanner_rounded, 'label': 'Scan QR', 'color': const Color(0xFF3D5AFE)},
      {'icon': Icons.sos_rounded, 'label': 'SOS', 'color': const Color(0xFFEF4444)},
      {'icon': Icons.calendar_today_rounded, 'label': 'Schedule', 'color': const Color(0xFF059669)},
      {'icon': Icons.forum_rounded, 'label': 'Channels', 'color': const Color(0xFF7C3AED)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.asMap().entries.map((e) {
            final action = e.value;
            return _QuickActionButton(
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: () {},
            ).animate(delay: (e.key * 80).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPrimary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('See all', style: TextStyle(color: kPrimary))),
      ],
    );
  }

  Widget _buildEventCards() {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final event = _events[i];
          return _EventCard(event: event)
              .animate(delay: (i * 100).ms)
              .fadeIn(duration: 500.ms)
              .slideX(begin: 0.2, end: 0, duration: 500.ms);
        },
      ),
    );
  }

  Widget _buildTaskCard(_MockTask task, int index) {
    final statusData = _statusInfo(task.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
        border: Border(left: BorderSide(color: statusData['color'] as Color, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(task.location, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(task.time, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
          _StatusChip(label: statusData['label'] as String, color: statusData['color'] as Color),
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'in-progress':
        return {'label': 'In Progress', 'color': const Color(0xFF3D5AFE)};
      case 'done':
        return {'label': 'Done', 'color': const Color(0xFF059669)};
      case 'cancelled':
        return {'label': 'Cancelled', 'color': const Color(0xFFEF4444)};
      default:
        return {'label': 'Pending', 'color': const Color(0xFF9CA3AF)};
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _MockEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [event.color, event.color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: event.color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(event.role, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Spacer(),
            Text(
              event.name,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 13),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    event.date,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.people_outline_rounded, color: Colors.white70, size: 13),
                const SizedBox(width: 4),
                Text('${event.memberCount}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
