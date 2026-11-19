import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- Mock Data ---
enum MemberStatus { notArrived, present, onShoot, onBreak, needsHelp, missedCheckIn }

class _MockMember {
  final String name;
  final String squad;
  final MemberStatus status;
  final String? location;
  const _MockMember({required this.name, required this.squad, required this.status, this.location});
}

class _MockShoot {
  final String name;
  final String location;
  final int crewCount;
  final String stage;
  final Color stageColor;
  const _MockShoot({required this.name, required this.location, required this.crewCount, required this.stage, required this.stageColor});
}

class _MockIssue {
  final String title;
  final String assignee;
  final String priority; // high | medium | low
  final String time;
  final bool escalated;
  const _MockIssue({required this.title, required this.assignee, required this.priority, required this.time, this.escalated = false});
}

class ControlRoomScreen extends StatefulWidget {
  final String? eventId;
  const ControlRoomScreen({super.key, this.eventId});

  @override
  State<ControlRoomScreen> createState() => _ControlRoomScreenState();
}

class _ControlRoomScreenState extends State<ControlRoomScreen> {
  static const Color kPrimary = Color(0xFF3D5AFE);

  String _selectedBuilding = 'All';
  String _selectedSquad = 'All';
  String _selectedStatus = 'All';

  final List<String> _buildings = ['All', 'Block A', 'Block B', 'Auditorium', 'Outdoor'];
  final List<String> _squads = ['All', 'Media', 'Logistics', 'Backstage', 'Security'];
  final List<String> _statuses = ['All', 'Present', 'On Shoot', 'Break', 'Needs Help'];

  final List<_MockMember> _members = const [
    _MockMember(name: 'Alex Johnson', squad: 'Media', status: MemberStatus.onShoot, location: 'Main Stage'),
    _MockMember(name: 'Priya Sharma', squad: 'Media', status: MemberStatus.present),
    _MockMember(name: 'Ravi Kumar', squad: 'Backstage', status: MemberStatus.onBreak),
    _MockMember(name: 'Chen Wei', squad: 'Logistics', status: MemberStatus.needsHelp, location: 'Gate 2'),
    _MockMember(name: 'Sara Ali', squad: 'Security', status: MemberStatus.present),
    _MockMember(name: 'Mohammed K', squad: 'Media', status: MemberStatus.missedCheckIn),
    _MockMember(name: 'Lia Santos', squad: 'Logistics', status: MemberStatus.notArrived),
    _MockMember(name: 'Dhruv Patel', squad: 'Media', status: MemberStatus.onShoot, location: 'Press Room'),
  ];

  final List<_MockShoot> _shoots = const [
    _MockShoot(name: 'Inauguration Ceremony', location: 'Main Stage', crewCount: 5, stage: 'Ingesting', stageColor: Color(0xFF3D5AFE)),
    _MockShoot(name: 'Dance Competition', location: 'Auditorium B', crewCount: 3, stage: 'Shot', stageColor: Color(0xFF059669)),
    _MockShoot(name: 'Press Conference', location: 'Press Room', crewCount: 2, stage: 'Editing', stageColor: Color(0xFF7C3AED)),
  ];

  final List<_MockIssue> _issues = const [
    _MockIssue(title: 'Camera battery depleted at Main Stage', assignee: 'Alex J.', priority: 'high', time: '5m ago', escalated: true),
    _MockIssue(title: 'Missing volunteer: Squad B Gate 3', assignee: 'Priya S.', priority: 'medium', time: '12m ago'),
    _MockIssue(title: 'SD card reader not working', assignee: 'Chen W.', priority: 'low', time: '28m ago'),
  ];

