import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/state/ground_flow_realtime_store.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/universal_event_model.dart';
import '../events/universal_event_wizard_screen.dart';
import '../workspace/event_operations_workspace_screen.dart';

class GlobalBrandHomeScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const GlobalBrandHomeScreen({super.key, required this.onSignOut});

  @override
  State<GlobalBrandHomeScreen> createState() => _GlobalBrandHomeScreenState();
}

class _GlobalBrandHomeScreenState extends State<GlobalBrandHomeScreen> {
  // Navigation State: 0 = Home, 1 = My Events, 2 = Discover, 3 = Activity, 4 = Profile
  int _currentBottomNavIndex = 0;

  // Search & Filter State
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Dialog Controllers
  final TextEditingController _joinCodeCtrl = TextEditingController();
  final TextEditingController _joinPasswordCtrl = TextEditingController();

  // My Events sub-filter: 0 = All, 1 = Created, 2 = Participating
  int _eventsSubFilter = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _joinCodeCtrl.dispose();
    _joinPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = GroundFlowRealtimeStore();

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final hasActiveEvents = store.events.isNotEmpty;
        final userEmail = store.userEmail.toLowerCase().trim();

        final createdEvents = store.events.where((e) {
          final role = store.getUserRoleForEvent(e['code'] ?? '');
          if (role == EventRole.creator) return true;
          final owner = e['createdBy']?.toString().toLowerCase().trim() ?? '';
          return userEmail.isNotEmpty && owner == userEmail;
        }).toList();

