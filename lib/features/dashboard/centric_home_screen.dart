import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/state/ground_flow_realtime_store.dart';

class CentricHomeScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  final int initialTabIndex;
  const CentricHomeScreen({super.key, required this.onSignOut, this.initialTabIndex = 0});

  @override
  State<CentricHomeScreen> createState() => _CentricHomeScreenState();
}

class _CentricHomeScreenState extends State<CentricHomeScreen> {
  int _currentTabIndex = 0;
  Timer? _qrTicker;
  int _rotatingQrSeconds = 48;
  String _qrToken = 'GF-BCS26-ROUND2-ALPHA-8921';
  final TextEditingController _chatInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _startQrTicker();
  }

  void _startQrTicker() {
    _qrTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_rotatingQrSeconds > 1) {
          _rotatingQrSeconds--;
        } else {
          _rotatingQrSeconds = 60;
          _qrToken = 'GF-BCS26-ROUND2-ALPHA-${DateTime.now().millisecondsSinceEpoch % 10000}';
        }
      });
    });
  }

  @override
  void dispose() {
    _qrTicker?.cancel();
    _chatInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = GroundFlowRealtimeStore();

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final role = store.currentRole;
        final dockItems = _getDockItemsForRole(role);

        // Ensure tab index is valid for current role
        if (_currentTabIndex >= dockItems.length) {
          _currentTabIndex = 0;
        }

        return Scaffold(
          backgroundColor: GlassTheme.black,
          body: Stack(
            children: [
              // Top Centric Bar (No sidebars!)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CentricTopBar(
                  title: '${store.currentEventCode} • ${store.currentDepartment}',
                  subtitle: 'Live Ground Protocol',
                  role: role.shortLabel,
                  photoUrl: store.photoUrl,
                  avatarText: store.userAvatar,
                  onRoleTap: () => _showRoleSwitchDialog(context, store),
                  onProfileTap: () => _showProfileDialog(context, store),
                ),
              ),

              // Main Body Content
              Positioned.fill(
                top: 96,
                bottom: 80,
                child: _buildRoleContent(role, _currentTabIndex, store),
              ),

              // Floating Apple Glass Dock at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: FloatingGlassDock(
                  currentIndex: _currentTabIndex,
                  items: dockItems,
                  onSelect: (idx) => setState(() => _currentTabIndex = idx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<DockItem> _getDockItemsForRole(AppRole role) {
    switch (role) {
      case AppRole.departmentHead:
        return const [
          DockItem(icon: Icons.radar_outlined, selectedIcon: Icons.radar_rounded, label: 'Command'),
          DockItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month_rounded, label: 'Shoots'),
          DockItem(icon: Icons.camera_alt_outlined, selectedIcon: Icons.camera_alt_rounded, label: 'Gear'),
          DockItem(icon: Icons.dns_outlined, selectedIcon: Icons.dns_rounded, label: 'Pipeline'),
          DockItem(icon: Icons.insights_outlined, selectedIcon: Icons.insights_rounded, label: 'Export'),
        ];
      case AppRole.teamLead:
        return const [
          DockItem(icon: Icons.groups_outlined, selectedIcon: Icons.groups_rounded, label: 'Squad'),
          DockItem(icon: Icons.qr_code_scanner_outlined, selectedIcon: Icons.qr_code_2_rounded, label: 'Verify QR'),
          DockItem(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today_rounded, label: 'Shoots'),
          DockItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'Gear'),
          DockItem(icon: Icons.report_problem_outlined, selectedIcon: Icons.report_problem_rounded, label: 'Issues'),
        ];
      case AppRole.volunteer:
        return const [
          DockItem(icon: Icons.route_outlined, selectedIcon: Icons.route_rounded, label: 'My Day'),
          DockItem(icon: Icons.how_to_reg_outlined, selectedIcon: Icons.how_to_reg_rounded, label: 'Check-In'),
          DockItem(icon: Icons.camera_enhance_outlined, selectedIcon: Icons.camera_enhance_rounded, label: 'My Kit'),
          DockItem(icon: Icons.sd_card_outlined, selectedIcon: Icons.sd_card_rounded, label: 'Handoff'),
          DockItem(icon: Icons.chat_bubble_outline_rounded, selectedIcon: Icons.chat_bubble_rounded, label: 'Chat & SOS'),
        ];
    }
  }

  Widget _buildRoleContent(AppRole role, int tabIndex, GroundFlowRealtimeStore store) {
    switch (role) {
      case AppRole.departmentHead:
        switch (tabIndex) {
          case 0: return _buildHeadCommandView(store);
          case 1: return _buildShootsView(store);
          case 2: return _buildGearView(store);
          case 3: return _buildPipelineView(store);
          case 4: return _buildAnalyticsView(store);
          default: return _buildHeadCommandView(store);
        }
      case AppRole.teamLead:
        switch (tabIndex) {
          case 0: return _buildLeadSquadView(store);
          case 1: return _buildLeadRotatingQrView(store);
          case 2: return _buildShootsView(store);
          case 3: return _buildGearView(store);
          case 4: return _buildIssuesFeedView(store);
          default: return _buildLeadSquadView(store);
        }
      case AppRole.volunteer:
        switch (tabIndex) {
          case 0: return _buildVolunteerMyDayView(store);
          case 1: return _buildVolunteerCheckInView(store);
          case 2: return _buildVolunteerKitView(store);
          case 3: return _buildVolunteerHandoffView(store);
          case 4: return _buildVolunteerChatView(store);
          default: return _buildVolunteerMyDayView(store);
        }
    }
  }

  // =========================================================================
  // 1. DEPARTMENT HEAD VIEWS
  // =========================================================================

  Widget _buildHeadCommandView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Titanium Metric Hero Cards
        Row(
          children: [
            _statMetricCard('${store.presentVolunteersCount} / ${store.totalVolunteersCount}', 'Members Present', GlassTheme.accentEmerald, Icons.people_alt_rounded),
            const SizedBox(width: 10),
            _statMetricCard('${store.activeShootsCount} Active', 'Shoots Live', GlassTheme.accentAmber, Icons.videocam_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statMetricCard('${store.verifiedBackupsCount} Safe', '2x NAS Backups', GlassTheme.accentSky, Icons.shield_rounded),
            const SizedBox(width: 10),
            _statMetricCard('${store.activeIssuesCount} Urgent', 'Tickets (<5m Esc.)', GlassTheme.accentRose, Icons.warning_amber_rounded),
          ],
        ),
        const SizedBox(height: 20),

        // Active Shoots Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Live Shoots Across Campus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            GlassPill(label: 'OR-Tools Active', icon: Icons.bolt, color: GlassTheme.accentEmerald),
          ],
        ),
        const SizedBox(height: 12),

        ...store.shoots.map((shoot) => GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: shoot['status'] == 'In Progress' ? GlassTheme.accentEmerald.withValues(alpha: 0.15) : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: shoot['status'] == 'In Progress' ? GlassTheme.accentEmerald.withValues(alpha: 0.3) : Colors.white12,
                      ),
                    ),
                    child: Text(
                      shoot['status'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: shoot['status'] == 'In Progress' ? GlassTheme.accentEmerald : Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shoot['id'],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassTheme.accentSky),
                  ),
                  const Spacer(),
                  if (shoot['travelMinutes'] > 0)
                    Text(
                      '${shoot['travelMinutes']}m walking buffer',
                      style: const TextStyle(fontSize: 11, color: GlassTheme.accentAmber, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(shoot['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: GlassTheme.mutedSilver),
                  children: [
                    const TextSpan(text: '📍 '),
                    TextSpan(text: '${shoot['venue']}', style: const TextStyle(color: Colors.white70)),
                    const TextSpan(text: ' • Time: '),
                    TextSpan(text: '${shoot['time']}', style: const TextStyle(color: GlassTheme.accentSky, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 14, color: GlassTheme.accentCyan),
                  const SizedBox(width: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11.5, color: GlassTheme.silver),
                      children: [
                        const TextSpan(text: 'Lead: '),
                        TextSpan(text: '${shoot['lead']}', style: const TextStyle(color: GlassTheme.accentCyan, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.camera_alt_outlined, size: 14, color: GlassTheme.accentViolet),
                  const SizedBox(width: 4),
                  Text(shoot['gear'], style: const TextStyle(fontSize: 11.5, color: GlassTheme.accentViolet, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        )),

        const SizedBox(height: 20),
        // Live Issues Feed
        const Text('Priority Event Issues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 10),

        ...store.issues.map((issue) => GlassContainer(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: issue['priority'] == 'High' ? GlassTheme.accentRose : GlassTheme.accentAmber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue['title'], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: GlassTheme.mutedSilver),
                        children: [
                          TextSpan(text: '${issue['squad']}', style: const TextStyle(color: GlassTheme.accentSky, fontWeight: FontWeight.w600)),
                          const TextSpan(text: ' • '),
                          TextSpan(
                            text: '${issue['status']}',
                            style: TextStyle(
                              color: issue['status'].toString().contains('Escalated') ? GlassTheme.accentRose : GlassTheme.accentAmber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => store.resolveIssue(issue['id']),
                child: const Text('Resolve', style: TextStyle(fontSize: 12, color: GlassTheme.accentEmerald, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _statMetricCard(String value, String label, Color accent, IconData icon) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: accent),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accent)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: GlassTheme.mutedSilver, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. TEAM LEAD VIEWS (Squad Roster & Dynamic Rotating QR Generator)
  // =========================================================================

  Widget _buildLeadSquadView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Media Squad Alpha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('10 Members Assigned • Building A Cluster', style: TextStyle(fontSize: 12, color: GlassTheme.mutedSilver)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Squad Members Live Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 10),

        ...store.squadMembers.map((member) => GlassContainer(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white12,
                child: Text(member['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11.5, color: GlassTheme.mutedSilver),
                        children: [
                          TextSpan(text: '${member['role']}', style: const TextStyle(color: GlassTheme.accentSky, fontWeight: FontWeight.w600)),
                          const TextSpan(text: ' • '),
                          TextSpan(text: '${member['location']}', style: const TextStyle(color: GlassTheme.accentAmber)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GlassPill(
                label: member['status'],
                color: member['status'] == 'On Shoot'
                    ? GlassTheme.appleBlue
                    : (member['status'] == 'Needs Help' ? GlassTheme.appleRed : GlassTheme.appleGreen),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLeadRotatingQrView(GroundFlowRealtimeStore store) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          const Text(
            'Anti-Cheating Verification Terminal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Hold this terminal screen for volunteers to scan. Token rotates automatically every 60s.',
            style: TextStyle(fontSize: 12, color: GlassTheme.mutedSilver),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Central Glossy QR Code Card
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 32,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _qrToken,
                    version: QrVersions.auto,
                    size: 210.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Token cycles in $_rotatingQrSeconds seconds',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GlassTheme.appleOrange),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _rotatingQrSeconds / 60.0,
                    backgroundColor: Colors.white12,
                    color: GlassTheme.appleOrange,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Payload: $_qrToken',
                  style: const TextStyle(fontSize: 10, color: GlassTheme.mutedSilver, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. VOLUNTEER VIEWS (My Day, Check-In, Kit Custody, Handoff)
  // =========================================================================

  Widget _buildVolunteerMyDayView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Mission Hero Card
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CURRENT ASSIGNMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: GlassTheme.appleGreen, letterSpacing: 1.0)),
                  GlassPill(label: 'Report in 15m', color: GlassTheme.appleGreen),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Inaugural Keynote & Lighting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Auditorium Hall A (Main Stage Riser)', style: TextStyle(fontSize: 13, color: GlassTheme.silver)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_walk_rounded, color: GlassTheme.appleOrange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '12 min walk from Building B Gear Locker. Head through central colonnade corridor.',
                        style: TextStyle(fontSize: 11.5, color: GlassTheme.silver),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Today\'s Volunteer Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 12),

        ...store.shoots.map((shoot) => GlassContainer(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
                child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shoot['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('${shoot['time']} • ${shoot['venue']}', style: const TextStyle(fontSize: 11.5, color: GlassTheme.mutedSilver)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildVolunteerCheckInView(GroundFlowRealtimeStore store) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Icon(Icons.gps_fixed_rounded, size: 48, color: GlassTheme.appleGreen),
                const SizedBox(height: 12),
                const Text('Auditorium Geofence: LOCKED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('GPS accuracy within 8 meters. Round 2 response window active.', style: TextStyle(fontSize: 12, color: GlassTheme.mutedSilver)),
                const SizedBox(height: 20),
                MetallicButton(
                  label: 'I\'m Here · Confirm Attendance',
                  icon: Icons.fingerprint_rounded,
                  onPressed: () {
                    store.markAttendanceRound(2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Verified! Attendance recorded in campus ledger.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Today\'s Timed Rounds Ledger', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 10),

          ...store.attendanceRounds.map((r) => GlassContainer(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  r['status'] == 'Verified' ? Icons.check_circle_rounded : Icons.access_time_rounded,
                  color: r['status'] == 'Verified' ? GlassTheme.appleGreen : GlassTheme.appleOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Round ${r['round']} (${r['time']})', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(r['status'] == 'Verified' ? 'Verified via ${r['method']}' : 'Awaiting physical round', style: const TextStyle(fontSize: 11, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
                GlassPill(
                  label: r['status'],
                  color: r['status'] == 'Verified' ? GlassTheme.appleGreen : GlassTheme.appleOrange,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildVolunteerKitView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('IN MY PHYSICAL CUSTODY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: GlassTheme.accentSky, letterSpacing: 1.0)),
                  GlassPill(label: 'CINE-FX3-01', color: GlassTheme.white),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Sony FX3 Cinema Bundle #1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, color: GlassTheme.mutedSilver),
                  children: [
                    TextSpan(text: 'Return to Gear Room B-104 before '),
                    TextSpan(text: '01:30 PM', style: TextStyle(color: GlassTheme.accentAmber, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Divider(height: 24, color: Colors.white12),
              const Text('Verified Kit Components:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GlassTheme.silver)),
              const SizedBox(height: 8),
              _itemBullet('Sony FX3 Body (SN: #8821)'),
              _itemBullet('Sony 24-70mm f/2.8 GM Lens'),
              _itemBullet('2x NP-FZ100 Lithium Batteries (100% Charged)'),
              _itemBullet('SanDisk Extreme Pro 128GB V90 SD Card'),
              _itemBullet('Manfrotto Carbon Tripod'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: GlassTheme.accentEmerald),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: GlassTheme.silver),
                children: [
                  TextSpan(text: text.split('(').first),
                  if (text.contains('('))
                    TextSpan(
                      text: '(${text.split('(').last}',
                      style: const TextStyle(color: GlassTheme.accentEmerald, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerHandoffView(GroundFlowRealtimeStore store) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text('SD Card Dump Handoff', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Scan the QR code on the dump station card reader or runner badge to log physical handoff.', style: TextStyle(fontSize: 12, color: GlassTheme.mutedSilver), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                MetallicButton(
                  label: 'Scan Ingest Tag',
                  icon: Icons.camera_alt_outlined,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Ingest handoff token verified for Card SD-128-01.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Dump Stations on Campus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                Icon(Icons.storage_rounded, color: GlassTheme.appleGreen),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dump Room B-204 (Open)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Operator: Meera Reddy • High Speed Readers Active', style: TextStyle(fontSize: 11.5, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerChatView(GroundFlowRealtimeStore store) {
    return Column(
      children: [
        // Emergency SOS Top Trigger
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: MetallicButton(
            label: 'Emergency SOS Broadcast',
            icon: Icons.sos_rounded,
            onPressed: () {
              store.addIssue(
                title: 'EMERGENCY SOS: Volunteer requested immediate assistance at current GPS position',
                priority: 'High',
                squad: 'Squad Alpha',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🚨 SOS Alert dispatched to Head & Security.'), backgroundColor: Colors.red),
              );
            },
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: store.chatMessages.map((msg) => _chatBubble(
              msg['sender'] as String? ?? 'User',
              msg['text'] as String? ?? '',
              msg['time'] as String? ?? 'Just Now',
              msg['isMe'] as bool? ?? false,
            )).toList(),
          ),
        ),

        // Live Chat Message Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF0C0C0E),
            border: Border(top: BorderSide(color: GlassTheme.border, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: TextField(
                    controller: _chatInputCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Broadcast dispatch message...',
                      hintStyle: TextStyle(color: Color(0xFF52525B), fontSize: 12.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        store.sendChatMessage(val);
                        _chatInputCtrl.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: GlassTheme.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                onPressed: () {
                  final text = _chatInputCtrl.text.trim();
                  if (text.isNotEmpty) {
                    store.sendChatMessage(text);
                    _chatInputCtrl.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chatBubble(String sender, String text, String time, bool isMe) {
    Color senderColor;
    if (isMe) {
      senderColor = GlassTheme.accentEmerald;
    } else if (sender.contains('Head')) {
      senderColor = GlassTheme.accentRose;
    } else if (sender.contains('Lead')) {
      senderColor = GlassTheme.accentAmber;
    } else {
      senderColor = GlassTheme.accentSky;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          width: 280,
          borderRadius: 20,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(sender, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: senderColor)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 13, color: Colors.white)),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontSize: 10, color: GlassTheme.mutedSilver)),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. SHARED VIEWS (Shoots, Gear, Pipeline, Analytics)
  // =========================================================================

  Widget _buildShootsView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: store.shoots.map((shoot) => GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(shoot['id'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: GlassTheme.accentSky)),
                GlassPill(label: shoot['status'], color: shoot['status'] == 'In Progress' ? GlassTheme.accentEmerald : Colors.white70),
              ],
            ),
            const SizedBox(height: 8),
            Text(shoot['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: GlassTheme.mutedSilver),
                children: [
                  const TextSpan(text: '📍 '),
                  TextSpan(text: '${shoot['venue']}', style: const TextStyle(color: Colors.white70)),
                  const TextSpan(text: ' • Time: '),
                  TextSpan(text: '${shoot['time']}', style: const TextStyle(color: GlassTheme.accentSky, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Divider(height: 20, color: Colors.white12),
            Text('Instructions: ${shoot['notes']}', style: const TextStyle(fontSize: 12, color: GlassTheme.silver)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildGearView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: store.gearKits.map((kit) => GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(kit['code'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: GlassTheme.accentSky)),
                GlassPill(
                  label: kit['status'],
                  color: kit['status'] == 'Available'
                      ? GlassTheme.accentEmerald
                      : (kit['status'] == 'Overdue' ? GlassTheme.accentRose : GlassTheme.accentCyan),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(kit['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: GlassTheme.mutedSilver),
                children: [
                  const TextSpan(text: 'Current Holder: '),
                  TextSpan(text: '${kit['holder']}', style: const TextStyle(color: GlassTheme.accentCyan, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPipelineView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: store.pipelineItems.map((item) => GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Card: ${item['cardId']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: GlassTheme.accentSky)),
                GlassPill(
                  label: item['copies'] >= 2 ? 'SAFE (2x Copy)' : '1 COPY ONLY',
                  color: item['copies'] >= 2 ? GlassTheme.accentEmerald : GlassTheme.accentAmber,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item['shoot'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: GlassTheme.mutedSilver),
                children: [
                  const TextSpan(text: 'Stage: '),
                  TextSpan(text: '${item['stageName']}', style: const TextStyle(color: GlassTheme.accentAmber, fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' • Files: '),
                  TextSpan(text: '${item['fileCount']}', style: const TextStyle(color: GlassTheme.accentEmerald, fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' ('),
                  TextSpan(text: '${item['sizeGb']} GB', style: const TextStyle(color: GlassTheme.accentCyan, fontWeight: FontWeight.w600)),
                  const TextSpan(text: ')'),
                ],
              ),
            ),
            if (item['nasPath'] != null) ...[
              const SizedBox(height: 8),
              Text('NAS Archive: ${item['nasPath']}', style: const TextStyle(fontSize: 10.5, color: GlassTheme.accentSky, fontFamily: 'monospace')),
            ],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAnalyticsView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export Event Report', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Generate complete audit log of attendance rounds, shoot completions, and gear custody.', style: TextStyle(fontSize: 12, color: GlassTheme.mutedSilver)),
              const SizedBox(height: 20),
              MetallicButton(
                label: 'Export to Microsoft Excel (.xlsx)',
                icon: Icons.table_chart_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Exported BCS-2026-Audit-Ledger.xlsx')),
                  );
                },
              ),
              const SizedBox(height: 10),
              MetallicButton(
                label: 'Sync to Google Sheets',
                icon: Icons.cloud_upload_rounded,
                isSecondary: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Synchronized to Google Sheets cloud ledger.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesFeedView(GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: store.issues.map((issue) => GlassContainer(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(issue['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('${issue['squad']} • ${issue['status']}', style: const TextStyle(fontSize: 11.5, color: GlassTheme.mutedSilver)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: () => store.resolveIssue(issue['id']),
              child: const Text('Resolve', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // Dialogs
  void _showRoleSwitchDialog(BuildContext context, GroundFlowRealtimeStore store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF14141E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white24, width: 1.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Switch Operational Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Changes your dashboard view and security permissions instantly.', style: TextStyle(fontSize: 12, color: GlassTheme.mutedSilver)),
              const SizedBox(height: 16),
              ...AppRole.values.map((r) => ListTile(
                leading: Icon(
                  r == store.currentRole ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: r == store.currentRole ? Colors.white : Colors.grey,
                ),
                title: Text(r.title, style: TextStyle(color: Colors.white, fontWeight: r == store.currentRole ? FontWeight.w800 : FontWeight.w500)),
                onTap: () {
                  store.switchRole(r);
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, GroundFlowRealtimeStore store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF14141E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white24, width: 1.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    backgroundImage: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                        ? NetworkImage(store.photoUrl!)
                        : null,
                    child: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                        ? null
                        : Text(store.userAvatar, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.userName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(store.userEmail, style: const TextStyle(fontSize: 12, color: GlassTheme.mutedSilver)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.white12),
              Text('Active Event Code: ${store.currentEventCode}', style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GlassTheme.statusRed,
                  side: const BorderSide(color: GlassTheme.statusRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text('Delete Event (${store.currentEventCode})', style: const TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  final codeToDelete = store.currentEventCode;
                  showDialog(
                    context: context,
                    builder: (delCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF141418),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: GlassTheme.border),
                      ),
                      title: const Text('Delete Active Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      content: Text(
                        'Are you sure you want to permanently delete event "$codeToDelete"? This will remove it from the operational ledger and Firestore.',
                        style: const TextStyle(color: GlassTheme.mutedSilver, fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(delCtx),
                          child: const Text('Cancel', style: TextStyle(color: GlassTheme.chrome)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: GlassTheme.statusRed),
                          onPressed: () async {
                            Navigator.pop(delCtx);
                            Navigator.pop(ctx);
                            final deletedFromCloud = await store.removeEvent(codeToDelete);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    deletedFromCloud
                                        ? '✓ Event $codeToDelete permanently deleted from Cloud Firestore & local storage.'
                                        : '✓ Event $codeToDelete removed from local storage.',
                                  ),
                                  backgroundColor: GlassTheme.statusRed,
                                ),
                              );
                            }
                          },
                          child: const Text('Delete Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              MetallicButton(
                label: 'Sign Out (Switch Account)',
                isSecondary: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  store.signOut();
                  widget.onSignOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