  List<_MockMember> get _filteredMembers {
    return _members.where((m) {
      if (_selectedSquad != 'All' && m.squad != _selectedSquad) return false;
      if (_selectedStatus != 'All') {
        final statusName = _statusLabel(m.status);
        if (!statusName.contains(_selectedStatus)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIssueCreationSheet,
        backgroundColor: const Color(0xFFEF4444),
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text('Report Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverToBoxAdapter(child: _buildPeopleBoardSection()),
          SliverToBoxAdapter(child: _buildActiveShootsSection()),
          SliverToBoxAdapter(child: _buildGearBoard()),
          SliverToBoxAdapter(child: _buildIssuesFeed()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF0D1117),
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: const Color(0xFF10B981)),
            const SizedBox(width: 8),
            const Text('Control Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            const Spacer(),
            Text('LIVE', style: TextStyle(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ],
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white70), onPressed: () {}),
        IconButton(icon: const Icon(Icons.tune_rounded, color: Colors.white70), onPressed: () {}),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {'label': 'Present', 'value': '312', 'icon': Icons.people_rounded, 'color': const Color(0xFF10B981)},
      {'label': 'Active Shoots', 'value': '8', 'icon': Icons.videocam_rounded, 'color': const Color(0xFF3D5AFE)},
      {'label': 'Open Issues', 'value': '3', 'icon': Icons.warning_amber_rounded, 'color': const Color(0xFFF59E0B)},
      {'label': 'Gear Out', 'value': '47', 'icon': Icons.camera_alt_rounded, 'color': const Color(0xFFEF4444)},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final s = e.value;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (s['color'] as Color).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                  const SizedBox(height: 8),
                  Text(s['value'] as String,
                      style: TextStyle(color: s['color'] as Color, fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(s['label'] as String, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ).animate(delay: (e.key * 80).ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildFilterDropdown('Building', _buildings, _selectedBuilding, (v) => setState(() => _selectedBuilding = v!)),
          const SizedBox(width: 8),
          _buildFilterDropdown('Squad', _squads, _selectedSquad, (v) => setState(() => _selectedSquad = v!)),
          const SizedBox(width: 8),
          _buildFilterDropdown('Status', _statuses, _selectedStatus, (v) => setState(() => _selectedStatus = v!)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> options, String selected, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected != 'All' ? kPrimary : const Color(0xFF30363D)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: const Color(0xFF161B22),
          style: TextStyle(
            color: selected != 'All' ? kPrimary : const Color(0xFF8B949E),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: selected != 'All' ? kPrimary : const Color(0xFF8B949E), size: 18),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPeopleBoardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDarkSectionHeader('People Board', Icons.people_alt_rounded, '${_filteredMembers.length} members'),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: _filteredMembers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final member = _filteredMembers[i];
              return _MemberCard(member: member).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveShootsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDarkSectionHeader('Active Shoots', Icons.videocam_rounded, '${_shoots.length} running'),
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _shoots.length,
          itemBuilder: (context, i) {
            final shoot = _shoots[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: shoot.stageColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.movie_creation_outlined, color: shoot.stageColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shoot.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFF8B949E), size: 12),
                            const SizedBox(width: 4),
                            Text(shoot.location, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                            const SizedBox(width: 10),
                            const Icon(Icons.people_outline, color: Color(0xFF8B949E), size: 12),
                            const SizedBox(width: 4),
                            Text('${shoot.crewCount}', style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: shoot.stageColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: shoot.stageColor.withOpacity(0.4)),
                    ),
                    child: Text(shoot.stage, style: TextStyle(color: shoot.stageColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ).animate(delay: (i * 80).ms).fadeIn(duration: 400.ms);
          },
        ),
      ],
    );
  }

  Widget _buildGearBoard() {
    final gearStats = [
      {'label': 'Out', 'value': '47', 'color': const Color(0xFF3D5AFE)},
      {'label': 'Overdue', 'value': '3', 'color': const Color(0xFFF59E0B)},
      {'label': 'Missing', 'value': '1', 'color': const Color(0xFFEF4444)},
      {'label': 'Charging', 'value': '12', 'color': const Color(0xFF10B981)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDarkSectionHeader('Gear Board', Icons.camera_alt_rounded, null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: gearStats.map((g) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: (g['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (g['color'] as Color).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(g['value'] as String, style: TextStyle(color: g['color'] as Color, fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(g['label'] as String, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDarkSectionHeader('Issues', Icons.warning_amber_rounded, '${_issues.length} open'),
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _issues.length,
          itemBuilder: (context, i) {
            final issue = _issues[i];
            final priorityColor = issue.priority == 'high'
                ? const Color(0xFFEF4444)
                : issue.priority == 'medium'
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: priorityColor, width: 3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issue.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(issue.assignee, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                            const SizedBox(width: 10),
                            Text(issue.time, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(issue.priority.toUpperCase(), style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      if (issue.escalated) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('↑ ESCALATED', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDarkSectionHeader(String title, IconData icon, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B949E), size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF30363D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(subtitle, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }

  void _showIssueCreationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _IssueCreationSheet(),
    );
  }

  String _statusLabel(MemberStatus status) {
    switch (status) {
      case MemberStatus.present: return 'Present';
      case MemberStatus.onShoot: return 'On Shoot';
      case MemberStatus.onBreak: return 'Break';
      case MemberStatus.needsHelp: return 'Needs Help';
      case MemberStatus.missedCheckIn: return 'Missed Check-in';
      case MemberStatus.notArrived: return 'Not Arrived';
    }
  }
}

class _MemberCard extends StatelessWidget {
  final _MockMember member;
  const _MemberCard({required this.member});

  static Color _statusColor(MemberStatus s) {
    switch (s) {
      case MemberStatus.present: return const Color(0xFF10B981);
      case MemberStatus.onShoot: return const Color(0xFF3D5AFE);
      case MemberStatus.onBreak: return const Color(0xFFF59E0B);
      case MemberStatus.needsHelp: return const Color(0xFFEF4444);
      case MemberStatus.missedCheckIn: return const Color(0xFFFF6B35);
      case MemberStatus.notArrived: return const Color(0xFF6B7280);
    }
  }

  static String _statusLabel(MemberStatus s) {
    switch (s) {
      case MemberStatus.present: return 'Present';
      case MemberStatus.onShoot: return 'On Shoot';
      case MemberStatus.onBreak: return 'Break';
      case MemberStatus.needsHelp: return 'Needs Help!';
      case MemberStatus.missedCheckIn: return 'Missed Check-in';
      case MemberStatus.notArrived: return 'Not Arrived';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(member.status);
    final initials = member.name.split(' ').take(2).map((w) => w[0]).join();

    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF161B22), width: 2)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            member.name.split(' ').first,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(member.squad, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statusLabel(member.status), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (member.location != null) ...[
            const SizedBox(height: 6),
            Text(member.location!, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _IssueCreationSheet extends StatefulWidget {
  const _IssueCreationSheet();

  @override
  State<_IssueCreationSheet> createState() => _IssueCreationSheetState();
}

class _IssueCreationSheetState extends State<_IssueCreationSheet> {
  String _selectedCategory = 'Gear';
  final _descCtrl = TextEditingController();
  final _categories = ['Gear', 'Crew Shortage', 'Access', 'Safety', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report Issue', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Auto-tagging your location...', style: TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: _categories.map((c) {
              final isSelected = _selectedCategory == c;
              return ChoiceChip(
                label: Text(c),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = c),
                selectedColor: const Color(0xFF3D5AFE),
                backgroundColor: const Color(0xFF30363D),
                labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF8B949E), fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe the issue...',
              hintStyle: const TextStyle(color: Color(0xFF8B949E)),
              filled: true,
              fillColor: const Color(0xFF0D1117),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF30363D))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF30363D))),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Submit Issue', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