        final participatingEvents = store.events.where((e) {
          final role = store.getUserRoleForEvent(e['code'] ?? '');
          if (role == EventRole.creator) return false;
          final owner = e['createdBy']?.toString().toLowerCase().trim() ?? '';
          if (userEmail.isNotEmpty && owner == userEmail) return false;
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: GlassTheme.black,
          appBar: _buildTopBar(context, store),
          body: RefreshIndicator(
            color: GlassTheme.white,
            backgroundColor: const Color(0xFF1B1B22),
            onRefresh: () async => await store.refreshEvents(),
            child: _buildCurrentTabBody(
              context,
              store,
              hasActiveEvents,
              createdEvents,
              participatingEvents,
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  // ===========================================================================
  // 1. TOP BAR — Logo, Search, Notifications, Profile
  // ===========================================================================
  PreferredSizeWidget _buildTopBar(
      BuildContext context, GroundFlowRealtimeStore store) {
    return AppBar(
      backgroundColor: GlassTheme.black,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GlassTheme.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.hub_rounded, color: Colors.black, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'GroundFlow',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: GlassTheme.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        // Search Action
        IconButton(
          tooltip: 'Search Events & Sessions',
          icon:
              const Icon(Icons.search_rounded, size: 21, color: Colors.white70),
          onPressed: () => _showSearchModal(context, store),
        ),

        // Notifications Action with Alert Badge
        IconButton(
          tooltip: 'Notifications & Broadcasts',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined,
                  size: 21, color: Colors.white70),
              if (store.announcements.isNotEmpty || store.chatMessages.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: GlassTheme.accentSky,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => _showNotificationsSheet(context, store),
        ),

        // Profile Avatar & Menu
        PopupMenuButton<String>(
          color: GlassTheme.cardBg,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF27272A),
            backgroundImage:
                (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                    ? NetworkImage(store.photoUrl!)
                    : null,
            child: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                ? null
                : Text(
                    store.userAvatar,
                    style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
          ),
          onSelected: (val) {
            if (val == 'signout') {
              store.signOut();
              widget.onSignOut();
            } else if (val == 'test_cloud') {
              _showCloudDiagnosticDialog(context);
            } else if (val == 'switch_role') {
              _showRoleSelectionDialog(context, store);
            } else if (val == 'profile_tab') {
              setState(() => _currentBottomNavIndex = 4);
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.userName,
                      style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(store.userEmail,
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: GlassTheme.mutedSilver)),
                  const SizedBox(height: 4),
                  Text(
                    store.hasAssignedRole
                        ? 'Role: ${store.displayRoleTitle}'
                        : 'Role: Not Assigned Yet',
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: store.hasAssignedRole
                            ? GlassTheme.accentSky
                            : GlassTheme.accentAmber),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'profile_tab',
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('View Full Profile',
                      style: GoogleFonts.roboto(
                          fontSize: 12.5, color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'switch_role',
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 16, color: GlassTheme.accentSky),
                  const SizedBox(width: 8),
                  Text('Change Operational Role',
                      style: GoogleFonts.roboto(
                          fontSize: 12.5, color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'test_cloud',
              child: Row(
                children: [
                  const Icon(Icons.cloud_sync_rounded,
                      size: 16, color: GlassTheme.accentEmerald),
                  const SizedBox(width: 8),
                  Text('Check Cloud Connection',
                      style: GoogleFonts.roboto(
                          fontSize: 12.5, color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded,
                      size: 16, color: GlassTheme.statusRed),
                  const SizedBox(width: 8),
                  Text('Sign Out',
                      style: GoogleFonts.roboto(
                          fontSize: 12.5, color: GlassTheme.statusRed)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ===========================================================================
  // 8. BOTTOM BAR — Home, My Events, Discover, Activity, Profile
  // ===========================================================================
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C10),
        border: Border(top: BorderSide(color: GlassTheme.border, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) => setState(() => _currentBottomNavIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: GlassTheme.mutedSilver,
          selectedLabelStyle:
              GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              GoogleFonts.roboto(fontSize: 10.5, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'My Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CURRENT TAB CONTENT ROUTER
  // ===========================================================================
  Widget _buildCurrentTabBody(
    BuildContext context,
    GroundFlowRealtimeStore store,
    bool hasActiveEvents,
    List<Map<String, dynamic>> createdEvents,
    List<Map<String, dynamic>> participatingEvents,
  ) {
    switch (_currentBottomNavIndex) {
      case 1:
        return _buildDedicatedMyEventsView(
            context, store, createdEvents, participatingEvents);
      case 2:
        return _buildDedicatedDiscoverView(context, store);
      case 3:
        return _buildDedicatedActivityView(context, store);
      case 4:
        return _buildDedicatedProfileView(context, store);
      case 0:
      default:
        return _buildFullHomeDashboard(
            context, store, hasActiveEvents, createdEvents, participatingEvents);
    }
  }

  // ===========================================================================
  // COMPLETE HOME DASHBOARD (Exact 8 Requirements Flow)
  // ===========================================================================
  Widget _buildFullHomeDashboard(
    BuildContext context,
    GroundFlowRealtimeStore store,
    bool hasActiveEvents,
    List<Map<String, dynamic>> createdEvents,
    List<Map<String, dynamic>> participatingEvents,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. Greeting — Personalised welcome
          _buildPersonalizedGreeting(context, store),
          const SizedBox(height: 18),

          // 3. Quick actions — Dynamically generated from permissions
          _buildDynamicQuickActions(context, store),
          const SizedBox(height: 20),

          // 4. Needs your attention — Pending actions and alerts
          _buildNeedsAttentionSection(store),
          const SizedBox(height: 22),

          // 5. My Events — Created and participating events
          _buildMyEventsSection(
              context, store, hasActiveEvents, createdEvents, participatingEvents),
          const SizedBox(height: 22),

          // 6. Upcoming schedule — Only relevant activities
          _buildUpcomingScheduleSection(store),
          const SizedBox(height: 22),

          // 7. Discover events — If enabled
          _buildDiscoverEventsSection(store),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. GREETING — Personalised Welcome
  // ===========================================================================
  Widget _buildPersonalizedGreeting(
      BuildContext context, GroundFlowRealtimeStore store) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF222228),
                backgroundImage:
                    (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                        ? NetworkImage(store.photoUrl!)
                        : null,
                child: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                    ? null
                    : Text(
                        store.userAvatar,
                        style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${store.userName}',
                      style: GoogleFonts.roboto(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: GlassTheme.mutedSilver),
                        children: [
                          const TextSpan(text: 'Active Session • '),
                          TextSpan(
                            text: store.hasAssignedRole
                                ? store.displayRoleTitle
                                : 'Awaiting Role Assignment',
                            style: TextStyle(
                              color: store.hasAssignedRole
                                  ? GlassTheme.accentEmerald
                                  : GlassTheme.accentAmber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' • '),
                          TextSpan(
                              text: store.userEmail,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    if (!store.hasAssignedRole) ...[
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: () => _showRoleSelectionDialog(context, store),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 13, color: GlassTheme.accentSky),
                            const SizedBox(width: 4),
                            Text(
                              'Assign or Select Role',
                              style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: GlassTheme.accentSky,
                                  decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Core Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Create an Event',
                      style: GoogleFonts.roboto(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                  onPressed: () => _showCreateEventDialog(context, store),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GlassTheme.white,
                    side: const BorderSide(color: GlassTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text('Join with Code',
                      style: GoogleFonts.roboto(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  onPressed: () => _showJoinEventDialog(context, store),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. QUICK ACTIONS — Dynamically Generated from Permissions
  // ===========================================================================
  Widget _buildDynamicQuickActions(
      BuildContext context, GroundFlowRealtimeStore store) {
    final actions = _generateActionsFromPermissions(context, store);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: GlassTheme.chrome),
            ),
            Text(
              'Permission-Aware',
              style: GoogleFonts.roboto(
                  fontSize: 10.5,
                  color: GlassTheme.mutedSilver,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions.map((a) {
            return InkWell(
              onTap: a['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF121216),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlassTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (a['color'] as Color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(a['icon'] as IconData,
                          size: 15, color: a['color'] as Color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      a['label'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _generateActionsFromPermissions(
      BuildContext context, GroundFlowRealtimeStore store) {
    final isCreator = store.events.any(
        (e) => store.getUserRoleForEvent(e['code'] ?? '') == EventRole.creator);
    final role = store.currentRole;

    List<Map<String, dynamic>> list = [];

    // Action 1: Create Event (Creator / Head) or Join
    if (isCreator || role == AppRole.departmentHead) {
      list.add({
        'icon': Icons.add_circle_outline_rounded,
        'label': 'Create Event',
        'color': Colors.white,
        'onTap': () => _showCreateEventDialog(context, store),
      });
    }

    // Action 2: Join with Passcode
    list.add({
      'icon': Icons.qr_code_2_rounded,
      'label': 'Join Event Code',
      'color': GlassTheme.accentSky,
      'onTap': () => _showJoinEventDialog(context, store),
    });

    // Action 3: Hardware Camera QR Scanner
    list.add({
      'icon': Icons.camera_alt_outlined,
      'label': 'Scan Pass QR',
      'color': GlassTheme.accentEmerald,
      'onTap': () => _openFastScanner(context, store),
    });

    // Action 4: Role-specific action
    if (isCreator) {
      list.add({
        'icon': Icons.admin_panel_settings_outlined,
        'label': 'Role Clearance',
        'color': const Color(0xFFF472B6),
        'onTap': () => _showRoleSelectionDialog(context, store),
      });
    } else if (role == AppRole.teamLead) {
      list.add({
        'icon': Icons.task_alt_rounded,
        'label': 'Squad Tasks',
        'color': GlassTheme.accentAmber,
        'onTap': () {
          if (store.events.isNotEmpty) {
            _openEventWorkspace(store.events.first['code']);
          } else {
            _showJoinEventDialog(context, store);
          }
        },
      });
    } else {
      list.add({
        'icon': Icons.badge_outlined,
        'label': 'My Digital Pass',
        'color': const Color(0xFFA78BFA),
        'onTap': () {
          if (store.events.isNotEmpty) {
            _openEventWorkspace(store.events.first['code']);
          } else {
            _showJoinEventDialog(context, store);
          }
        },
      });
    }

    return list;
  }

  // ===========================================================================
  // 4. NEEDS YOUR ATTENTION — Pending Actions and Alerts
  // ===========================================================================
  Widget _buildNeedsAttentionSection(GroundFlowRealtimeStore store) {
    final pendingApprovals = store.approvals
        .where((a) => a.status == ApprovalDecision.pending)
        .length;
    final hasConflict = store.conflictResult?.hasConflict == true;
    final blockedTasks =
        store.tasks.where((t) => t.status == TaskStatus.blocked).length;

    final hasUrgentItem =
        pendingApprovals > 0 || hasConflict || blockedTasks > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  hasUrgentItem
                      ? Icons.priority_high_rounded
                      : Icons.verified_user_rounded,
                  size: 16,
                  color: hasUrgentItem
                      ? GlassTheme.accentAmber
                      : GlassTheme.accentEmerald,
                ),
                const SizedBox(width: 8),
                Text(
                  'Needs Your Attention',
                  style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            ),
            if (hasUrgentItem)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: GlassTheme.statusRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: GlassTheme.statusRed.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'ACTION REQUIRED',
                  style: GoogleFonts.roboto(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: GlassTheme.statusRed),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (!hasUrgentItem)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1712),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: GlassTheme.accentEmerald.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: GlassTheme.accentEmerald, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All Systems Cleared',
                          style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(
                          'No pending approvals, resource conflicts, or urgent alerts.',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (hasConflict)
            _buildAttentionAlertCard(
              icon: Icons.warning_amber_rounded,
              color: GlassTheme.statusRed,
              title: 'Resource Collision Detected',
              subtitle: store.conflictResult!.conflictDetails,
              actionLabel: 'Resolve Conflict',
              onTap: () {
                if (store.events.isNotEmpty) {
                  _openEventWorkspace(store.events.first['code']);
                }
              },
            ),
          if (pendingApprovals > 0)
            _buildAttentionAlertCard(
              icon: Icons.gavel_rounded,
              color: GlassTheme.accentAmber,
              title: '$pendingApprovals Stage Approvals Pending',
              subtitle:
                  'Department applications and budget sign-offs awaiting review.',
              actionLabel: 'Review Sign-offs',
              onTap: () {
                if (store.events.isNotEmpty) {
                  _openEventWorkspace(store.events.first['code']);
                }
              },
            ),
          if (blockedTasks > 0)
            _buildAttentionAlertCard(
              icon: Icons.block_flipped,
              color: GlassTheme.accentSky,
              title: '$blockedTasks Tasks Blocked in Squads',
              subtitle:
                  'Logistics or gear impediments flagged by volunteers.',
              actionLabel: 'Unblock Tasks',
              onTap: () {
                if (store.events.isNotEmpty) {
                  _openEventWorkspace(store.events.first['code']);
                }
              },
            ),
        ],
      ],
    );
  }

  Widget _buildAttentionAlertCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(subtitle,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: GlassTheme.mutedSilver),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel,
                style: GoogleFonts.roboto(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. MY EVENTS — Created and Participating Events
  // ===========================================================================
  Widget _buildMyEventsSection(
    BuildContext context,
    GroundFlowRealtimeStore store,
    bool hasActiveEvents,
    List<Map<String, dynamic>> createdEvents,
    List<Map<String, dynamic>> participatingEvents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exact String for Tests: "Your Events (X)"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Events (${store.events.length})',
              style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            if (hasActiveEvents)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: GlassTheme.accentEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: GlassTheme.accentEmerald.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 6, color: GlassTheme.accentEmerald),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE PROTOCOL',
                      style: GoogleFonts.roboto(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: GlassTheme.accentEmerald),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // If no events exist, show clean empty state (zero dummy events)
        if (!hasActiveEvents)
          _buildNoEventsCard(context, store)
        else ...[
          // Sub-Filter Tabs
          Row(
            children: [
              _filterPill(
                title: 'All (${store.events.length})',
                isSelected: _eventsSubFilter == 0,
                onTap: () => setState(() => _eventsSubFilter = 0),
              ),
              const SizedBox(width: 8),
              _filterPill(
                title: 'Created (${createdEvents.length})',
                isSelected: _eventsSubFilter == 1,
                onTap: () => setState(() => _eventsSubFilter = 1),
              ),
              const SizedBox(width: 8),
              _filterPill(
                title: 'Participating (${participatingEvents.length})',
                isSelected: _eventsSubFilter == 2,
                onTap: () => setState(() => _eventsSubFilter = 2),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // SECTION 1: Events Created by the User
          if (_eventsSubFilter == 0 || _eventsSubFilter == 1) ...[
            Row(
              children: [
                const Icon(Icons.stars_rounded,
                    size: 16, color: Color(0xFFF472B6)),
                const SizedBox(width: 6),
                Text(
                  'Created by You (${createdEvents.length})',
                  style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (createdEvents.isEmpty)
              _buildEmptySectionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'No Events Created',
                subtitle:
                    'You haven\'t organized any events yet. Tap "Create an Event" to start.',
              )
            else
              ...createdEvents
                  .map((event) => _buildEventCard(context, store, event)),
            const SizedBox(height: 16),
          ],

          // SECTION 2: Events Where User Participates
          if (_eventsSubFilter == 0 || _eventsSubFilter == 2) ...[
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 16, color: GlassTheme.accentSky),
                const SizedBox(width: 6),
                Text(
                  'Participating Events (${participatingEvents.length})',
                  style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (participatingEvents.isEmpty)
              _buildEmptySectionCard(
                icon: Icons.login_rounded,
                title: 'No Joined Events',
                subtitle:
                    'You haven\'t joined any external events yet. Tap "Join with Code" to enter.',
              )
            else
              ...participatingEvents
                  .map((event) => _buildEventCard(context, store, event)),
          ],
        ],
      ],
    );
  }

  Widget _filterPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF222228) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? GlassTheme.border : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : GlassTheme.mutedSilver,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. UPCOMING SCHEDULE — Only Relevant Activities
  // ===========================================================================
  Widget _buildUpcomingScheduleSection(GroundFlowRealtimeStore store) {
    final sessions = store.sessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 15, color: GlassTheme.accentSky),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Schedule',
                  style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            ),
            if (sessions.isNotEmpty)
              Text(
                '${sessions.length} sessions active',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: GlassTheme.mutedSilver),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 16, color: GlassTheme.mutedSilver),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No upcoming sessions scheduled for today.',
                    style: GoogleFonts.roboto(
                        fontSize: 11.5, color: GlassTheme.mutedSilver),
                  ),
                ),
              ],
            ),
          )
        else
          ...sessions.take(3).map((s) => _buildScheduleRow(s)),
      ],
    );
  }

  Widget _buildScheduleRow(EventSessionModel session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121216),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: GlassTheme.accentSky.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              session.startTime,
              style: GoogleFonts.robotoMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: GlassTheme.accentSky),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${session.room} • Speaker: ${session.speaker}',
                  style: GoogleFonts.roboto(
                      fontSize: 10.5, color: GlassTheme.mutedSilver),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (session.isLiveNow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: GlassTheme.accentEmerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LIVE',
                style: GoogleFonts.roboto(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: GlassTheme.accentEmerald),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. DISCOVER EVENTS — If Enabled
  // ===========================================================================
  Widget _buildDiscoverEventsSection(GroundFlowRealtimeStore store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.explore_outlined,
                    size: 16, color: GlassTheme.accentEmerald),
                const SizedBox(width: 8),
                Text(
                  'Discover Events',
                  style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            ),
            Text(
              'Public Directory',
              style: GoogleFonts.roboto(
                  fontSize: 10.5, color: GlassTheme.mutedSilver),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF101014),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GlassTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GlassTheme.accentEmerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.travel_explore_rounded,
                        size: 18, color: GlassTheme.accentEmerald),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campus Conclaves & Tech Summits',
                          style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Explore and register for university-verified symposiums.',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: GlassTheme.mutedSilver),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: GlassTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 38),
                ),
                icon: const Icon(Icons.search_rounded,
                    size: 16, color: GlassTheme.accentEmerald),
                label: Text('Browse Public Directory',
                    style: GoogleFonts.roboto(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => setState(() => _currentBottomNavIndex = 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DEDICATED VIEWS FOR OTHER BOTTOM TABS
  // ===========================================================================
  Widget _buildDedicatedMyEventsView(
    BuildContext context,
    GroundFlowRealtimeStore store,
    List<Map<String, dynamic>> createdEvents,
    List<Map<String, dynamic>> participatingEvents,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'My Events Ledger',
          style: GoogleFonts.roboto(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage the events you organize or view credentials for events you attend',
          style:
              GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver),
        ),
        const SizedBox(height: 16),
        _buildMyEventsSection(
            context, store, store.events.isNotEmpty, createdEvents, participatingEvents),
      ],
    );
  }

  Widget _buildDedicatedDiscoverView(
      BuildContext context, GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Discover Campus Events',
          style: GoogleFonts.roboto(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Publicly registered events and symposiums across your academic network',
          style:
              GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver),
        ),
        const SizedBox(height: 16),
        if (store.events.isEmpty)
          _buildEmptySectionCard(
            icon: Icons.explore_off_outlined,
            title: 'No Public Events Listed',
            subtitle:
                'All campus summits are actively synchronized. Create an event to list one publicly.',
          )
        else
          ...store.events.map((e) => _buildEventCard(context, store, e)),
      ],
    );
  }

  Widget _buildDedicatedActivityView(
      BuildContext context, GroundFlowRealtimeStore store) {
    final activities = store.activityLogs;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Operational Activity Stream',
          style: GoogleFonts.roboto(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Live audit trails, check-in timestamps, and operational dispatch logs',
          style:
              GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver),
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          _buildEmptySectionCard(
            icon: Icons.history_rounded,
            title: 'No Activity Recorded',
            subtitle:
                'Real-time actions, gate scans, and duty assignments will appear here live.',
          )
        else
          ...activities.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF101014),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GlassTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: GlassTheme.accentEmerald),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.action,
                              style: GoogleFonts.roboto(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(a.details,
                              style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: GlassTheme.mutedSilver)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildDedicatedProfileView(
      BuildContext context, GroundFlowRealtimeStore store) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'User Profile & Security',
          style: GoogleFonts.roboto(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: GlassTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GlassTheme.border),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF222228),
                backgroundImage:
                    (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                        ? NetworkImage(store.photoUrl!)
                        : null,
                child: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                    ? null
                    : Text(
                        store.userAvatar,
                        style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                      ),
              ),
              const SizedBox(height: 12),
              Text(store.userName,
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(store.userEmail,
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: GlassTheme.mutedSilver)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GlassTheme.accentSky.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Role: ${store.displayRoleTitle}',
                  style: GoogleFonts.roboto(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: GlassTheme.accentSky),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFF101014),
          leading: const Icon(Icons.badge_outlined, color: GlassTheme.accentSky),
          title: Text('Change Operational Role',
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.white)),
          onTap: () => _showRoleSelectionDialog(context, store),
        ),
        const SizedBox(height: 8),
        ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFF101014),
          leading:
              const Icon(Icons.cloud_sync_rounded, color: GlassTheme.accentEmerald),
          title: Text('Test Cloud Connectivity',
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.white)),
          onTap: () => _showCloudDiagnosticDialog(context),
        ),
        const SizedBox(height: 8),
        ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFF101014),
          leading: const Icon(Icons.logout_rounded, color: GlassTheme.statusRed),
          title: Text('Sign Out',
              style: GoogleFonts.roboto(fontSize: 13, color: GlassTheme.statusRed)),
          onTap: () {
            store.signOut();
            widget.onSignOut();
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // CARDS & COMPONENTS
  // ===========================================================================
  Widget _buildEmptySectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassTheme.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF18181F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: GlassTheme.mutedSilver, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: GlassTheme.mutedSilver),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEventsCard(
      BuildContext context, GroundFlowRealtimeStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GlassTheme.accentSky.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_outlined,
                size: 28, color: GlassTheme.accentSky),
          ),
          const SizedBox(height: 14),
          Text(
            'No Events Created or Joined Yet',
            style: GoogleFonts.roboto(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your campus event or enter an event passcode to launch the live volunteer ledger.',
            style: GoogleFonts.roboto(
                fontSize: 12.5, color: GlassTheme.mutedSilver),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward_rounded,
                    size: 14, color: GlassTheme.accentSky),
                const SizedBox(width: 6),
                Text(
                  'Use "Create an Event" or "Join with Code" above to begin',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: GlassTheme.chrome),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, GroundFlowRealtimeStore store,
      Map<String, dynamic> event) {
    final code = event['code'] as String? ?? '';
    final title = event['title'] as String? ?? 'Campus Event';
    final venue = extractEventVenue(event['venue'], fallback: 'Campus Arena');
    final isCurrent = store.currentEventCode == code;
    final isCreator = store.getUserRoleForEvent(code) == EventRole.creator;

    void openEventDetails() {
      store.joinEvent(code);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventOperationsWorkspaceScreen(eventCode: code),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? const Color(0xFF3F3F46) : GlassTheme.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('event_card_$code'),
          borderRadius: BorderRadius.circular(18),
          onTap: openEventDetails,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCreator
                        ? const Color(0xFF3B1D28)
                        : const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCreator
                          ? const Color(0xFFF472B6).withValues(alpha: 0.3)
                          : GlassTheme.border,
                    ),
                  ),
                  child: Icon(
                    isCreator
                        ? Icons.stars_rounded
                        : Icons.confirmation_number_outlined,
                    color: isCreator
                        ? const Color(0xFFF472B6)
                        : GlassTheme.accentSky,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.roboto(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                          children: [
                            TextSpan(
                              text: code,
                              style: TextStyle(
                                color: isCreator
                                    ? const Color(0xFFF472B6)
                                    : GlassTheme.accentSky,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: ' • $title'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '📍 $venue • Passcode: $code',
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: GlassTheme.chrome),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isCreator
                                  ? const Color(0xFF3B1D28)
                                  : const Color(0xFF0F2537),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isCreator
                                    ? const Color(0xFFF472B6)
                                        .withValues(alpha: 0.4)
                                    : GlassTheme.accentSky
                                        .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isCreator
                                  ? '👑 Organized by You'
                                  : '🎟️ Participant',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isCreator
                                    ? const Color(0xFFF472B6)
                                    : GlassTheme.accentSky,
                              ),
                            ),
                          ),
                          Text(
                            isCreator
                                ? 'Tap to manage →'
                                : 'Tap for details & pass →',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: GlassTheme.mutedSilver,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCreator)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: GlassTheme.statusRed),
                    tooltip: 'Delete Event',
                    onPressed: () =>
                        _confirmDeleteEvent(context, store, code, title),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: GlassTheme.mutedSilver),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEventWorkspace(String code) {
    final store = GroundFlowRealtimeStore();
    store.joinEvent(code);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventOperationsWorkspaceScreen(eventCode: code),
      ),
    );
  }

  void _openFastScanner(BuildContext context, GroundFlowRealtimeStore store) {
    if (store.events.isNotEmpty) {
      _openEventWorkspace(store.events.first['code']);
    } else {
      _showJoinEventDialog(context, store);
    }
  }

  // ===========================================================================
  // SEARCH MODAL
  // ===========================================================================
  void _showSearchModal(BuildContext context, GroundFlowRealtimeStore store) {
    _searchCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101014),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: GlassTheme.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final query = _searchCtrl.text.toLowerCase().trim();
          final matchingEvents = store.events.where((e) {
            final t = (e['title'] ?? '').toString().toLowerCase();
            final c = (e['code'] ?? '').toString().toLowerCase();
            final v = (e['venue'] ?? '').toString().toLowerCase();
            return t.contains(query) || c.contains(query) || v.contains(query);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.70,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 20, color: GlassTheme.accentSky),
                    const SizedBox(width: 8),
                    Text(
                      'Search Events & Venues',
                      style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: GlassTheme.mutedSilver),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    autofocus: true,
                    controller: _searchCtrl,
                    style:
                        GoogleFonts.roboto(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search by title, event code, or campus hall...',
                      hintStyle: GoogleFonts.roboto(
                          color: GlassTheme.mutedSilver, fontSize: 12.5),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setModalState(() {}),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: matchingEvents.isEmpty
                    ? Center(
                        child: Text(
                          query.isEmpty
                              ? 'Type above to search through your campus events'
                              : 'No events match "$query"',
                          style: GoogleFonts.roboto(
                              color: GlassTheme.mutedSilver, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matchingEvents.length,
                        itemBuilder: (ctx, i) {
                          final e = matchingEvents[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.hub_rounded,
                                color: GlassTheme.accentSky),
                            title: Text(
                              e['title'] ?? e['code'] ?? '',
                              style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Code: ${e['code']} • ${extractEventVenue(e['venue'])}',
                              style: GoogleFonts.roboto(
                                  color: GlassTheme.mutedSilver, fontSize: 11),
                            ),
                            trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: GlassTheme.mutedSilver),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openEventWorkspace(e['code']);
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // NOTIFICATIONS SHEET
  // ===========================================================================
  void _showNotificationsSheet(
      BuildContext context, GroundFlowRealtimeStore store) {
    final announcements = store.announcements;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101014),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: GlassTheme.border),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined,
                    size: 20, color: GlassTheme.accentSky),
                const SizedBox(width: 8),
                Text(
                  'Operations Notifications',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: GlassTheme.mutedSilver),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (announcements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No new alerts or broadcast announcements.',
                    style: GoogleFonts.roboto(
                        color: GlassTheme.mutedSilver, fontSize: 13),
                  ),
                ),
              )
            else
              ...announcements.take(4).map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GlassTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              a.title,
                              style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                            const Spacer(),
                            Text(
                              a.urgency.displayName,
                              style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: GlassTheme.accentAmber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.message,
                          style: GoogleFonts.roboto(
                              fontSize: 11.5, color: GlassTheme.mutedSilver),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DIALOGS & ACTIONS (Create, Join, Role, Cloud, Delete)
  // ===========================================================================
  void _showCreateEventDialog(
      BuildContext context, GroundFlowRealtimeStore store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalEventWizardScreen(
          onEventCreated: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showJoinEventDialog(
      BuildContext context, GroundFlowRealtimeStore store) {
    _joinCodeCtrl.clear();
    _joinPasswordCtrl.clear();
    String? joinError;
    bool isJoining = false;
    bool obscurePass = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: GlassTheme.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.meeting_room_rounded,
                        color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Join Campus Event',
                    style: GoogleFonts.roboto(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the Event Code and Password provided by your organizer to join the live operational ledger.',
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: GlassTheme.mutedSilver,
                    height: 1.3),
              ),
              const SizedBox(height: 18),
              _dialogInput(
                label: 'Event Code / Reference ID *',
                controller: _joinCodeCtrl,
                hint: 'e.g. SUMMIT-2026',
                prefixIcon: Icons.tag_rounded,
              ),
              const SizedBox(height: 12),
              _dialogInput(
                label: 'Event Password / Passcode *',
                controller: _joinPasswordCtrl,
                hint: 'Enter event password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                obscure: obscurePass,
                onToggleObscure: () =>
                    setModalState(() => obscurePass = !obscurePass),
              ),
              if (joinError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: GlassTheme.statusRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: GlassTheme.statusRed.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: GlassTheme.statusRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          joinError!,
                          style: GoogleFonts.roboto(
                              color: GlassTheme.statusRed,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isJoining
                      ? null
                      : () async {
                          final code = _joinCodeCtrl.text.trim();
                          final pass = _joinPasswordCtrl.text.trim();

                          if (code.isEmpty) {
                            setModalState(() =>
                                joinError = 'Please enter an Event Code.');
                            return;
                          }

                          setModalState(() {
                            isJoining = true;
                            joinError = null;
                          });

                          final result = await store.joinEventWithPassword(
                              code: code, password: pass);

                          if (!ctx.mounted) return;

                          if (result['success'] == true) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] as String? ??
                                    '✓ Joined event!'),
                                backgroundColor: GlassTheme.accentEmerald,
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      EventOperationsWorkspaceScreen(
                                          eventCode: code)),
                            );
                          } else {
                            setModalState(() {
                              isJoining = false;
                              joinError = result['message'] as String? ??
                                  'Failed to join event.';
                            });
                          }
                        },
                  child: isJoining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : Text('Verify & Join Operational Hub',
                          style:
                              GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleSelectionDialog(
      BuildContext context, GroundFlowRealtimeStore store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GlassTheme.border),
        ),
        title: Text('Select Your Operational Role',
            style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppRole.values.map((role) {
            final isCurrent = role == store.currentRole && store.hasAssignedRole;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF222228)
                    : const Color(0xFF0E0E12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isCurrent
                        ? GlassTheme.accentEmerald
                        : GlassTheme.border),
              ),
              child: ListTile(
                leading: Icon(
                  isCurrent
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isCurrent ? GlassTheme.accentEmerald : Colors.grey,
                  size: 20,
                ),
                title: Text(role.title,
                    style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5)),
                subtitle: Text(
                  role == AppRole.departmentHead
                      ? 'Event / Department Administrator'
                      : (role == AppRole.teamLead
                          ? 'Squad Lead (Field Coordinator)'
                          : 'Ground Volunteer / Crew Member'),
                  style: GoogleFonts.roboto(
                      color: GlassTheme.mutedSilver, fontSize: 11),
                ),
                onTap: () {
                  store.switchRole(role);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✓ Role set to ${role.title}')),
                  );
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: GlassTheme.chrome)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, GroundFlowRealtimeStore store,
      String code, String title) {
    final permissions = store.getUserPermissions(code);
    if (!permissions.canDeleteEvent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ Access Denied: Only the Event Creator / Super Admin has authority to delete this event.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GlassTheme.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlassTheme.statusRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: GlassTheme.statusRed, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Event',
                style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "$title" ($code)?',
              style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This will remove the event, its operational tasks, and clear its live cloud ledger on Firestore. This action cannot be undone.',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: GlassTheme.mutedSilver, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: GlassTheme.chrome)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.statusRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedFromCloud = await store.removeEvent(code);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      deletedFromCloud
                          ? '✓ Event $code permanently deleted from Cloud Firestore & local ledger.'
                          : '✓ Event $code removed from local ledger.',
                    ),
                    backgroundColor: GlassTheme.statusRed,
                  ),
                );
              }
            },
            child: Text('Delete Event',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCloudDiagnosticDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GlassTheme.border),
        ),
        title: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: GlassTheme.accentSky)),
            const SizedBox(width: 12),
            Text('Testing Cloud Firestore...',
                style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
        content: Text(
            'Testing real-time read and write connectivity to Firebase Project: groundflow-acca3',
            style: GoogleFonts.roboto(
                fontSize: 12, color: GlassTheme.mutedSilver)),
      ),
    );

    final result = await FirestoreService().testFirestoreDiagnostic();
    if (!context.mounted) return;
    Navigator.pop(context); // close progress dialog

    final isSuccess = result['status'] == 'SUCCESS';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: isSuccess
                  ? GlassTheme.accentEmerald
                  : GlassTheme.statusRed),
        ),
        title: Row(
          children: [
            Icon(
                isSuccess
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                color: isSuccess
                    ? GlassTheme.accentEmerald
                    : GlassTheme.statusRed,
                size: 22),
            const SizedBox(width: 10),
            Text(isSuccess ? 'Cloud Connected' : 'Cloud Sync Notice',
                style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuccess
                  ? 'Your mobile app is actively connected to Google Cloud Firestore (groundflow-acca3). Events and user profiles are syncing live!'
                  : 'Cloud operation returned: ${result['error'] ?? result['reason'] ?? 'Unknown status'}',
              style: GoogleFonts.roboto(
                  fontSize: 12.5, color: Colors.white70, height: 1.4),
            ),
            if (!isSuccess &&
                (result['error']?.toString().contains('permission-denied') ??
                    false)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFF221516),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Action Required: Open Firebase Console > Firestore Database > Rules and ensure read/write is allowed.',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: GlassTheme.statusRed),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.white,
                foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _dialogInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    final bool shouldObscure = isPassword && obscure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GlassTheme.chrome)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E11),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GlassTheme.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: shouldObscure,
            enableSuggestions: !isPassword,
            autocorrect: !isPassword,
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.roboto(
                  color: const Color(0xFF52525B), fontSize: 12.5),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: GlassTheme.chrome, size: 16)
                  : null,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: GlassTheme.chrome,
                        size: 16,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
