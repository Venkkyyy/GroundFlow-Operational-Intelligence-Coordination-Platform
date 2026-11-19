import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gf_network_pill.dart';
import '../../core/network/data_usage_manager.dart';

class EventDashboardScreen extends StatefulWidget {
  final String eventId;
  const EventDashboardScreen({super.key, required this.eventId});

  @override
  State<EventDashboardScreen> createState() => _EventDashboardScreenState();
}

class _EventDashboardScreenState extends State<EventDashboardScreen> {
  String _currentDepartment = 'Media';

  final List<String> _departments = [
    'Media',
    'Registration',
    'Logistics',
    'Security',
    'Hospitality',
    'Tech & Stage',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BCS 2026', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
            Text('Department: $_currentDepartment', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch Department',
            onPressed: () => _showDeptSwitcher(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: GFNetworkPill(compact: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Head control room hero card
            GestureDetector(
              onTap: () => context.push('/events/${widget.eventId}/control-room'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D5AFE), Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.radar_rounded, size: 14, color: Colors.greenAccent),
                              SizedBox(width: 6),
                              Text('LIVE RADAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Live Control Room',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Campus map view, who is where, travel-aware squad roster & active alerts.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _heroMetric('68/78', 'Present'),
                        const SizedBox(width: 16),
                        _heroMetric('4', 'Shoots'),
                        const SizedBox(width: 16),
                        _heroMetric('3', 'Issues'),
                        const SizedBox(width: 16),
                        _heroMetric('14', 'Safe Ingests'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Operational Modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _ModuleCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Shoot Schedule',
                  subtitle: 'Travel-aware slots',
                  color: const Color(0xFF3D5AFE),
                  onTap: () => context.push('/events/${widget.eventId}/tasks'),
                ),
                _ModuleCard(
                  icon: Icons.how_to_reg_rounded,
                  title: 'Attendance',
                  subtitle: 'Geofence & Rounds',
                  color: const Color(0xFF00C853),
                  badge: 'Round 2',
                  onTap: () => context.push('/events/${widget.eventId}/attendance'),
                ),
                _ModuleCard(
                  icon: Icons.camera_enhance_rounded,
                  title: 'Gear & Custody',
                  subtitle: 'Kits & QR scans',
                  color: const Color(0xFFFFB300),
                  onTap: () => context.push('/events/${widget.eventId}/gear'),
                ),
                _ModuleCard(
                  icon: Icons.dns_rounded,
                  title: 'Data Pipeline',
                  subtitle: 'Dump stations & NAS',
                  color: const Color(0xFF0288D1),
                  badge: 'Safe (2x)',
                  onTap: () => context.push('/events/${widget.eventId}/pipeline'),
                ),
                _ModuleCard(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Channels & SOS',
                  subtitle: '#media-all & DMs',
                  color: const Color(0xFF8E24AA),
                  onTap: () => context.push('/events/${widget.eventId}/chat'),
                ),
                _ModuleCard(
                  icon: Icons.report_problem_rounded,
                  title: 'Issues & Tickets',
                  subtitle: '5m auto escalation',
                  color: const Color(0xFFD32F2F),
                  badge: '3 Open',
                  onTap: () => context.push('/events/${widget.eventId}/issues'),
                ),
                _ModuleCard(
                  icon: Icons.insights_rounded,
                  title: 'Analytics & Export',
                  subtitle: 'Excel, PDF & Sheets',
                  color: const Color(0xFF00897B),
                  onTap: () => context.push('/events/${widget.eventId}/reports'),
                ),
                _ModuleCard(
                  icon: Icons.offline_pin_rounded,
                  title: 'Low Data Mode',
                  subtitle: 'Campus Bandwidth',
                  color: const Color(0xFF455A64),
                  badge: 'Active',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Low Data Mode active for campus network.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMetric(String val, String lbl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        Text(lbl, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  void _showDeptSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Switch Department View', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Generic GroundFlow primitives configured per team', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 14),
              ..._departments.map((dept) => ListTile(
                    leading: Icon(
                      dept == _currentDepartment ? Icons.check_circle_rounded : Icons.apartment_rounded,
                      color: dept == _currentDepartment ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(dept, style: TextStyle(fontWeight: dept == _currentDepartment ? FontWeight.w700 : FontWeight.w500)),
                    onTap: () {
                      setState(() => _currentDepartment = dept);
                      Navigator.pop(ctx);
                      DataUsageManager().trackNetworkTransfer(upload: 90);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(badge!, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
