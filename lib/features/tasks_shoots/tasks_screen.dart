import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gf_network_pill.dart';

class TasksScreen extends StatefulWidget {
  final String eventId;
  const TasksScreen({super.key, required this.eventId});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedDay = 1;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'My Shoots', 'Hall A', 'Building B', 'Outdoor'];

  final List<_ShootSlot> _shoots = [
    _ShootSlot(
      id: 'shoot-101',
      title: 'Inaugural Keynote & Lighting',
      building: 'Building A',
      room: 'Main Auditorium (Hall 1)',
      startTime: '10:00 AM',
      endTime: '11:30 AM',
      day: 1,
      priority: 'High',
      status: 'In Progress',
      crew: ['Vinik Shah (Lead)', 'Arjun Mehta (Cam A)', 'Sara Ali (Audio)'],
      gear: ['Sony FX3 Kit #1', 'Sennheiser Wireless Mic', 'Manfrotto Tripod'],
      travelTimeMinutes: 0,
      notes: 'Capture entrance crowd, dignitary stage welcome, wide-angle audience.',
      isMine: true,
    ),
    _ShootSlot(
      id: 'shoot-102',
      title: 'Robotics Showcase & Arena Trials',
      building: 'Tech Block',
      room: 'Ground Floor Arena',
      startTime: '11:45 AM',
      endTime: '01:15 PM',
      day: 1,
      priority: 'High',
      status: 'Upcoming',
      crew: ['Priya Sharma (Lead)', 'Dhruv Patel (Drone Pilot)'],
      gear: ['DJI Mini 3 Pro Kit', 'Sony A7IV', '2x V-Mount Battery'],
      travelTimeMinutes: 12,
      notes: 'Fast autofocus required. Keep drone under 15m safety ceiling.',
      isMine: true,
    ),
    _ShootSlot(
      id: 'shoot-103',
      title: 'Hackathon Round 1 Judging',
      building: 'Library Block',
      room: 'Seminar Hall 3',
      startTime: '02:00 PM',
      endTime: '03:30 PM',
      day: 1,
      priority: 'Medium',
      status: 'Upcoming',
      crew: ['Chen Wei (Cam)', 'Ananya Patel (B-roll)'],
      gear: ['Sony A7SIII', 'Gimbal Ronin SC'],
      travelTimeMinutes: 8,
      notes: 'Focus on student team expressions and project displays.',
      isMine: false,
    ),
    _ShootSlot(
      id: 'shoot-104',
      title: 'Cultural Night Dance Rehearsal',
      building: 'Open Amphitheatre',
      room: 'Central Stage',
      startTime: '04:00 PM',
      endTime: '05:30 PM',
      day: 1,
      priority: 'Medium',
      status: 'Upcoming',
      crew: ['Vinik Shah', 'Deepak Singh', 'Ravi Kumar'],
      gear: ['Sony FX3 Kit #2', 'Boom Mic Kit', 'LED Panel Pair'],
      travelTimeMinutes: 15,
      notes: 'Low-light shooting after sunset; check battery charge beforehand.',
      isMine: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _shoots.where((s) {
      if (s.day != _selectedDay) return false;
      if (_selectedFilter == 'My Shoots') return s.isMine;
      if (_selectedFilter == 'Hall A') return s.room.contains('Hall 1');
      if (_selectedFilter == 'Building B') return s.building.contains('Tech');
      if (_selectedFilter == 'Outdoor') return s.building.contains('Amphitheatre');
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shoot Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text('Travel-Aware & Solver Optimized', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: GFNetworkPill(compact: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Day selector tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                _DayTab(day: 1, label: 'Day 1 (Nov 22)', isSelected: _selectedDay == 1, onSelect: () => setState(() => _selectedDay = 1)),
                const SizedBox(width: 8),
                _DayTab(day: 2, label: 'Day 2 (Nov 23)', isSelected: _selectedDay == 2, onSelect: () => setState(() => _selectedDay = 2)),
                const SizedBox(width: 8),
                _DayTab(day: 3, label: 'Day 3 (Nov 24)', isSelected: _selectedDay == 3, onSelect: () => setState(() => _selectedDay = 3)),
              ],
            ),
          ),

          // Horizontal filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _filters.map((f) {
                final isSel = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.primary : null,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Solver info note
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(0.18)),
            ),
            child: const Row(
              children: [
                Icon(Icons.route_outlined, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Campus travel matrix enforced. Back-to-back shoots include 8-15 min transition.',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),

          // List of shoots
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No shoots scheduled for this filter.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _ShootCardWidget(
                      shoot: filtered[i],
                      onTap: () => _showShootDetail(context, filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showShootDetail(BuildContext context, _ShootSlot shoot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ShootDetailSheet(shoot: shoot),
    );
  }
}

class _DayTab extends StatelessWidget {
  final int day;
  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  const _DayTab({
    required this.day,
    required this.label,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShootCardWidget extends StatelessWidget {
  final _ShootSlot shoot;
  final VoidCallback onTap;

  const _ShootCardWidget({required this.shoot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInProgress = shoot.status == 'In Progress';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isInProgress ? AppColors.primary : AppColors.border,
          width: isInProgress ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInProgress ? AppColors.primary.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shoot.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isInProgress ? AppColors.primary : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (shoot.priority == 'High')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'High Priority',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.danger),
                      ),
                    ),
                  const Spacer(),
                  if (shoot.travelTimeMinutes > 0)
                    Row(
                      children: [
                        const Icon(Icons.directions_walk_rounded, size: 14, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text(
                          '${shoot.travelTimeMinutes}m walk',
                          style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                shoot.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${shoot.startTime} – ${shoot.endTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 14),
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${shoot.building} • ${shoot.room}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${shoot.crew.length} Crew', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 14),
                  const Icon(Icons.camera_alt_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${shoot.gear.length} Gear Items', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShootDetailSheet extends StatelessWidget {
  final _ShootSlot shoot;
  const _ShootDetailSheet({required this.shoot});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shoot.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${shoot.building} • ${shoot.room}',
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('Time: ${shoot.startTime} – ${shoot.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 24),
              const Text('Assigned Crew', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...shoot.crew.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin_circle_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(c, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              const Text('Required Gear & Kits', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...shoot.gear.map((g) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(g, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              const Text('Shot Instructions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(shoot.notes, style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scan Ingest QR'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.check, size: 18, color: Colors.white),
                      label: const Text('Check-In Venue', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Checked into shoot venue.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShootSlot {
  final String id, title, building, room, startTime, endTime, priority, status, notes;
  final int day, travelTimeMinutes;
  final List<String> crew, gear;
  final bool isMine;

  _ShootSlot({
    required this.id,
    required this.title,
    required this.building,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.priority,
    required this.status,
    required this.crew,
    required this.gear,
    required this.travelTimeMinutes,
    required this.notes,
    required this.isMine,
  });
}
