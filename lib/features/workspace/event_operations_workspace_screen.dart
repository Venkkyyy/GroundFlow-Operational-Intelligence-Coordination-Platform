import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/state/ground_flow_realtime_store.dart';
import '../../core/models/universal_event_model.dart';
import '../../core/services/event_email_service.dart';

class EventOperationsWorkspaceScreen extends StatefulWidget {
  final String eventCode;
  final VoidCallback? onBack;

  const EventOperationsWorkspaceScreen({
    super.key,
    required this.eventCode,
    this.onBack,
  });

  @override
  State<EventOperationsWorkspaceScreen> createState() =>
      _EventOperationsWorkspaceScreenState();
}

class _EventOperationsWorkspaceScreenState
    extends State<EventOperationsWorkspaceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _scannerAnimCtrl;
  final GroundFlowRealtimeStore _store = GroundFlowRealtimeStore();

  // Participant Search & Filter
  String _searchQuery = '';
  String _selectedFilter = 'All';

  // Task Filter
  String _taskFilter = 'All';

  // Participant Tab Submode: 0 = Directory, 1 = Rapid Gate Scanner
  int _participantSubMode = 0;

  // Scanner & Camera Controls
  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);
  MobileScannerController? _cameraController;
  DateTime? _lastScanTime;
  final TextEditingController _scanCtrl = TextEditingController();
  Map<String, dynamic>? _lastScanResult;
  bool _showPassQr = false;
  bool _isCameraActive = true;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  // Communication Channel State
  String _activeCommsChannel = 'all-ops';
  final TextEditingController _quickCommsCtrl = TextEditingController();
  final TextEditingController _fullCommsCtrl = TextEditingController();
  final ScrollController _commsScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 11, vsync: this);
    _scannerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    if (!_isDesktop) {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        autoStart: false, // We call start() manually when Gate Scanner tab is opened
      );
    }
    // Listen to tab changes so camera pauses/resumes on the correct tab
    _tabController.addListener(_onMainTabChanged);
  }

  void _onMainTabChanged() {
    // Participants tab is index 0 — camera only relevant there
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index != 0) {
      _pauseCameraIfActive();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onMainTabChanged);
    if (!_isDesktop) {
      _cameraController?.dispose();
    }
    _scannerAnimCtrl.dispose();
    _tabController.dispose();
    _scanCtrl.dispose();
    _quickCommsCtrl.dispose();
    _fullCommsCtrl.dispose();
    _commsScrollCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getEventData() {
    return _store.events.firstWhere(
      (e) => e['code'] == widget.eventCode,
      orElse: () => {
        'code': widget.eventCode,
        'title': '${widget.eventCode} Operations',
        'venue': 'Campus Pavilion',
        'status': 'Live Protocol',
        'lifecycle': 'published',
      },
    );
  }

  EventLifecycleState _getLifecycleState(Map<String, dynamic> event) {
    return EventLifecycleState.fromString(
        event['lifecycle'] as String? ?? 'published');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final event = _getEventData();
        final lifecycle = _getLifecycleState(event);

        return Scaffold(
          backgroundColor: GlassTheme.black,
          appBar: _buildWorkspaceAppBar(event, lifecycle),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(event, lifecycle),
              _buildScheduleTab(event),
              _buildMyPassTab(event),
              _buildVenueTab(event),
              _buildCommunicationChannelTab(event),
              _buildDepartmentsAndTeamsTab(event),
              _buildTasksTab(event),
              _buildApprovalsAndConflictsTab(event),
              _buildBudgetTab(event),
              _buildInvitationsTab(event),
              _buildParticipantsAndScannerTab(event),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildWorkspaceAppBar(
      Map<String, dynamic> event, EventLifecycleState lifecycle) {
    final title = event['title'] as String? ?? widget.eventCode;
    final isCreator =
        _store.getUserRoleForEvent(widget.eventCode) == EventRole.creator;

    return AppBar(
      backgroundColor: const Color(0xFF0C0C10),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _buildLifecycleBadge(lifecycle),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.eventCode} • Operations Hub',
            style: GoogleFonts.roboto(
                fontSize: 10.5, color: GlassTheme.mutedSilver),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Access & Roles',
          icon: const Icon(Icons.shield_outlined,
              size: 20, color: Color(0xFF818CF8)),
          onPressed: () => _showRolePermissionsModal(event),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
          color: const Color(0xFF141418),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: GlassTheme.border),
          ),
          onSelected: (val) {
            switch (val) {
              case 'owner_pass':
                _showOwnerConfirmationEmailModal(event);
                break;
              case 'broadcast':
                _showBroadcastAnnouncementDialog(event);
                break;
              case 'audit':
                _showAuditReportSheet(event);
                break;
              case 'lifecycle':
                _showLifecycleTransitionSheet(lifecycle);
                break;
            }
          },
          itemBuilder: (ctx) => [
            if (isCreator)
              PopupMenuItem(
                value: 'owner_pass',
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_rounded,
                        size: 16, color: Color(0xFFF472B6)),
                    const SizedBox(width: 10),
                    Text('Owner VIP Pass & Credentials',
                        style: GoogleFonts.roboto(
                            fontSize: 12.5, color: Colors.white)),
                  ],
                ),
              ),
            if (isCreator)
              PopupMenuItem(
                value: 'broadcast',
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded,
                        size: 16, color: GlassTheme.accentAmber),
                    const SizedBox(width: 10),
                    Text('Broadcast Announcement',
                        style: GoogleFonts.roboto(
                            fontSize: 12.5, color: Colors.white)),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'audit',
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded,
                      size: 16, color: GlassTheme.accentEmerald),
                  const SizedBox(width: 10),
                  Text('Audit & Intelligence Report',
                      style: GoogleFonts.roboto(
                          fontSize: 12.5, color: Colors.white)),
                ],
              ),
            ),
            if (isCreator)
              PopupMenuItem(
                value: 'lifecycle',
                child: Row(
                  children: [
                    const Icon(Icons.published_with_changes_rounded,
                        size: 16, color: GlassTheme.accentSky),
                    const SizedBox(width: 10),
                    Text('Transition Lifecycle',
                        style: GoogleFonts.roboto(
                            fontSize: 12.5, color: Colors.white)),
                  ],
                ),
              ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: GlassTheme.white,
        indicatorWeight: 2,
        labelColor: Colors.white,
        unselectedLabelColor: GlassTheme.mutedSilver,
        labelStyle:
            GoogleFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w500),
        tabs: [
          const Tab(
              icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Overview'),
          Tab(
            icon: const Icon(Icons.schedule_rounded, size: 18),
            text: 'Schedule (${_store.sessions.length})',
          ),
          const Tab(
            icon: Icon(Icons.badge_rounded, size: 18),
            text: 'My Pass',
          ),
          const Tab(
            icon: Icon(Icons.location_on_rounded, size: 18),
            text: 'Venue',
          ),
          Tab(
            icon: const Icon(Icons.forum_rounded, size: 18),
            text: 'Comms (${_store.chatMessages.length})',
          ),
          Tab(
            icon: const Icon(Icons.groups_rounded, size: 18),
            text: 'Teams (${_store.teams.length})',
          ),
          Tab(
            icon: const Icon(Icons.task_alt_rounded, size: 18),
            text: 'Tasks (${_store.tasks.length})',
          ),
          Tab(
            icon: const Icon(Icons.verified_user_rounded, size: 18),
            text: 'Approvals (${_store.approvals.length})',
          ),
          Tab(
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
            text:
                'Budget (₹${_store.totalExpensesIncurred.toStringAsFixed(0)})',
          ),
          Tab(
            icon: const Icon(Icons.link_rounded, size: 18),
            text: 'Passes (${_store.invitationLinks.length})',
          ),
          Tab(
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            text: 'Gate (${_store.participants.length})',
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleBadge(EventLifecycleState state) {
    Color bg = const Color(0xFF1E293B);
    Color fg = const Color(0xFF94A3B8);

    switch (state) {
      case EventLifecycleState.draft:
        bg = const Color(0xFF334155);
        fg = const Color(0xFFCBD5E1);
        break;
      case EventLifecycleState.pendingApproval:
        bg = const Color(0xFF451A03);
        fg = GlassTheme.accentAmber;
        break;
      case EventLifecycleState.approved:
        bg = const Color(0xFF064E3B);
        fg = GlassTheme.accentEmerald;
        break;
      case EventLifecycleState.published:
        bg = const Color(0xFF0C4A6E);
        fg = GlassTheme.accentSky;
        break;
      case EventLifecycleState.preparation:
        bg = const Color(0xFF312E81);
        fg = const Color(0xFFA5B4FC);
        break;
      case EventLifecycleState.live:
        bg = const Color(0xFF065F46);
        fg = const Color(0xFF34D399);
        break;
      case EventLifecycleState.completed:
        bg = const Color(0xFF1E293B);
        fg = GlassTheme.chrome;
        break;
      case EventLifecycleState.cancelled:
      case EventLifecycleState.closed:
        bg = const Color(0xFF450A0A);
        fg = GlassTheme.statusRed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        state.displayName,
        style: GoogleFonts.roboto(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  void _showLifecycleTransitionSheet(EventLifecycleState current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event Lifecycle State Machine',
                style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('Transition ${widget.eventCode} through operational phases.',
                style: GoogleFonts.roboto(
                    fontSize: 12, color: GlassTheme.mutedSilver)),
            const SizedBox(height: 16),
            ...EventLifecycleState.values.map((s) {
              final isCurrent = s == current;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF22222A)
                      : const Color(0xFF101014),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isCurrent ? GlassTheme.white : GlassTheme.border),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    isCurrent
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isCurrent ? GlassTheme.accentEmerald : Colors.grey,
                  ),
                  title: Text(s.displayName,
                      style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _store.updateEventLifecycle(s);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('✓ Transitioned to ${s.displayName}'),
                            backgroundColor: GlassTheme.accentEmerald),
                      );
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: OVERVIEW & AUDIT LOGS
  // ===========================================================================
  Widget _buildOverviewTab(
      Map<String, dynamic> event, EventLifecycleState lifecycle) {
    final participants = _store.participants;
    final totalExpected = event['headcount'] != null
        ? (event['headcount']['expectedTotalAttendance'] as int? ?? 100)
        : 100;
    final registered = participants.length;
    final confirmed = _store.confirmedParticipantsCount;
    final checkedIn = _store.checkedInParticipantsCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Core Event & Venue Hero Section
          _buildEventHeroCard(event, lifecycle),
          const SizedBox(height: 14),

          // 2. Event Pass Section (Compact by default; QR code ONLY visible when user selects it!)
          _buildPassSection(event),
          const SizedBox(height: 14),

          // 3. Master Schedule & Agendas Section
          _buildScheduleSection(event),
          const SizedBox(height: 14),

          // 4. Venue & Space Logistics Section
          _buildVenueSection(event),
          const SizedBox(height: 14),

          // 5. Live Communication Channel & Squad Radio Section
          _buildCommunicationChannelSection(event),
          const SizedBox(height: 14),

          // 6. Automated Email & Countdown Reminders Section (1 Day, 2 Days, Guests, Volunteers, VIPs)
          _buildEmailAndRemindersSection(event),
          const SizedBox(height: 16),

          // Resource Conflict Alert Banner
          if (_store.conflictResult?.hasConflict == true) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GlassTheme.statusRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassTheme.statusRed),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: GlassTheme.statusRed, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resource Collision Detected',
                            style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(_store.conflictResult!.conflictDetails,
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: GlassTheme.mutedSilver)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Operational Headcount Matrix Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: GlassTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Live Operational Headcount',
                        style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GlassTheme.accentSky.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Target: $totalExpected',
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: GlassTheme.accentSky)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _metricColumn(
                            'Registered', '$registered', GlassTheme.white)),
                    Expanded(
                        child: _metricColumn('Confirmed', '$confirmed',
                            GlassTheme.accentEmerald)),
                    Expanded(
                        child: _metricColumn(
                            'Checked-In', '$checkedIn', GlassTheme.accentSky)),
                    Expanded(
                        child: _metricColumn(
                            'Pending',
                            '${_store.pendingRegistrationsCount}',
                            GlassTheme.accentAmber)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalExpected > 0
                        ? (checkedIn / totalExpected).clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: const Color(0xFF1E1E26),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        GlassTheme.accentEmerald),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Milestone 2 Enterprise Automation KPIs
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  icon: Icons.task_alt_rounded,
                  title: 'Tasks Progress',
                  value:
                      '${_store.completedTasksCount} / ${_store.totalTasksCount}',
                  subtitle:
                      '${(_store.tasksProgressRatio * 100).toInt()}% Operational Done',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryBox(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Incurred Spend',
                  value: '₹${_store.totalExpensesIncurred.toStringAsFixed(0)}',
                  subtitle: '${_store.expenses.length} Expense Records',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Operational Quick Stats
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  icon: Icons.groups_rounded,
                  title: 'Working Teams',
                  value: '${_store.teams.length}',
                  subtitle:
                      '${_store.teams.map((t) => t.members.length).fold(0, (a, b) => a + b)} Staff & Crew',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryBox(
                  icon: Icons.verified_user_rounded,
                  title: 'Governance',
                  value: _store.allApprovalsGranted
                      ? 'Approved'
                      : '${_store.approvals.where((a) => a.status == ApprovalDecision.approved).length}/${_store.approvals.length}',
                  subtitle: _store.allApprovalsGranted
                      ? 'Ready For Live Execution'
                      : 'Sign-Off In Progress',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Executive Intelligence & Post-Event Report Action Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GlassTheme.accentEmerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_rounded,
                      color: GlassTheme.accentEmerald, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Post-Event Intelligence & Audit',
                          style: GoogleFonts.roboto(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(
                          'Compile attendance turnout, task efficiency & financial variance.',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showAuditReportSheet(event),
                  child: Text('Generate Report',
                      style: GoogleFonts.roboto(
                          fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Incident Escalation Matrix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Live Incident Escalation (${_store.activeIncidentsCount} Active)',
                  style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              TextButton.icon(
                icon: const Icon(Icons.crisis_alert_rounded,
                    size: 14, color: GlassTheme.statusRed),
                label: Text('Report Incident',
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: GlassTheme.statusRed,
                        fontWeight: FontWeight.w700)),
                onPressed: () => _showReportIncidentDialog(event),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_store.incidents.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GlassTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: GlassTheme.accentEmerald, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'All operations green. Zero reported incidents across departments.',
                        style: GoogleFonts.roboto(
                            fontSize: 11.5, color: GlassTheme.mutedSilver)),
                  ),
                ],
              ),
            )
          else
            ..._store.incidents.map((inc) => _buildIncidentCard(inc)),

          const SizedBox(height: 24),

          // Broadcast & Emergency Push Announcements Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Broadcast Announcements (${_store.announcements.length})',
                  style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              TextButton.icon(
                icon: const Icon(Icons.campaign_rounded,
                    size: 14, color: GlassTheme.accentAmber),
                label: Text('New Broadcast',
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: GlassTheme.accentAmber,
                        fontWeight: FontWeight.w700)),
                onPressed: () => _showBroadcastAnnouncementDialog(event),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_store.announcements.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: GlassTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlassTheme.border)),
              child: Center(
                child: Text(
                    'No announcements sent yet. Use "New Broadcast" to message all attendees or specific squads.',
                    style: GoogleFonts.roboto(
                        fontSize: 11.5, color: GlassTheme.mutedSilver)),
              ),
            )
          else
            ..._store.announcements.map((ann) {
              Color fg = GlassTheme.accentSky;
              Color bg = const Color(0xFF0F172A);
              if (ann.urgency == AnnouncementUrgency.emergency) {
                fg = GlassTheme.statusRed;
                bg = const Color(0xFF450A0A);
              } else if (ann.urgency == AnnouncementUrgency.high) {
                fg = GlassTheme.accentAmber;
                bg = const Color(0xFF451A03);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0F0F13),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GlassTheme.border)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: bg, borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.campaign_rounded, size: 14, color: fg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(ann.title,
                                  style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(ann.audience.displayName,
                                    style: GoogleFonts.roboto(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: fg)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(ann.message,
                              style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  color: GlassTheme.mutedSilver)),
                          const SizedBox(height: 2),
                          Text(
                              'By ${ann.sentBy} • ${ann.sentAt.hour}:${ann.sentAt.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.roboto(
                                  fontSize: 10, color: GlassTheme.chrome)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // Audit & Activity Logs Stream
          Text('Live Audit & Activity Ledger',
              style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 10),
          if (_store.activityLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: GlassTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassTheme.border),
              ),
              child: Center(
                child: Text('No operational activity recorded yet.',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: GlassTheme.mutedSilver)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _store.activityLogs.length,
              itemBuilder: (ctx, idx) {
                final log = _store.activityLogs[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F13),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1C1C24),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.history_rounded,
                            size: 14, color: GlassTheme.accentSky),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.action,
                                style: GoogleFonts.roboto(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(log.details,
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    color: GlassTheme.mutedSilver)),
                          ],
                        ),
                      ),
                      Text(
                        '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.roboto(
                            fontSize: 10.5, color: GlassTheme.chrome),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.roboto(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 10.5, color: GlassTheme.mutedSilver)),
      ],
    );
  }

  Widget _summaryBox(
      {required IconData icon,
      required String title,
      required String value,
      required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GlassTheme.chrome, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(title,
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          Text(subtitle,
              style: GoogleFonts.roboto(
                  fontSize: 10.5, color: GlassTheme.mutedSilver)),
        ],
      ),
    );
  }

  EventParticipantModel? _findUserParticipant() {
    final email = _store.userEmail.toLowerCase().trim();
    if (email.isEmpty) return null;
    try {
      return _store.participants
          .firstWhere((p) => p.email.toLowerCase().trim() == email);
    } catch (_) {
      return null;
    }
  }

  Widget _buildEventHeroCard(
      Map<String, dynamic> event, EventLifecycleState lifecycle) {
    final title = event['title'] as String? ?? widget.eventCode;
    final venueName =
        extractEventVenue(event['venue'], fallback: 'Campus Main Arena');
    final code = widget.eventCode;
    final passcode =
        event['password'] as String? ?? event['passcode'] as String? ?? '';
    final isCreator = _store.getUserRoleForEvent(code) == EventRole.creator;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCreator
              ? [
                  const Color(0xFF2E1065),
                  const Color(0xFF1E1B4B),
                  const Color(0xFF0F172A)
                ]
              : [
                  const Color(0xFF064E3B),
                  const Color(0xFF0C4A6E),
                  const Color(0xFF0F172A)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCreator
              ? const Color(0xFFF472B6).withValues(alpha: 0.4)
              : GlassTheme.accentEmerald.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCreator
                      ? const Color(0xFF581C87)
                      : const Color(0xFF065F46),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCreator
                      ? '👑 EVENT CREATOR & ADMIN'
                      : '🎟️ ATTENDEE / STAFF',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isCreator
                        ? const Color(0xFFF472B6)
                        : GlassTheme.accentEmerald,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildLifecycleBadge(lifecycle),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.roboto(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 13, color: GlassTheme.accentSky),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  venueName,
                  style:
                      GoogleFonts.roboto(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded,
                          size: 13, color: GlassTheme.accentAmber),
                      const SizedBox(width: 6),
                      Text('Code: ',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: GlassTheme.mutedSilver)),
                      Text(code,
                          style: GoogleFonts.roboto(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      if (passcode.isNotEmpty) ...[
                        Text(' • Passcode: ',
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: GlassTheme.mutedSilver)),
                        Text(passcode,
                            style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: GlassTheme.accentSky)),
                      ],
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            'Event: $title\nCode: $code\nPasscode: $passcode\nVenue: $venueName'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('✓ Event credentials copied to clipboard!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded,
                            size: 12, color: GlassTheme.mutedSilver),
                        const SizedBox(width: 4),
                        Text('Copy',
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: GlassTheme.mutedSilver,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassSection(Map<String, dynamic> event) {
    final code = widget.eventCode;
    final title = event['title'] as String? ?? widget.eventCode;
    final isCreator = _store.getUserRoleForEvent(code) == EventRole.creator;
    final participant = _findUserParticipant();
    final passCode = isCreator
        ? 'VIP-$code-OWNER'
        : (participant?.ticketPassCode ??
            'PASS-$code-${_store.userName.hashCode.abs().toString().substring(0, 4)}');
    final passcode =
        event['password'] as String? ?? event['passcode'] as String? ?? '';
    final venueName =
        extractEventVenue(event['venue'], fallback: 'Campus Main Arena');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCreator
              ? const Color(0xFFF472B6).withValues(alpha: 0.35)
              : GlassTheme.accentEmerald.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isCreator
                          ? Icons.stars_rounded
                          : Icons.confirmation_number_rounded,
                      size: 18,
                      color: isCreator
                          ? const Color(0xFFF472B6)
                          : GlassTheme.accentEmerald,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCreator
                          ? 'My Pass • VIP Organizer Clearance'
                          : 'My Pass • Digital Event Ticket',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCreator
                        ? const Color(0xFF3B1D28)
                        : const Color(0xFF0F2537),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCreator
                        ? 'OWNER VIP'
                        : (participant?.attendanceStatus.displayName ??
                            'GATE READY'),
                    style: GoogleFonts.roboto(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isCreator
                          ? const Color(0xFFF472B6)
                          : GlassTheme.accentEmerald,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141419),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: Icon(
                    _showPassQr
                        ? Icons.qr_code_2_rounded
                        : Icons.badge_outlined,
                    color: isCreator
                        ? const Color(0xFFF472B6)
                        : GlassTheme.accentEmerald,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passCode,
                        style: GoogleFonts.robotoMono(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isCreator ? _store.userName : (participant?.name ?? _store.userName)} • ${isCreator ? "Event Master" : _store.getUserRoleForEvent(code).displayName}',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: GlassTheme.mutedSilver),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showPassQr
                        ? const Color(0xFF2E2E38)
                        : (isCreator
                            ? const Color(0xFFF472B6)
                            : GlassTheme.accentEmerald),
                    foregroundColor: _showPassQr ? Colors.white : Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: Icon(
                    _showPassQr
                        ? Icons.visibility_off_rounded
                        : Icons.qr_code_rounded,
                    size: 15,
                  ),
                  label: Text(
                    _showPassQr ? 'Hide QR' : 'Show QR',
                    style: GoogleFonts.roboto(
                        fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassQr = !_showPassQr;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_showPassQr) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCreator
                      ? const Color(0xFFF472B6).withValues(alpha: 0.3)
                      : GlassTheme.accentEmerald.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Scan for Gate Clearance & Event Validation',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: GlassTheme.mutedSilver),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10),
                      ],
                    ),
                    child: QrImageView(
                      data: passCode,
                      version: QrVersions.auto,
                      size: 140,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '📍 $venueName • Passcode: ${passcode.isNotEmpty ? passcode : "Open"}',
                    style:
                        GoogleFonts.roboto(fontSize: 11, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: GlassTheme.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: Text('Copy Pass',
                            style: GoogleFonts.roboto(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  'Pass ID: $passCode\nEvent: $title ($code)\nPasscode: $passcode\nVenue: $venueName'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('✓ Pass details copied!'),
                                backgroundColor: GlassTheme.accentEmerald),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      if (isCreator)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.mark_email_read_rounded,
                              size: 14),
                          label: Text('Email VIP Pass',
                              style: GoogleFonts.roboto(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                          onPressed: () =>
                              _showOwnerConfirmationEmailModal(event),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSection(Map<String, dynamic> event) {
    final sessions = _store.sessions;
    final liveSession = _store.currentLiveSession;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 18, color: GlassTheme.accentSky),
                  const SizedBox(width: 8),
                  Text(
                    'Master Schedule & Agendas (${sessions.length})',
                    style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 28)),
                    icon: const Icon(Icons.add_rounded,
                        size: 14, color: GlassTheme.accentSky),
                    label: Text('Add',
                        style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: GlassTheme.accentSky,
                            fontWeight: FontWeight.w700)),
                    onPressed: () => _showAddSessionDialog(event),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _tabController.animateTo(1),
                    child: Row(
                      children: [
                        Text('All Tracks',
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: GlassTheme.chrome,
                                fontWeight: FontWeight.w600)),
                        const Icon(Icons.chevron_right_rounded,
                            size: 14, color: GlassTheme.chrome),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (liveSession != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GlassTheme.accentEmerald),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record_rounded,
                      size: 10, color: GlassTheme.accentEmerald),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'HAPPENING NOW: ${liveSession.title} (${liveSession.room})',
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: GlassTheme.accentEmerald),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(liveSession.startTime,
                      style: GoogleFonts.roboto(
                          fontSize: 10.5, color: Colors.white70)),
                ],
              ),
            ),
          ],
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No timetable sessions scheduled yet. Tap "+ Add" to create tracks.',
                  style: GoogleFonts.roboto(
                      fontSize: 11.5, color: GlassTheme.mutedSilver),
                ),
              ),
            )
          else
            ...sessions.take(3).map((ses) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ses.isLiveNow
                        ? const Color(0xFF0F1E19)
                        : const Color(0xFF0F0F13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: ses.isLiveNow
                            ? GlassTheme.accentEmerald
                            : GlassTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(ses.startTime,
                            style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: GlassTheme.accentSky)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ses.title,
                                style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                            Text('${ses.speaker} • ${ses.room} • ${ses.track}',
                                style: GoogleFonts.roboto(
                                    fontSize: 10.5,
                                    color: GlassTheme.mutedSilver)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            _store.toggleSessionLive(ses.id, !ses.isLiveNow),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ses.isLiveNow
                                ? GlassTheme.accentEmerald
                                    .withValues(alpha: 0.2)
                                : const Color(0xFF141419),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: ses.isLiveNow
                                    ? GlassTheme.accentEmerald
                                    : GlassTheme.border),
                          ),
                          child: Text(
                            ses.isLiveNow ? 'LIVE' : 'Set Live',
                            style: GoogleFonts.roboto(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: ses.isLiveNow
                                    ? GlassTheme.accentEmerald
                                    : GlassTheme.mutedSilver),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          if (sessions.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text('View all ${sessions.length} sessions →',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: GlassTheme.accentSky)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVenueSection(Map<String, dynamic> event) {
    final venueName =
        extractEventVenue(event['venue'], fallback: 'Campus Main Arena');
    final address = event['address'] as String? ??
        '$venueName, University Campus, Pune 411038';
    final capacity = event['capacity'] as int? ?? 500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 18, color: GlassTheme.accentAmber),
                  const SizedBox(width: 8),
                  Text(
                    'Venue & Space Logistics',
                    style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _tabController.animateTo(3),
                child: Row(
                  children: [
                    Text('Full Layout',
                        style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: GlassTheme.accentSky,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded,
                        size: 14, color: GlassTheme.accentSky),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            venueName,
            style: GoogleFonts.roboto(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            address,
            style: GoogleFonts.roboto(
                fontSize: 11.5, color: GlassTheme.mutedSilver),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _metricMiniChip(Icons.people_alt_rounded, 'Capacity: $capacity+'),
              _metricMiniChip(Icons.domain_rounded, 'Indoor AC'),
              _metricMiniChip(Icons.wifi_rounded, '5G Wi-Fi'),
              _metricMiniChip(Icons.bolt_rounded, '100% DG Backup'),
              _metricMiniChip(Icons.videocam_rounded, '4K Projection'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationChannelSection(Map<String, dynamic> event) {
    final commsChannels = [
      {'id': 'all-ops', 'label': '#all-ops'},
      {'id': 'announcements', 'label': '#announcements'},
      {'id': 'security', 'label': '#security'},
      {'id': 'volunteers', 'label': '#volunteers'},
      {'id': 'stage-av', 'label': '#stage-av'},
    ];

    final allMessages = _store.chatMessages;
    final filteredMessages = _activeCommsChannel == 'all-ops'
        ? allMessages
        : allMessages
            .where((m) => (m['channel'] ?? 'all-ops') == _activeCommsChannel)
            .toList();
    final recentMessages = filteredMessages.length > 3
        ? filteredMessages.sublist(filteredMessages.length - 3)
        : filteredMessages;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.forum_rounded,
                      size: 18, color: GlassTheme.accentEmerald),
                  const SizedBox(width: 8),
                  Text(
                    'Communication Channel',
                    style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: GlassTheme.accentEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              GlassTheme.accentEmerald.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: GlassTheme.accentEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${filteredMessages.length} msgs',
                          style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: GlassTheme.accentEmerald),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _tabController.animateTo(4),
                child: Row(
                  children: [
                    Text('Full Channel',
                        style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: GlassTheme.accentSky,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded,
                        size: 14, color: GlassTheme.accentSky),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Channel selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: commsChannels.map((ch) {
                final isSelected = _activeCommsChannel == ch['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _activeCommsChannel = ch['id']!),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GlassTheme.accentEmerald.withValues(alpha: 0.18)
                            : const Color(0xFF141418),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? GlassTheme.accentEmerald
                              : GlassTheme.border,
                        ),
                      ),
                      child: Text(
                        ch['label']!,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : GlassTheme.mutedSilver,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Message Preview Feed
          if (recentMessages.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GlassTheme.subtleBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: GlassTheme.mutedSilver.withValues(alpha: 0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No messages in #$_activeCommsChannel yet. Dispatch a radio update below.',
                      style: GoogleFonts.roboto(
                          fontSize: 11.5, color: GlassTheme.mutedSilver),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: recentMessages.map((m) {
                final isMe = m['isMe'] == true;
                final sender = m['sender'] as String? ?? 'Squad';
                final role = m['role'] as String? ?? 'Team';
                final text = m['text'] as String? ?? '';
                final time = m['time'] as String? ?? 'Just now';
                final channel = m['channel'] as String? ?? 'all-ops';

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF132030)
                        : const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isMe
                            ? GlassTheme.accentSky.withValues(alpha: 0.4)
                            : GlassTheme.subtleBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: isMe
                            ? GlassTheme.accentSky
                            : GlassTheme.accentEmerald,
                        child: Text(
                          sender.isNotEmpty ? sender[0].toUpperCase() : 'S',
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(sender,
                                    style: GoogleFonts.roboto(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: GlassTheme.cardHover,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(role,
                                      style: GoogleFonts.roboto(
                                          fontSize: 9,
                                          color: GlassTheme.chrome)),
                                ),
                                const SizedBox(width: 4),
                                Text('#$channel',
                                    style: GoogleFonts.roboto(
                                        fontSize: 9,
                                        color: GlassTheme.accentEmerald)),
                                const Spacer(),
                                Text(time,
                                    style: GoogleFonts.roboto(
                                        fontSize: 9.5,
                                        color: GlassTheme.mutedSilver)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(text,
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    color: const Color(0xFFE2E8F0))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // Quick Composer Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0B0E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: TextField(
                    controller: _quickCommsCtrl,
                    style:
                        GoogleFonts.roboto(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Transmit update to #$_activeCommsChannel...',
                      hintStyle: GoogleFonts.roboto(
                          color: const Color(0xFF6B7280), fontSize: 11.5),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    onSubmitted: (_) {
                      final txt = _quickCommsCtrl.text.trim();
                      if (txt.isNotEmpty) {
                        _store.sendChatMessage(txt,
                            channel: _activeCommsChannel);
                        _quickCommsCtrl.clear();
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  final txt = _quickCommsCtrl.text.trim();
                  if (txt.isNotEmpty) {
                    _store.sendChatMessage(txt, channel: _activeCommsChannel);
                    _quickCommsCtrl.clear();
                    setState(() {});
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: GlassTheme.accentSky,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.send_rounded, size: 16, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Action Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.campaign_rounded,
                    size: 15, color: GlassTheme.accentAmber),
                label: Text('Broadcast Announcement',
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: GlassTheme.accentAmber,
                        fontWeight: FontWeight.w700)),
                onPressed: () => _showBroadcastAnnouncementDialog(event),
              ),
              InkWell(
                onTap: () => _tabController.animateTo(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Text('Open Comms Radio',
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: GlassTheme.accentSky,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 2),
                      const Icon(Icons.open_in_new_rounded,
                          size: 12, color: GlassTheme.accentSky),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailAndRemindersSection(Map<String, dynamic> event) {
    final isCreator =
        _store.getUserRoleForEvent(widget.eventCode) == EventRole.creator;
    final hasEmailAccess =
        isCreator || _store.hasEmailAutomationAccess(widget.eventCode);

    if (!hasEmailAccess) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF101015),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GlassTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: GlassTheme.mutedSilver, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Private Section: Email & Automated Reminders',
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Email automation & countdown alerts are restricted to the Event Creator. Contact your organizer for access.',
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: GlassTheme.mutedSilver,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final daysUntil = _store.daysUntilCurrentEvent;
    final reminders = _store.reminders;
    final totalParticipants = _store.participants.length;
    final volunteersCount = _store.participants
            .where((p) => p.participantType == ParticipantType.volunteer)
            .length +
        _store.squadMembers.length;
    final guestsCount = _store.participants
        .where((p) =>
            p.participantType == ParticipantType.guest ||
            p.participantType == ParticipantType.employee)
        .length;
    final vipsCount = _store.participants
        .where((p) =>
            p.participantType == ParticipantType.vip ||
            p.participantType == ParticipantType.speaker)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_read_rounded,
                      size: 18, color: GlassTheme.accentSky),
                  const SizedBox(width: 8),
                  Text(
                    'Email & Automated Reminders',
                    style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: GlassTheme.accentSky.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: GlassTheme.accentSky.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _store.currentEventCountdownLabel,
                      style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: GlassTheme.accentSky),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCreator) ...[
                    InkWell(
                      onTap: () =>
                          _showEmailAutomationAccessDelegationDialog(event),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B4B),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.vpn_key_rounded,
                                size: 11, color: Color(0xFFA5B4FC)),
                            const SizedBox(width: 4),
                            Text('Access',
                                style: GoogleFonts.roboto(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFA5B4FC))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: () => _showEmailReminderDispatcherDialog(event),
                    child: Row(
                      children: [
                        Text('New Reminder',
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: GlassTheme.accentEmerald,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 2),
                        const Icon(Icons.add_circle_outline_rounded,
                            size: 14, color: GlassTheme.accentEmerald),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dynamic Countdown Action Alert Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                Icon(
                  daysUntil == 1
                      ? Icons.bolt_rounded
                      : (daysUntil == 2
                          ? Icons.hourglass_top_rounded
                          : (daysUntil == 0
                              ? Icons.campaign_rounded
                              : Icons.calendar_today_rounded)),
                  size: 20,
                  color: daysUntil == 1
                      ? GlassTheme.accentAmber
                      : (daysUntil == 2
                          ? GlassTheme.accentSky
                          : GlassTheme.accentEmerald),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        daysUntil == 2
                            ? '⏰ 2 Days to Go: Send 48-Hour Briefing'
                            : (daysUntil == 1
                                ? '⚡ 1 Day to Go: Tomorrow is Execution Day!'
                                : (daysUntil == 0
                                    ? '🚨 Happening Today: Gates Are Open!'
                                    : 'Countdown Briefing Automation')),
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        daysUntil == 2
                            ? 'Ideal time to email venue check-in details to guests and duty rosters to volunteers.'
                            : (daysUntil == 1
                                ? 'Dispatch tomorrow\'s gate entry passes & final morning roll-call instructions.'
                                : (daysUntil == 0
                                    ? 'Broadcast live timetable, room allocations, and helpdesk contact to attendees.'
                                    : 'Schedule and dispatch 2-day, 1-day, or role-specific email alerts.')),
                        style: GoogleFonts.roboto(
                            fontSize: 10.5, color: GlassTheme.mutedSilver),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: daysUntil == 1
                            ? GlassTheme.accentAmber
                            : (daysUntil == 2
                                ? GlassTheme.accentSky
                                : Colors.white),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final targetMilestone = daysUntil == 2
                            ? ReminderMilestone.twoDaysToGo
                            : (daysUntil == 1
                                ? ReminderMilestone.oneDayToGo
                                : (daysUntil == 0
                                    ? ReminderMilestone.eventDay
                                    : ReminderMilestone.twoDaysToGo));
                        _showEmailReminderDispatcherDialog(event,
                            defaultMilestone: targetMilestone);
                      },
                      child: Text(
                        daysUntil == 2
                            ? 'Send T-2'
                            : (daysUntil == 1
                                ? 'Send T-1'
                                : (daysUntil == 0 ? 'Send Live' : 'Send')),
                        style: GoogleFonts.roboto(
                            fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final targetMilestone = daysUntil == 2
                            ? ReminderMilestone.twoDaysToGo
                            : (daysUntil == 1
                                ? ReminderMilestone.oneDayToGo
                                : (daysUntil == 0
                                    ? ReminderMilestone.eventDay
                                    : ReminderMilestone.twoDaysToGo));
                        final res = await _store.triggerAutomatedReminderToAll(
                          milestone: targetMilestone,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] as String? ??
                                  '✓ Automated reminder dispatched to all users!'),
                              backgroundColor: GlassTheme.accentEmerald,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: GlassTheme.border),
                        ),
                        child: Text(
                          '⚡ All Users',
                          style: GoogleFonts.roboto(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: GlassTheme.accentSky,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Role Target Shortcuts Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleReminderChip(
                  label: 'Guests ($guestsCount)',
                  icon: Icons.people_outline_rounded,
                  color: GlassTheme.accentSky,
                  onTap: () => _showEmailReminderDispatcherDialog(event,
                      defaultRole: ReminderTargetRole.guests),
                ),
                _buildRoleReminderChip(
                  label: 'Volunteers ($volunteersCount)',
                  icon: Icons.volunteer_activism_rounded,
                  color: GlassTheme.accentEmerald,
                  onTap: () => _showEmailReminderDispatcherDialog(event,
                      defaultRole: ReminderTargetRole.volunteers),
                ),
                _buildRoleReminderChip(
                  label: 'VIPs ($vipsCount)',
                  icon: Icons.star_outline_rounded,
                  color: GlassTheme.accentAmber,
                  onTap: () => _showEmailReminderDispatcherDialog(event,
                      defaultRole: ReminderTargetRole.vips),
                ),
                _buildRoleReminderChip(
                  label: 'All ($totalParticipants)',
                  icon: Icons.groups_rounded,
                  color: Colors.white,
                  onTap: () => _showEmailReminderDispatcherDialog(event,
                      defaultRole: ReminderTargetRole.all),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Recent Reminders Dispatch History
          if (reminders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GlassTheme.subtleBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline_rounded,
                      size: 18,
                      color: GlassTheme.mutedSilver.withValues(alpha: 0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No reminders dispatched yet. Tap above to send 1-day or 2-day briefings to your attendees & squad.',
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: GlassTheme.mutedSilver),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: reminders.take(2).map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.subtleBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(r.milestone.badge,
                            style: GoogleFonts.roboto(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: GlassTheme.accentSky)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(height: 1),
                            Text(
                                '${r.targetRole.label} • ${r.recipientCount} recipients',
                                style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: GlassTheme.mutedSilver)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✓ Automated reminder was dispatched to ${r.recipientCount} recipients (${r.targetRole.label})'),
                              backgroundColor: GlassTheme.accentEmerald,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14141A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: GlassTheme.border),
                          ),
                          child: const Icon(Icons.open_in_new_rounded,
                              size: 13, color: GlassTheme.accentSky),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleReminderChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF121216),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GlassTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmailReminderDispatcherDialog(
    Map<String, dynamic> event, {
    ReminderMilestone? defaultMilestone,
    ReminderTargetRole? defaultRole,
  }) {
    ReminderMilestone selectedMilestone = defaultMilestone ??
        (_store.daysUntilCurrentEvent == 1
            ? ReminderMilestone.oneDayToGo
            : ReminderMilestone.twoDaysToGo);
    ReminderTargetRole selectedRole = defaultRole ?? ReminderTargetRole.all;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final template = EventEmailService().generateReminderTemplate(
              event: event,
              milestone: selectedMilestone,
              targetRole: selectedRole,
              organizerName: _store.userName,
            );
            final targetRecipients =
                _store.getRecipientsForTargetRole(selectedRole);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mark_email_read_rounded,
                                size: 20, color: GlassTheme.accentSky),
                            const SizedBox(width: 8),
                            Text('Dispatch Event Reminder',
                                style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: GlassTheme.mutedSilver),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Send automated countdown briefings & access passes to guests, volunteers, or all attendees.',
                        style: GoogleFonts.roboto(
                            fontSize: 11.5, color: GlassTheme.mutedSilver)),
                    const SizedBox(height: 16),

                    // Milestone Selector
                    _fieldLabel('Countdown Milestone *'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ReminderMilestone.values.map((m) {
                          final isSel = selectedMilestone == m;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(m.title),
                              selected: isSel,
                              selectedColor:
                                  GlassTheme.accentSky.withValues(alpha: 0.25),
                              backgroundColor: const Color(0xFF141418),
                              labelStyle: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel
                                    ? Colors.white
                                    : GlassTheme.mutedSilver,
                              ),
                              side: BorderSide(
                                  color: isSel
                                      ? GlassTheme.accentSky
                                      : GlassTheme.border),
                              onSelected: (_) =>
                                  setModalState(() => selectedMilestone = m),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Target Role Selector
                    _fieldLabel('Target Audience *'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ReminderTargetRole.values.map((r) {
                          final isSel = selectedRole == r;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(r.label),
                              selected: isSel,
                              selectedColor: GlassTheme.accentEmerald
                                  .withValues(alpha: 0.25),
                              backgroundColor: const Color(0xFF141418),
                              labelStyle: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel
                                    ? Colors.white
                                    : GlassTheme.mutedSilver,
                              ),
                              side: BorderSide(
                                  color: isSel
                                      ? GlassTheme.accentEmerald
                                      : GlassTheme.border),
                              onSelected: (_) =>
                                  setModalState(() => selectedRole = r),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Target Recipients Info Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded,
                              size: 14, color: GlassTheme.accentSky),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recipients: ${targetRecipients.length} emails targeted (${targetRecipients.take(2).join(", ")}${targetRecipients.length > 2 ? " +${targetRecipients.length - 2} more" : ""})',
                              style: GoogleFonts.roboto(
                                  fontSize: 11, color: const Color(0xFF94A3B8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Preview Box
                    _fieldLabel('Generated Email Preview'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0B0E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GlassTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject: ${template.subject}',
                              style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const Divider(height: 14, color: Colors.white10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 140),
                            child: SingleChildScrollView(
                              child: Text(
                                template.plainText,
                                style: GoogleFonts.robotoMono(
                                    fontSize: 10.5,
                                    color: const Color(0xFFCBD5E1),
                                    height: 1.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons Row
                    // Primary Action: Automated Background Email Dispatch (No external popups)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.accentEmerald,
                          foregroundColor: Colors.black,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 20),
                        label: Text(
                          '⚡ Send Automated Reminder Now (${targetRecipients.length})',
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);

                          await _store.dispatchEventReminder(
                            milestone: selectedMilestone,
                            targetRole: selectedRole,
                            customRecipients: targetRecipients,
                          );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✓ Automated ${selectedMilestone.badge} reminder dispatched in background to ${targetRecipients.length} recipients!'),
                              backgroundColor: GlassTheme.accentEmerald,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Manual Email App Launcher (Optional Fallback)
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: GlassTheme.mutedSilver,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 12),
                        label: Text(
                          'Open draft in Gmail / Email App (Optional)',
                          style: GoogleFonts.roboto(
                              fontSize: 10.5, decoration: TextDecoration.underline),
                        ),
                        onPressed: () async {
                          final firstRecipient = targetRecipients.isNotEmpty
                              ? targetRecipients.first
                              : _store.userEmail;
                          final bccList = targetRecipients.length > 1
                              ? targetRecipients.skip(1).toList()
                              : null;
                          await EventEmailService().launchEmail(
                            recipientEmail: firstRecipient,
                            bcc: bccList,
                            subject: template.subject,
                            body: template.plainText,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Secondary actions: Copy & Test Email to Me
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: GlassTheme.border),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Copy Email Text',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text:
                                      'Subject: ${template.subject}\n\n${template.plainText}'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        '✓ Full reminder email copied to clipboard!'),
                                    backgroundColor: GlassTheme.accentEmerald),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GlassTheme.accentEmerald,
                              side: BorderSide(
                                  color: GlassTheme.accentEmerald
                                      .withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 14),
                            label: const Text('Test to My Email',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(ctx);
                              final myEmail = _store.userEmail.isNotEmpty
                                  ? _store.userEmail
                                  : 'tester@groundflow.app';

                              await EventEmailService().launchGmailWeb(
                                recipientEmail: myEmail,
                                subject: '[TEST PREVIEW] ${template.subject}',
                                body: template.plainText,
                              );

                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '✓ Test reminder opened for $myEmail!'),
                                    backgroundColor: GlassTheme.accentEmerald),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEmailAutomationAccessDelegationDialog(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141418),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final participants = _store.participants;
            final delegates = List<String>.from(
                (event['emailAutomationDelegates'] as List<dynamic>?)
                        ?.map((e) => e.toString().toLowerCase().trim()) ??
                    []);

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B4B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.vpn_key_rounded,
                            size: 20, color: Color(0xFFA5B4FC)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Automation Access Control',
                              style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                            Text(
                              'Grant or revoke private section access to team members & volunteers.',
                              style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  color: GlassTheme.mutedSilver),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: GlassTheme.border),
                  const SizedBox(height: 12),
                  if (participants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                            'No participants enrolled in this event roster yet.',
                            style: GoogleFonts.roboto(
                                color: GlassTheme.mutedSilver, fontSize: 12)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: participants.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (c, i) {
                          final p = participants[i];
                          final cleanEmail = p.email.toLowerCase().trim();
                          final isDelegate = delegates.contains(cleanEmail);
                          final isOwner = cleanEmail ==
                              (event['createdBy']
                                      ?.toString()
                                      .toLowerCase()
                                      .trim() ??
                                  '');

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: isDelegate
                                  ? const Color(0xFF1E1B4B)
                                  : const Color(0xFF222228),
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                    color: isDelegate
                                        ? const Color(0xFFA5B4FC)
                                        : Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(p.name,
                                    style: GoogleFonts.roboto(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                                const SizedBox(width: 6),
                                if (isOwner)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF3B1D28),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text('Owner',
                                        style: GoogleFonts.roboto(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFF472B6))),
                                  ),
                              ],
                            ),
                            subtitle: Text('${p.email} • ${p.assignedRole}',
                                style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: GlassTheme.mutedSilver)),
                            trailing: isOwner
                                ? const Text('Permanent',
                                    style: TextStyle(
                                        color: GlassTheme.accentEmerald,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600))
                                : Switch(
                                    value: isDelegate,
                                    activeColor: const Color(0xFFA5B4FC),
                                    activeTrackColor: const Color(0xFF4338CA),
                                    onChanged: (val) async {
                                      await _store.toggleEmailAutomationAccess(
                                        eventCode: widget.eventCode,
                                        targetEmail: cleanEmail,
                                        grant: val,
                                      );
                                      setSheetState(() {
                                        if (val) {
                                          delegates.add(cleanEmail);
                                        } else {
                                          delegates.remove(cleanEmail);
                                        }
                                        event['emailAutomationDelegates'] =
                                            delegates;
                                      });
                                      setState(() {});
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.white,
                          foregroundColor: Colors.black),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Done',
                          style:
                              GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScheduleTab(Map<String, dynamic> event) {
    final sessions = _store.sessions;
    final liveSession = _store.currentLiveSession;
    final isCreator =
        _store.getUserRoleForEvent(widget.eventCode) == EventRole.creator;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isCreator
          ? FloatingActionButton.extended(
              backgroundColor: GlassTheme.white,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add Session',
                  style: GoogleFonts.roboto(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              onPressed: () => _showAddSessionDialog(event),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GlassTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GlassTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                        'Total Sessions', '${sessions.length}', Colors.white),
                  ),
                  Container(width: 1, height: 32, color: GlassTheme.border),
                  Expanded(
                    child: _metricColumn(
                      'Live Now',
                      '${sessions.where((s) => s.isLiveNow).length}',
                      liveSession != null
                          ? GlassTheme.accentEmerald
                          : GlassTheme.mutedSilver,
                    ),
                  ),
                  Container(width: 1, height: 32, color: GlassTheme.border),
                  Expanded(
                    child: _metricColumn(
                      'Tracks',
                      '${sessions.map((s) => s.track).toSet().length}',
                      GlassTheme.accentSky,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (liveSession != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlassTheme.accentEmerald),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: GlassTheme.accentEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.black, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('LIVE OPERATIONAL SESSION',
                                  style: GoogleFonts.roboto(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: GlassTheme.accentEmerald)),
                              const SizedBox(width: 6),
                              Text(
                                  '• ${liveSession.startTime} – ${liveSession.endTime}',
                                  style: GoogleFonts.roboto(
                                      fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(liveSession.title,
                              style: GoogleFonts.roboto(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(
                              'Speaker: ${liveSession.speaker} • Room: ${liveSession.room}',
                              style: GoogleFonts.roboto(
                                  fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Master Event Timeline & Agendas',
                  style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded,
                      size: 14, color: GlassTheme.accentSky),
                  label: Text('New Session',
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: GlassTheme.accentSky,
                          fontWeight: FontWeight.w700)),
                  onPressed: () => _showAddSessionDialog(event),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: GlassTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GlassTheme.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          size: 40, color: GlassTheme.mutedSilver),
                      const SizedBox(height: 12),
                      Text('No Timetable Sessions Scheduled',
                          style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Provision agenda slots with time, room, speaker & track assignments.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                            fontSize: 11.5, color: GlassTheme.mutedSilver),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('Add First Session',
                            style: GoogleFonts.roboto(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () => _showAddSessionDialog(event),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...sessions.map((ses) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ses.isLiveNow
                          ? const Color(0xFF0F241D)
                          : GlassTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ses.isLiveNow
                            ? GlassTheme.accentEmerald
                            : GlassTheme.border,
                        width: ses.isLiveNow ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2838),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${ses.startTime} – ${ses.endTime}',
                                    style: GoogleFonts.roboto(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: GlassTheme.accentSky),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141419),
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: GlassTheme.border),
                                  ),
                                  child: Text(
                                    ses.track,
                                    style: GoogleFonts.roboto(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _store.toggleSessionLive(
                                  ses.id, !ses.isLiveNow),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ses.isLiveNow
                                      ? GlassTheme.accentEmerald
                                          .withValues(alpha: 0.2)
                                      : const Color(0xFF1C1C24),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: ses.isLiveNow
                                          ? GlassTheme.accentEmerald
                                          : GlassTheme.border),
                                ),
                                child: Text(
                                  ses.isLiveNow ? '● LIVE' : 'Set Live',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: ses.isLiveNow
                                        ? GlassTheme.accentEmerald
                                        : GlassTheme.mutedSilver,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ses.title,
                          style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 13, color: GlassTheme.accentAmber),
                            const SizedBox(width: 4),
                            Text(ses.speaker,
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5, color: Colors.white70)),
                            const SizedBox(width: 12),
                            const Icon(Icons.room_outlined,
                                size: 13, color: GlassTheme.accentSky),
                            const SizedBox(width: 4),
                            Text(ses.room,
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    color: GlassTheme.mutedSilver)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 16, color: GlassTheme.mutedSilver),
                              tooltip: 'Delete Session',
                              onPressed: () => _store.deleteSession(ses.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPassTab(Map<String, dynamic> event) {
    final code = widget.eventCode;
    final title = event['title'] as String? ?? widget.eventCode;
    final isCreator = _store.getUserRoleForEvent(code) == EventRole.creator;
    final participant = _findUserParticipant();
    final passCode = isCreator
        ? 'VIP-$code-OWNER'
        : (participant?.ticketPassCode ??
            'PASS-$code-${_store.userName.hashCode.abs().toString().substring(0, 4)}');
    final passcode =
        event['password'] as String? ?? event['passcode'] as String? ?? '';
    final venueName =
        extractEventVenue(event['venue'], fallback: 'Campus Main Arena');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCreator
                ? 'Owner VIP Pass & Credentials Backup'
                : 'Your Digital Event Pass & Gate Access',
            style: GoogleFonts.roboto(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            isCreator
                ? 'Master cryptographic pass for $code. Keep this badge to verify administration access.'
                : 'Present this QR ticket at campus entrance gates and attendance checkpoints.',
            style: GoogleFonts.roboto(
                fontSize: 11.5, color: GlassTheme.mutedSilver),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCreator
                    ? [
                        const Color(0xFF1E1B4B),
                        const Color(0xFF0F172A),
                        const Color(0xFF141419)
                      ]
                    : [
                        const Color(0xFF064E3B),
                        const Color(0xFF0C4A6E),
                        const Color(0xFF0F172A)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCreator
                    ? const Color(0xFFF472B6).withValues(alpha: 0.5)
                    : GlassTheme.accentEmerald.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCreator
                      ? const Color(0xFFF472B6).withValues(alpha: 0.1)
                      : GlassTheme.accentEmerald.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCreator
                        ? const Color(0xFF2E1065)
                        : const Color(0xFF065F46),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCreator
                                ? Icons.stars_rounded
                                : Icons.confirmation_number_rounded,
                            size: 16,
                            color: isCreator
                                ? const Color(0xFFF472B6)
                                : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCreator
                                ? 'VIP ORGANIZER ACCESS'
                                : 'OFFICIAL PARTICIPANT PASS',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          code,
                          style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 $venueName',
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: GlassTheme.mutedSilver),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          passCode,
                          style: GoogleFonts.robotoMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCreator
                                ? const Color(0xFFF472B6)
                                : GlassTheme.accentEmerald,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showPassQr
                              ? const Color(0xFF22222A)
                              : (isCreator
                                  ? const Color(0xFFF472B6)
                                  : GlassTheme.accentEmerald),
                          foregroundColor:
                              _showPassQr ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: Icon(
                            _showPassQr
                                ? Icons.visibility_off_rounded
                                : Icons.qr_code_rounded,
                            size: 15),
                        label: Text(
                          _showPassQr ? 'Hide QR Code' : 'Show QR Code Pass',
                          style: GoogleFonts.roboto(
                              fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassQr = !_showPassQr;
                          });
                        },
                      ),
                      if (_showPassQr) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: passCode,
                            version: QrVersions.auto,
                            size: 150,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            _passRow(
                                'Holder Name',
                                isCreator
                                    ? _store.userName
                                    : (participant?.name ?? _store.userName)),
                            const Divider(color: Colors.white10, height: 12),
                            _passRow(
                                'Email Address',
                                isCreator
                                    ? _store.userEmail
                                    : (participant?.email ?? _store.userEmail)),
                            const Divider(color: Colors.white10, height: 12),
                            _passRow(
                                'Designation',
                                isCreator
                                    ? 'Event Creator (Level 1)'
                                    : _store
                                        .getUserRoleForEvent(code)
                                        .displayName),
                            if (passcode.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 12),
                              _passRow('Event Passcode', passcode),
                            ],
                            const Divider(color: Colors.white10, height: 12),
                            _passRow(
                                'Gate Clearance',
                                isCreator
                                    ? 'UNRESTRICTED ALL-ACCESS'
                                    : (participant
                                            ?.attendanceStatus.displayName ??
                                        'Registered')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: GlassTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text('Copy Passcode',
                      style: GoogleFonts.roboto(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            'Pass Code: $passCode\nEvent: $title ($code)\nPasscode: $passcode\nVenue: $venueName'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('✓ Pass details copied!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              if (isCreator)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.mark_email_read_rounded, size: 16),
                    label: Text('Email Pass',
                        style: GoogleFonts.roboto(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: () => _showOwnerConfirmationEmailModal(event),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.accentEmerald,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: Text('Share Pass',
                        style: GoogleFonts.roboto(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text:
                              'My Event Ticket for $title ($code):\nTicket ID: $passCode\nVenue: $venueName'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✓ Ticket share link copied!'),
                            backgroundColor: GlassTheme.accentEmerald),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _passRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 11, color: GlassTheme.mutedSilver)),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildVenueTab(Map<String, dynamic> event) {
    final venueName =
        extractEventVenue(event['venue'], fallback: 'Campus Main Arena');
    final address = event['address'] as String? ??
        '$venueName, University Campus, Pune, Maharashtra 411038';
    final capacity = event['capacity'] as int? ?? 500;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GlassTheme.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.stadium_rounded,
                          color: GlassTheme.accentAmber, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GlassTheme.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: GlassTheme.accentEmerald
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text('RESERVED & OPERATIONAL',
                          style: GoogleFonts.roboto(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: GlassTheme.accentEmerald)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  venueName,
                  style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: GlassTheme.mutedSilver),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _metricMiniChip(
                        Icons.people_alt_rounded, 'Capacity: $capacity+'),
                    const SizedBox(width: 8),
                    _metricMiniChip(Icons.domain_rounded, 'Indoor AC'),
                    const SizedBox(width: 8),
                    _metricMiniChip(Icons.security_rounded, 'Security Active'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Designated Rooms & Space Allocation',
              style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 10),
          _venueRoomCard(
              '🏛️ Main Stage & Grand Auditorium',
              'Opening ceremony, keynote addresses, and master sessions',
              'Capacity: 350 seats'),
          _venueRoomCard(
              '💼 Seminar Hall 1 & Workshop Labs',
              'Department breakout sessions and hands-on tracks',
              'Capacity: 80 seats'),
          _venueRoomCard(
              '☕ VIP Green Room & Dignitary Suite',
              'Speaker hospitality, media interviews, and VIP holding area',
              'Restricted Access'),
          _venueRoomCard(
              '🛡️ Operations Command & Media Desk',
              'Sound engineering, camera feed switching, and incident desk',
              'Crew Only'),
          _venueRoomCard(
              '🎟️ Gates A & B Registration Concourse',
              'Rapid QR scanner checkpoints, badge issuance, and baggage check',
              'Public Entry'),
          const SizedBox(height: 20),
          Text('On-Site Facilities & Technical Amenities',
              style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _facilityBadge(Icons.wifi_rounded, 'High-Speed 5G Wi-Fi'),
              _facilityBadge(Icons.bolt_rounded, '100% DG Power Backup'),
              _facilityBadge(
                  Icons.videocam_rounded, '4K Projection & Video Walls'),
              _facilityBadge(Icons.mic_rounded, 'Wireless Line-Array Audio'),
              _facilityBadge(
                  Icons.medical_services_rounded, 'First Aid Station'),
              _facilityBadge(
                  Icons.local_parking_rounded, 'Reserved Parking Area'),
              _facilityBadge(Icons.accessible_rounded, 'Wheelchair Accessible'),
              _facilityBadge(
                  Icons.coffee_rounded, 'Cafeteria & Water Stations'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GlassTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Campus Navigation & Parking',
                        style: GoogleFonts.roboto(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          size: 16, color: GlassTheme.accentSky),
                      tooltip: 'Copy Address',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('✓ Venue address copied!'),
                              backgroundColor: GlassTheme.accentEmerald),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Main entrance via Campus Gate 2. Visitor and attendee parking is assigned at Parking Lot P3. Shuttles available from reception every 15 minutes.',
                  style: GoogleFonts.roboto(
                      fontSize: 11.5, color: GlassTheme.mutedSilver),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _metricMiniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _venueRoomCard(String title, String desc, String tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(desc,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: GlassTheme.mutedSilver)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(tag,
                style: GoogleFonts.roboto(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: GlassTheme.accentSky)),
          ),
        ],
      ),
    );
  }

  Widget _facilityBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GlassTheme.accentEmerald),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(EventIncidentModel inc) {
    Color sevBg = const Color(0xFF1E293B);
    Color sevFg = GlassTheme.accentSky;
    if (inc.severity == IncidentSeverity.critical) {
      sevBg = const Color(0xFF450A0A);
      sevFg = GlassTheme.statusRed;
    } else if (inc.severity == IncidentSeverity.high) {
      sevBg = const Color(0xFF451A03);
      sevFg = GlassTheme.accentAmber;
    }

    final isResolved = inc.status == IncidentStatus.resolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: inc.severity == IncidentSeverity.critical && !isResolved
                ? GlassTheme.statusRed
                : GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                        color: sevBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(inc.severity.displayName.toUpperCase(),
                        style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: sevFg)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1C1C24),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(inc.department,
                        style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isResolved
                      ? GlassTheme.accentEmerald.withValues(alpha: 0.15)
                      : (inc.status == IncidentStatus.escalated
                          ? GlassTheme.statusRed.withValues(alpha: 0.15)
                          : const Color(0xFF1E1E26)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inc.status.displayName,
                  style: GoogleFonts.roboto(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isResolved
                          ? GlassTheme.accentEmerald
                          : (inc.status == IncidentStatus.escalated
                              ? GlassTheme.statusRed
                              : GlassTheme.accentAmber)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(inc.title,
              style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          if (inc.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(inc.description,
                style: GoogleFonts.roboto(
                    fontSize: 11.5, color: GlassTheme.mutedSilver)),
          ],
          if (inc.resolutionNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF14141A),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('Resolution: "${inc.resolutionNotes}"',
                  style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: GlassTheme.accentEmerald)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reported by ${inc.reportedBy}',
                  style: GoogleFonts.roboto(
                      fontSize: 10.5, color: GlassTheme.chrome)),
              if (!isResolved) ...[
                Row(
                  children: [
                    if (inc.status != IncidentStatus.escalated)
                      TextButton(
                        style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        onPressed: () => _store.escalateIncident(inc.id),
                        child: const Text('Escalate to Head',
                            style: TextStyle(
                                color: GlassTheme.accentAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                      onPressed: () => _showResolveIncidentDialog(inc),
                      child: const Text('Resolve Ticket',
                          style: TextStyle(
                              color: GlassTheme.accentEmerald,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showReportIncidentDialog(Map<String, dynamic> event) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final departments = (event['departments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Operations', 'Security', 'Tech & AV', 'Logistics'];
    String selectedDept = departments.first;
    IncidentSeverity severity = IncidentSeverity.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report Operational Incident',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _fieldLabel('Incident Title *'),
              _textInput(titleCtrl, 'e.g. Stage 2 Wireless Mic Interference'),
              const SizedBox(height: 12),
              _fieldLabel('Severity Level *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<IncidentSeverity>(
                    dropdownColor: const Color(0xFF141418),
                    value: severity,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: IncidentSeverity.values
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s.displayName)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => severity = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Department *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF141418),
                    value: selectedDept,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedDept = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Description & Ground Details'),
              _textInput(
                  descCtrl, 'Location, frequency issue, immediate impact...'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.statusRed,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _store.logIncident(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      severity: severity,
                      department: selectedDept,
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content:
                              Text('✓ Incident ticket logged & broadcast!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Dispatch Incident Ticket',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResolveIncidentDialog(EventIncidentModel inc) {
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GlassTheme.border)),
        title: Text('Resolve Incident Ticket',
            style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket: ${inc.title}',
                style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 12),
            _fieldLabel('Resolution Summary & Corrective Action'),
            _textInput(notesCtrl,
                'e.g. Switched wireless mic channel from 540MHz to 580MHz.'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.accentEmerald,
                foregroundColor: Colors.black),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await _store.resolveIncident(
                incidentId: inc.id,
                resolutionNotes: notesCtrl.text.trim(),
              );
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('✓ Incident resolved!'),
                    backgroundColor: GlassTheme.accentEmerald),
              );
            },
            child: const Text('Mark Resolved',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAuditReportSheet(Map<String, dynamic> event) {
    final report = _store.generatePostEventReport(event);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: GlassTheme.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Executive Operations Audit',
                      style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: GlassTheme.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('LIVE AUDIT',
                        style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: GlassTheme.accentEmerald)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${report.eventTitle} (${report.eventId})',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: GlassTheme.mutedSilver)),
              const SizedBox(height: 20),

              // Executive Scorecard Matrix
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GlassTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _metricColumn(
                                'Turnout',
                                '${report.attendanceRate.toStringAsFixed(1)}%',
                                GlassTheme.accentSky)),
                        Expanded(
                            child: _metricColumn(
                                'Task Efficiency',
                                '${report.taskCompletionRate.toStringAsFixed(1)}%',
                                GlassTheme.accentEmerald)),
                        Expanded(
                            child: _metricColumn(
                                'Budget Var',
                                '₹${report.budgetVariance.toStringAsFixed(0)}',
                                report.budgetVariance >= 0
                                    ? Colors.white
                                    : GlassTheme.statusRed)),
                        Expanded(
                            child: _metricColumn(
                                'Incidents',
                                '${report.resolvedIncidents}/${report.totalIncidents}',
                                report.totalIncidents ==
                                        report.resolvedIncidents
                                    ? GlassTheme.accentEmerald
                                    : GlassTheme.accentAmber)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Formatted Report Markdown Preview
              Text('Comprehensive Audit Summary',
                  style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B0E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlassTheme.border),
                ),
                child: SelectableText(
                  report.generatedSummaryText,
                  style: GoogleFonts.robotoMono(
                      fontSize: 11.5,
                      color: const Color(0xFFCBD5E1),
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 20),

              // Copy to Clipboard Action
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text('Copy Audit Report to Clipboard',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: report.generatedSummaryText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              '✓ Full executive audit report copied to clipboard!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB: COMMUNICATION CHANNEL & SQUAD RADIO
  // ===========================================================================
  Widget _buildCommunicationChannelTab(Map<String, dynamic> event) {
    final isCreator =
        _store.getUserRoleForEvent(widget.eventCode) == EventRole.creator;
    final commsChannels = [
      {'id': 'all-ops', 'label': '#all-ops'},
      {'id': 'announcements', 'label': '#announcements'},
      {'id': 'security', 'label': '#security'},
      {'id': 'volunteers', 'label': '#volunteers'},
      {'id': 'stage-av', 'label': '#stage-av'},
    ];

    final allMessages = _store.chatMessages;
    final filteredMessages = _activeCommsChannel == 'all-ops'
        ? allMessages
        : allMessages
            .where((m) => (m['channel'] ?? 'all-ops') == _activeCommsChannel)
            .toList();

    final announcements = _store.announcements;

    return Column(
      children: [
        // Top Control Strip: Channels & Broadcast Action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F14),
            border: Border(bottom: BorderSide(color: GlassTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: commsChannels.map((ch) {
                      final isSelected = _activeCommsChannel == ch['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _activeCommsChannel = ch['id']!),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? GlassTheme.accentEmerald
                                      .withValues(alpha: 0.2)
                                  : const Color(0xFF16161C),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? GlassTheme.accentEmerald
                                    : GlassTheme.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ch['label']!,
                                  style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : GlassTheme.mutedSilver,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (isCreator) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.accentAmber,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.campaign_rounded, size: 14),
                  label: Text('Broadcast',
                      style: GoogleFonts.roboto(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: () => _showBroadcastAnnouncementDialog(event),
                ),
              ],
            ],
          ),
        ),

        // Pinned Live Announcement Banner (if any)
        if (announcements.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  announcements.first.urgency == AnnouncementUrgency.emergency
                      ? const Color(0xFF450A0A)
                      : const Color(0xFF1E293B),
              border:
                  const Border(bottom: BorderSide(color: GlassTheme.border)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  size: 16,
                  color: announcements.first.urgency ==
                          AnnouncementUrgency.emergency
                      ? GlassTheme.statusRed
                      : GlassTheme.accentAmber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${announcements.first.title}: ${announcements.first.message}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    announcements.first.audience.displayName,
                    style:
                        GoogleFonts.roboto(fontSize: 9, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

        // Message Feed
        Expanded(
          child: filteredMessages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141418),
                            shape: BoxShape.circle,
                            border: Border.all(color: GlassTheme.border),
                          ),
                          child: const Icon(Icons.forum_outlined,
                              size: 36, color: GlassTheme.accentSky),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No messages in #$_activeCommsChannel',
                          style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dispatch a radio update to squad leads, volunteers, or all ops below.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              fontSize: 12, color: GlassTheme.mutedSilver),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _commsScrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  itemCount: filteredMessages.length,
                  itemBuilder: (ctx, idx) {
                    final m = filteredMessages[idx];
                    final isMe = m['isMe'] == true;
                    final sender = m['sender'] as String? ?? 'Squad';
                    final role = m['role'] as String? ?? 'Team';
                    final text = m['text'] as String? ?? '';
                    final time = m['time'] as String? ?? 'Just now';
                    final channel = m['channel'] as String? ?? 'all-ops';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(ctx).size.width * 0.8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF132A46)
                                : const Color(0xFF15151B),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isMe
                                  ? const Radius.circular(12)
                                  : const Radius.circular(2),
                              bottomRight: isMe
                                  ? const Radius.circular(2)
                                  : const Radius.circular(12),
                            ),
                            border: Border.all(
                              color: isMe
                                  ? GlassTheme.accentSky.withValues(alpha: 0.5)
                                  : GlassTheme.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundColor: isMe
                                        ? GlassTheme.accentSky
                                        : GlassTheme.accentEmerald,
                                    child: Text(
                                      sender.isNotEmpty
                                          ? sender[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    sender,
                                    style: GoogleFonts.roboto(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: GlassTheme.cardHover,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(role,
                                        style: GoogleFonts.roboto(
                                            fontSize: 8.5,
                                            color: GlassTheme.chrome)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('#$channel',
                                      style: GoogleFonts.roboto(
                                          fontSize: 8.5,
                                          color: GlassTheme.accentEmerald)),
                                  const SizedBox(width: 8),
                                  Text(time,
                                      style: GoogleFonts.roboto(
                                          fontSize: 9,
                                          color: GlassTheme.mutedSilver)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                text,
                                style: GoogleFonts.roboto(
                                    fontSize: 12.5,
                                    color: Colors.white,
                                    height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Quick Ops Radio Dispatch Templates Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C10),
            border: Border(top: BorderSide(color: GlassTheme.subtleBorder)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickDispatchChip('🟢 Stage Sound OK'),
                _buildQuickDispatchChip('🚨 Gate Queue High'),
                _buildQuickDispatchChip('👤 VIP On-Site'),
                _buildQuickDispatchChip('💧 Restock Water & Badges'),
                _buildQuickDispatchChip('⚠️ Medical Assistance'),
              ],
            ),
          ),
        ),

        // Bottom Message Composer
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0E0E14),
            border: Border(top: BorderSide(color: GlassTheme.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181820),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: Text(
                    '#$_activeCommsChannel',
                    style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: GlassTheme.accentEmerald),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GlassTheme.border),
                    ),
                    child: TextField(
                      controller: _fullCommsCtrl,
                      style:
                          GoogleFonts.roboto(color: Colors.white, fontSize: 13),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText:
                            'Transmit operational dispatch to #$_activeCommsChannel...',
                        hintStyle: GoogleFonts.roboto(
                            color: const Color(0xFF6B7280), fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) {
                        final txt = _fullCommsCtrl.text.trim();
                        if (txt.isNotEmpty) {
                          _store.sendChatMessage(txt,
                              channel: _activeCommsChannel);
                          _fullCommsCtrl.clear();
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final txt = _fullCommsCtrl.text.trim();
                    if (txt.isNotEmpty) {
                      _store.sendChatMessage(txt, channel: _activeCommsChannel);
                      _fullCommsCtrl.clear();
                      setState(() {});
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: GlassTheme.accentSky,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.send_rounded,
                        size: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDispatchChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          _store.sendChatMessage(text, channel: _activeCommsChannel);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF181822),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GlassTheme.subtleBorder),
          ),
          child: Text(
            text,
            style: GoogleFonts.roboto(
                fontSize: 10,
                color: const Color(0xFFCBD5E1),
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: DEPARTMENTS & TEAMS HIERARCHY
  // ===========================================================================
  Widget _buildDepartmentsAndTeamsTab(Map<String, dynamic> event) {
    final teams = _store.teams;
    final departments = List<String>.from(event['departments'] ??
        ['Media', 'Security', 'Registration', 'Logistics']);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GlassTheme.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.group_add_rounded, size: 18),
        label: Text('Create Team',
            style: GoogleFonts.roboto(
                fontSize: 12.5, fontWeight: FontWeight.w700)),
        onPressed: () => _showCreateTeamDialog(departments),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Fields Engine Quick-Launch Banner
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10141D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E3A5F)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      size: 20, color: GlassTheme.accentSky),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Dynamic Custom Fields Engine (${_store.customFields.length})',
                            style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                            'Configure registration fields, attendee attributes & credentials.',
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: GlassTheme.mutedSilver)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GlassTheme.accentSky,
                      side: const BorderSide(color: GlassTheme.accentSky),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _showCustomFieldsManagementModal(event),
                    child: Text('Manage',
                        style: GoogleFonts.roboto(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            Text('Participating Departments (${departments.length})',
                style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: departments.map((d) {
                final teamCount = teams
                    .where((t) => t.department.toLowerCase() == d.toLowerCase())
                    .length;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141419),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.domain_rounded,
                          size: 14, color: GlassTheme.accentSky),
                      const SizedBox(width: 6),
                      Text(d,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('$teamCount teams',
                            style: GoogleFonts.roboto(
                                fontSize: 9.5, color: GlassTheme.mutedSilver)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Text('Working Teams & Squad Hubs (${teams.length})',
                style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 12),

            if (teams.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: GlassTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlassTheme.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined,
                          size: 36, color: GlassTheme.chrome),
                      const SizedBox(height: 8),
                      Text('No Teams Provisioned Yet',
                          style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                          'Click "Create Team" below to provision your first department squad.',
                          style: GoogleFonts.roboto(
                              fontSize: 11.5, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: teams.length,
                itemBuilder: (ctx, idx) {
                  final team = teams[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GlassTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GlassTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(team.name,
                                style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A24),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(team.department,
                                  style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: GlassTheme.accentSky)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          team.responsibilities.isNotEmpty
                              ? team.responsibilities
                              : 'General operational execution',
                          style: GoogleFonts.roboto(
                              fontSize: 11.5, color: GlassTheme.mutedSilver),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_pin_rounded,
                                size: 14, color: GlassTheme.accentAmber),
                            const SizedBox(width: 6),
                            Text('Lead: ${team.teamLeader}',
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const Spacer(),
                            const Icon(Icons.badge_outlined,
                                size: 14, color: GlassTheme.chrome),
                            const SizedBox(width: 4),
                            Text(
                                '${team.members.length + 1} / ${team.requiredHeadcount} Staff',
                                style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: GlassTheme.mutedSilver)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GlassTheme.accentSky,
                              side: const BorderSide(color: Color(0xFF1E3A5F)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.meeting_room_rounded,
                                size: 14),
                            label: Text('Enter Team Workspace Hub',
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700)),
                            onPressed: () =>
                                _showTeamWorkspaceModal(team, event),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog(List<String> departments) {
    final nameCtrl = TextEditingController();
    final leadCtrl = TextEditingController(text: _store.userName);
    final respCtrl = TextEditingController();
    String selectedDept =
        departments.isNotEmpty ? departments.first : 'Operations';

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
              Text('Provision Working Team',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _fieldLabel('Team Name *'),
              _textInput(nameCtrl, 'e.g. Stage AV Technicians'),
              const SizedBox(height: 12),
              _fieldLabel('Department *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF141418),
                    value: selectedDept,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedDept = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Team Leader *'),
              _textInput(leadCtrl, 'Leader full name'),
              const SizedBox(height: 12),
              _fieldLabel('Primary Responsibilities'),
              _textInput(respCtrl, 'Tasks, gear handling, zone monitoring...'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _store.createTeam(
                      name: nameCtrl.text.trim(),
                      department: selectedDept,
                      teamLeader: leadCtrl.text.trim(),
                      responsibilities: respCtrl.text.trim(),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('✓ Team provisioned!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Create Team in Cloud',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: AUTOMATED TASKS & OPERATIONAL WORKFLOWS
  // ===========================================================================
  Widget _buildTasksTab(Map<String, dynamic> event) {
    final isCreator =
        _store.getUserRoleForEvent(widget.eventCode) == EventRole.creator;
    final tasks = _store.tasks;
    final filtered = tasks.where((t) {
      if (_taskFilter == 'Assigned' && t.status != TaskStatus.assigned)
        return false;
      if (_taskFilter == 'In Progress' && t.status != TaskStatus.inProgress)
        return false;
      if (_taskFilter == 'Completed' && t.status != TaskStatus.completed)
        return false;
      if (_taskFilter == 'Blocked' && t.status != TaskStatus.blocked)
        return false;
      return true;
    }).toList();

    final departments = (event['departments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Operations', 'IT'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isCreator
          ? FloatingActionButton.extended(
              backgroundColor: GlassTheme.white,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: Text('New Task',
                  style: GoogleFonts.roboto(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              onPressed: () => _showCreateTaskDialog(event),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Automated Workflow Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GlassTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GlassTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Operational Automation Engine',
                          style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              GlassTheme.accentEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                            '${_store.completedTasksCount} / ${_store.totalTasksCount} Done',
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: GlassTheme.accentEmerald)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _store.tasksProgressRatio,
                      backgroundColor: const Color(0xFF1E1E26),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          GlassTheme.accentEmerald),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: GlassTheme.accentSky),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.auto_fix_high_rounded,
                              size: 16, color: GlassTheme.accentSky),
                          label: Text('Seed Template Tasks',
                              style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: GlassTheme.accentSky)),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final count = await _store.generateAutomatedTasks(
                              category: event['category'] as String? ??
                                  'Departmental',
                              departments: departments,
                            );
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '✓ Seeded $count automated operational tasks!'),
                                  backgroundColor: GlassTheme.accentEmerald),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Assigned',
                  'In Progress',
                  'Completed',
                  'Blocked'
                ].map((f) {
                  final isSelected = _taskFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f,
                          style: GoogleFonts.roboto(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.black
                                  : GlassTheme.mutedSilver)),
                      selected: isSelected,
                      selectedColor: Colors.white,
                      backgroundColor: const Color(0xFF101014),
                      side: BorderSide(
                          color: isSelected ? Colors.white : GlassTheme.border),
                      onSelected: (val) {
                        if (val) setState(() => _taskFilter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Tasks List
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    color: GlassTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassTheme.border)),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.task_alt_rounded,
                          size: 36, color: GlassTheme.mutedSilver),
                      const SizedBox(height: 10),
                      Text('No tasks match the filter.',
                          style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                          'Tap "Seed Template Tasks" above to auto-populate workflows.',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map((task) => _buildTaskCard(task)),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(EventTaskModel task) {
    Color statusBg = const Color(0xFF1E293B);
    Color statusFg = const Color(0xFF94A3B8);
    switch (task.status) {
      case TaskStatus.assigned:
        statusBg = const Color(0xFF1E293B);
        statusFg = GlassTheme.accentSky;
        break;
      case TaskStatus.inProgress:
        statusBg = const Color(0xFF451A03);
        statusFg = GlassTheme.accentAmber;
        break;
      case TaskStatus.completed:
        statusBg = const Color(0xFF064E3B);
        statusFg = GlassTheme.accentEmerald;
        break;
      case TaskStatus.blocked:
        statusBg = const Color(0xFF450A0A);
        statusFg = GlassTheme.statusRed;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E1E26),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(task.department,
                    style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
              InkWell(
                onTap: () {
                  final nextStatus = task.status == TaskStatus.assigned
                      ? TaskStatus.inProgress
                      : (task.status == TaskStatus.inProgress
                          ? TaskStatus.completed
                          : TaskStatus.assigned);
                  _store.updateTaskStatus(
                    taskId: task.id,
                    status: nextStatus,
                    progressPercentage: nextStatus == TaskStatus.completed
                        ? 100
                        : (nextStatus == TaskStatus.inProgress ? 50 : 0),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusFg.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(task.status.displayName,
                          style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: statusFg)),
                      const SizedBox(width: 4),
                      Icon(Icons.sync_alt_rounded, size: 10, color: statusFg),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.title,
              style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          if (task.checklist.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...task.checklist.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(
                          task.status == TaskStatus.completed
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 12,
                          color: task.status == TaskStatus.completed
                              ? GlassTheme.accentEmerald
                              : GlassTheme.mutedSilver),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(item,
                              style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: GlassTheme.mutedSilver))),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lead: ${task.assignedUser}',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: GlassTheme.mutedSilver)),
              IconButton(
                tooltip: 'Delete Task',
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Colors.grey),
                onPressed: () => _store.deleteTask(task.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(Map<String, dynamic> event) {
    final titleCtrl = TextEditingController();
    final leadCtrl = TextEditingController(text: _store.userName);
    final checklistCtrl = TextEditingController();
    final departments = (event['departments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Operations', 'IT', 'Security', 'Media'];
    String selectedDept = departments.first;
    String priority = 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Operational Task',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _fieldLabel('Task Title *'),
              _textInput(titleCtrl, 'e.g. Test backup generator switchover'),
              const SizedBox(height: 12),
              _fieldLabel('Department *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF141418),
                    value: selectedDept,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedDept = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Assigned Lead / Member'),
              _textInput(leadCtrl, 'Person in charge'),
              const SizedBox(height: 12),
              _fieldLabel('Checklist (Comma separated)'),
              _textInput(
                  checklistCtrl, 'e.g. Check fuel, Check battery, Test load'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final checkItems = checklistCtrl.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    await _store.createTask(
                      title: titleCtrl.text.trim(),
                      department: selectedDept,
                      assignedUser: leadCtrl.text.trim(),
                      priority: priority,
                      checklist: checkItems,
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('✓ Operational task created!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Create Task',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 4: APPROVALS & RESOURCE CONFLICT DETECTION
  // ===========================================================================
  Widget _buildApprovalsAndConflictsTab(Map<String, dynamic> event) {
    final approvals = _store.approvals;
    final resources = _store.resources;
    final conflict = _store.conflictResult;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GlassTheme.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
        label: Text('Reserve Resource',
            style: GoogleFonts.roboto(
                fontSize: 12.5, fontWeight: FontWeight.w700)),
        onPressed: () => _showReserveResourceDialog(event),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resource Conflict & Collision Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: conflict?.hasConflict == true
                    ? GlassTheme.statusRed.withValues(alpha: 0.15)
                    : GlassTheme.accentEmerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: conflict?.hasConflict == true
                        ? GlassTheme.statusRed
                        : GlassTheme.accentEmerald),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        conflict?.hasConflict == true
                            ? Icons.crisis_alert_rounded
                            : Icons.shield_rounded,
                        color: conflict?.hasConflict == true
                            ? GlassTheme.statusRed
                            : GlassTheme.accentEmerald,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conflict?.hasConflict == true
                            ? 'RESOURCE COLLISION ALERT'
                            : 'EXCLUSIVE SPACE & RESOURCE LOCK',
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: conflict?.hasConflict == true
                                ? GlassTheme.statusRed
                                : GlassTheme.accentEmerald),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Scan for collisions',
                        icon: const Icon(Icons.refresh_rounded,
                            size: 18, color: Colors.white),
                        onPressed: () => _store.checkResourceConflicts(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conflict?.hasConflict == true
                        ? conflict!.conflictDetails
                        : 'No overlapping event reservations found for venue "${extractEventVenue(event['venue'])}". Resources locked exclusively for ${widget.eventCode}.',
                    style:
                        GoogleFonts.roboto(fontSize: 11.5, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Approvals Workflow Chain
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Multi-Tier Governance & Approvals',
                    style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                if (approvals.isEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.bolt_rounded,
                        size: 14, color: GlassTheme.accentSky),
                    label: Text('Seed Chain',
                        style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: GlassTheme.accentSky,
                            fontWeight: FontWeight.w700)),
                    onPressed: () => _store.seedDefaultApprovals(),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (approvals.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: GlassTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassTheme.border)),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 32, color: GlassTheme.mutedSilver),
                      const SizedBox(height: 8),
                      Text('No approval chain initiated.',
                          style: GoogleFonts.roboto(
                              fontSize: 12.5, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                          'Tap "Seed Chain" to configure Department Head, Finance, and Security stages.',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
              )
            else
              ...approvals.map((app) => _buildApprovalStageCard(app)),

            const SizedBox(height: 24),

            // Reserved Resources & Equipment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Allocated Resources & Equipment (${resources.length})',
                    style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 10),

            if (resources.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: GlassTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassTheme.border)),
                child: Center(
                  child: Text('No external resources allocated yet.',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: GlassTheme.mutedSilver)),
                ),
              )
            else
              ...resources.map((res) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0F0F13),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GlassTheme.border)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1E1E26),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.inventory_2_rounded,
                              size: 16, color: GlassTheme.accentSky),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(res.resourceName,
                                  style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(
                                  '${res.resourceType} • Qty: ${res.quantity} • ${res.location}',
                                  style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: GlassTheme.mutedSilver)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: GlassTheme.accentEmerald
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('Locked',
                              style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: GlassTheme.accentEmerald)),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalStageCard(EventApprovalModel app) {
    Color bg = const Color(0xFF451A03);
    Color fg = GlassTheme.accentAmber;
    if (app.status == ApprovalDecision.approved) {
      bg = const Color(0xFF064E3B);
      fg = GlassTheme.accentEmerald;
    } else if (app.status == ApprovalDecision.rejected) {
      bg = const Color(0xFF450A0A);
      fg = GlassTheme.statusRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(app.approverRole,
                  style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: GlassTheme.mutedSilver)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(app.status.displayName,
                    style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: fg)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(app.stageName,
              style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text('Assigned Approver: ${app.approverEmail}',
              style:
                  GoogleFonts.roboto(fontSize: 11, color: GlassTheme.chrome)),
          if (app.comments.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF14141A),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('Remarks: "${app.comments}"',
                  style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70)),
            ),
          ],
          if (app.status == ApprovalDecision.pending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showApprovalReviewDialog(app),
                child: Text('Review & Cast Vote',
                    style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showApprovalReviewDialog(EventApprovalModel approval) {
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GlassTheme.border)),
        title: Text('Review: ${approval.stageName}',
            style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Approver: ${approval.approverRole} (${approval.approverEmail})',
                style: GoogleFonts.roboto(
                    fontSize: 12, color: GlassTheme.mutedSilver)),
            const SizedBox(height: 14),
            _fieldLabel('Audit Remarks / Review Notes'),
            _textInput(commentCtrl,
                'e.g. Budget verified and approved within limits.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await _store.submitApprovalDecision(
                approvalId: approval.id,
                decision: ApprovalDecision.rejected,
                comments: commentCtrl.text.trim(),
              );
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Stage rejected.'),
                    backgroundColor: GlassTheme.statusRed),
              );
            },
            child: const Text('Reject Stage',
                style: TextStyle(color: GlassTheme.statusRed)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.accentEmerald,
                foregroundColor: Colors.black),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await _store.submitApprovalDecision(
                approvalId: approval.id,
                decision: ApprovalDecision.approved,
                comments: commentCtrl.text.trim(),
              );
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('✓ Stage approved & signed off!'),
                    backgroundColor: GlassTheme.accentEmerald),
              );
            },
            child: const Text('Approve Stage',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showReserveResourceDialog(Map<String, dynamic> event) {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController(
        text: extractEventVenue(event['venue'], fallback: 'Main Stage'));
    final qtyCtrl = TextEditingController(text: '1');
    String resType = 'AudioVisual';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Allocate & Lock Resource',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _fieldLabel('Resource Name *'),
              _textInput(nameCtrl,
                  'e.g. 500-Seater Auditorium / 400W PA Audio System'),
              const SizedBox(height: 12),
              _fieldLabel('Resource Category *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF141418),
                    value: resType,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: [
                      'AudioVisual',
                      'Venue Space',
                      'Seating',
                      'Power Backup',
                      'Transport',
                      'Network'
                    ]
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => resType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Quantity'),
              _textInput(qtyCtrl, '1'),
              const SizedBox(height: 12),
              _fieldLabel('Location / Zone'),
              _textInput(locCtrl, 'Main Stage Zone A'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _store.reserveResource(
                      resourceName: nameCtrl.text.trim(),
                      resourceType: resType,
                      quantity: int.tryParse(qtyCtrl.text.trim()) ?? 1,
                      location: locCtrl.text.trim(),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('✓ Resource reserved and locked!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Reserve & Lock Resource',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 5: BUDGET & FINANCIAL EXPENSE LEDGER
  // ===========================================================================
  Widget _buildBudgetTab(Map<String, dynamic> event) {
    const double allocatedBudget = 250000.0;
    final totalSpend = _store.totalExpensesIncurred;
    final balance = allocatedBudget - totalSpend;
    final ratio = allocatedBudget > 0
        ? (totalSpend / allocatedBudget).clamp(0.0, 1.0)
        : 0.0;
    final isOverrun = totalSpend > allocatedBudget;
    final expenses = _store.expenses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GlassTheme.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_card_rounded, size: 18),
        label: Text('Log Expense',
            style: GoogleFonts.roboto(
                fontSize: 12.5, fontWeight: FontWeight.w700)),
        onPressed: () => _showAddExpenseDialog(event),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Summary KPI Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GlassTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        isOverrun ? GlassTheme.statusRed : GlassTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cost Center & Budget Tracking',
                          style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOverrun
                              ? GlassTheme.statusRed.withValues(alpha: 0.15)
                              : GlassTheme.accentEmerald
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOverrun ? 'OVERRUN DETECTED' : 'BUDGET ON TRACK',
                          style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isOverrun
                                  ? GlassTheme.statusRed
                                  : GlassTheme.accentEmerald),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _metricColumn(
                              'Allocated',
                              '₹${allocatedBudget.toStringAsFixed(0)}',
                              Colors.white)),
                      Expanded(
                          child: _metricColumn(
                              'Incurred',
                              '₹${totalSpend.toStringAsFixed(0)}',
                              isOverrun
                                  ? GlassTheme.statusRed
                                  : GlassTheme.accentSky)),
                      Expanded(
                          child: _metricColumn(
                              'Balance',
                              '₹${balance.toStringAsFixed(0)}',
                              balance >= 0
                                  ? GlassTheme.accentEmerald
                                  : GlassTheme.statusRed)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: const Color(0xFF1E1E26),
                      valueColor: AlwaysStoppedAnimation<Color>(isOverrun
                          ? GlassTheme.statusRed
                          : GlassTheme.accentSky),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Itemized Expenses
            Text('Itemized Expense Ledger (${expenses.length})',
                style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 10),

            if (expenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    color: GlassTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassTheme.border)),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          size: 36, color: GlassTheme.mutedSilver),
                      const SizedBox(height: 8),
                      Text('No expense records logged yet.',
                          style: GoogleFonts.roboto(
                              fontSize: 13, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                          'Tap "Log Expense" to record vendor invoices and line items.',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
              )
            else
              ...expenses.map((exp) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0F0F13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GlassTheme.border)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1C1C24),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.currency_rupee_rounded,
                              size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exp.title,
                                  style: GoogleFonts.roboto(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(
                                  '${exp.category} • ${exp.department} • Vendor: ${exp.vendor}',
                                  style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: GlassTheme.mutedSilver)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${exp.amount.toStringAsFixed(0)}',
                                style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: GlassTheme.accentEmerald
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(exp.paymentStatus,
                                  style: GoogleFonts.roboto(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: GlassTheme.accentEmerald)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.grey),
                          onPressed: () => _store.deleteExpenseItem(exp.id),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(Map<String, dynamic> event) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final departments = (event['departments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Operations', 'Catering', 'Media', 'Logistics'];
    String selectedDept = departments.first;
    String category = 'Logistics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log Operational Expense',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _fieldLabel('Expense Title *'),
              _textInput(titleCtrl, 'e.g. Stage LED Screen Rental'),
              const SizedBox(height: 12),
              _fieldLabel('Amount (₹) *'),
              _textInput(amountCtrl, '45000'),
              const SizedBox(height: 12),
              _fieldLabel('Category *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF141418),
                    value: category,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: [
                      'Logistics',
                      'Catering',
                      'Venue',
                      'Tech & AV',
                      'Marketing',
                      'Misc'
                    ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => category = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Department'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF141418),
                    value: selectedDept,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedDept = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Vendor / Supplier Name'),
              _textInput(vendorCtrl, 'Vendor name'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text.trim());
                    if (titleCtrl.text.trim().isEmpty || amt == null) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _store.addExpenseItem(
                      title: titleCtrl.text.trim(),
                      category: category,
                      department: selectedDept,
                      vendor: vendorCtrl.text.trim().isNotEmpty
                          ? vendorCtrl.text.trim()
                          : 'Internal',
                      amount: amt,
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content:
                              Text('✓ Expense logged in financial ledger!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Add to Ledger',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 6: INVITATIONS & QR PASSCODE ENGINE
  // ===========================================================================
  Widget _buildInvitationsTab(Map<String, dynamic> event) {
    final isCreator =
        _store.getUserRoleForEvent(widget.eventCode) == EventRole.creator;
    final links = _store.invitationLinks;
    final totalRedeemed = _store.totalRedemptionsCount;
    final activeCount = _store.activeInvitationLinksCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isCreator
          ? FloatingActionButton.extended(
              backgroundColor: GlassTheme.white,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: Text('Create Link',
                  style: GoogleFonts.roboto(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              onPressed: _showCreateInvitationLinkDialog,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Metric Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GlassTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GlassTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _metricColumn(
                          'Total Links', '${links.length}', Colors.white)),
                  Container(width: 1, height: 32, color: GlassTheme.border),
                  Expanded(
                      child: _metricColumn('Active Passes', '$activeCount',
                          GlassTheme.accentEmerald)),
                  Container(width: 1, height: 32, color: GlassTheme.border),
                  Expanded(
                      child: _metricColumn(
                          'Redeemed', '$totalRedeemed', GlassTheme.accentSky)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Cryptographic Invitation Links (${links.length})',
                style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(
                'Opaque tokens for general admission, VIP passes, and department access.',
                style: GoogleFonts.roboto(
                    fontSize: 11.5, color: GlassTheme.mutedSilver)),
            const SizedBox(height: 16),

            if (links.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: GlassTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassTheme.border)),
                child: Center(
                  child: Text(
                      'No invitation links generated yet. Click "Create Link" below.',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: GlassTheme.mutedSilver)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: links.length,
                itemBuilder: (ctx, idx) {
                  final link = links[idx];
                  final usageRatio = link.maxUses > 0
                      ? (link.currentUses / link.maxUses).clamp(0.0, 1.0)
                      : 0.0;
                  final usagePct = (usageRatio * 100).toInt();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GlassTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: link.isActive
                              ? GlassTheme.border
                              : GlassTheme.statusRed.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(link.name,
                                    style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(width: 8),
                                _statusPill(link.type.displayName,
                                    GlassTheme.accentSky),
                              ],
                            ),
                            InkWell(
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await _store.toggleInvitationLinkStatus(
                                    linkId: link.id, isActive: !link.isActive);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(link.isActive
                                        ? '✓ Link revoked.'
                                        : '✓ Link reactivated!'),
                                    backgroundColor: link.isActive
                                        ? GlassTheme.statusRed
                                        : GlassTheme.accentEmerald,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: link.isActive
                                      ? GlassTheme.accentEmerald
                                          .withValues(alpha: 0.15)
                                      : GlassTheme.statusRed
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: link.isActive
                                          ? GlassTheme.accentEmerald
                                              .withValues(alpha: 0.3)
                                          : GlassTheme.statusRed
                                              .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      link.isActive
                                          ? Icons.check_circle_rounded
                                          : Icons.block_rounded,
                                      size: 11,
                                      color: link.isActive
                                          ? GlassTheme.accentEmerald
                                          : GlassTheme.statusRed,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      link.isActive
                                          ? 'Active (Revoke)'
                                          : 'Revoked (Reopen)',
                                      style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: link.isActive
                                              ? GlassTheme.accentEmerald
                                              : GlassTheme.statusRed),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Token: ${link.token}',
                            style: GoogleFonts.robotoMono(
                                fontSize: 11, color: GlassTheme.accentSky)),
                        const SizedBox(height: 10),

                        // Usage Quota Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${link.currentUses} of ${link.maxUses} Redeemed',
                                style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: GlassTheme.mutedSilver)),
                            Text('$usagePct% Quota',
                                style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: usageRatio >= 0.9
                                        ? GlassTheme.accentAmber
                                        : Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: usageRatio,
                            minHeight: 4,
                            backgroundColor: const Color(0xFF22222A),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              usageRatio >= 0.9
                                  ? GlassTheme.accentAmber
                                  : GlassTheme.accentSky,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E2822),
                                foregroundColor: GlassTheme.accentEmerald,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                textStyle: GoogleFonts.roboto(
                                    fontSize: 11, fontWeight: FontWeight.w700),
                                side: BorderSide(
                                    color: GlassTheme.accentEmerald
                                        .withValues(alpha: 0.3)),
                              ),
                              icon: const Icon(Icons.share_rounded, size: 14),
                              label: const Text('WhatsApp Invite'),
                              onPressed: () {
                                final eventTitle = event['title'] as String? ??
                                    widget.eventCode;
                                final venue = extractEventVenue(event['venue'],
                                    fallback: 'Main Venue');
                                final date =
                                    event['date'] as String? ?? 'Upcoming';
                                final msg =
                                    '''🎟️ *GroundFlow Official Invitation*
You are invited to: *$eventTitle*
📍 Venue: $venue
📅 Date: $date
🔑 Pass Code: *${link.token}*
🔗 Access Portal: https://groundflow.app/invite/${link.token}''';
                                Clipboard.setData(ClipboardData(text: msg));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '✓ WhatsApp invite template copied! Ready to paste into chat or status.'),
                                    backgroundColor: GlassTheme.accentEmerald,
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Show QR Pass',
                              icon: const Icon(Icons.qr_code_2_rounded,
                                  size: 18, color: Colors.white),
                              onPressed: () =>
                                  _showQRModal(link.token, link.name),
                            ),
                            IconButton(
                              tooltip: 'Copy Invite Link',
                              icon: const Icon(Icons.copy_rounded,
                                  size: 16, color: GlassTheme.chrome),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text:
                                        'https://groundflow.app/invite/${link.token}'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          '✓ Invitation link copied to clipboard!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateInvitationLinkDialog() {
    final nameCtrl = TextEditingController(text: 'General Registration');
    InvitationLinkType selectedType = InvitationLinkType.general;
    int maxUses = 100;
    bool requireApproval = false;

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
              Text('Generate Cryptographic Link',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _fieldLabel('Link Name *'),
              _textInput(nameCtrl, 'e.g. VIP Delegation Pass'),
              const SizedBox(height: 12),
              _fieldLabel('Link Access Scope *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InvitationLinkType>(
                    dropdownColor: const Color(0xFF141418),
                    value: selectedType,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: InvitationLinkType.values
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.displayName)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Require Registration Approval',
                      style: GoogleFonts.roboto(
                          fontSize: 12.5, color: Colors.white)),
                  Switch(
                    value: requireApproval,
                    activeColor: GlassTheme.accentEmerald,
                    onChanged: (v) => setModalState(() => requireApproval = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _store.createInvitationLink(
                      name: nameCtrl.text.trim(),
                      type: selectedType,
                      maxUses: maxUses,
                      requiresApproval: requireApproval,
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('✓ Cryptographic link generated!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Generate & Activate Link',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRModal(String payload, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GlassTheme.border)),
        title: Text(title,
            style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(payload,
                style: GoogleFonts.robotoMono(
                    fontSize: 11, color: GlassTheme.accentSky)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Close', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 7: PARTICIPANTS DIRECTORY & GATE CHECK-IN TERMINAL
  // ===========================================================================
  Widget _buildParticipantsAndScannerTab(Map<String, dynamic> event) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          height: 38,
          decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GlassTheme.border)),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() => _participantSubMode = 0);
                    _pauseCameraIfActive();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _participantSubMode == 0
                          ? const Color(0xFF22222A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Directory (${_store.participants.length})',
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _participantSubMode == 0
                                ? Colors.white
                                : GlassTheme.mutedSilver)),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() => _participantSubMode = 1);
                    _startCameraIfAvailable();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _participantSubMode == 1
                          ? const Color(0xFF22222A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded,
                            size: 14, color: GlassTheme.accentEmerald),
                        const SizedBox(width: 6),
                        Text(
                            'Gate Scanner (${_store.checkedInParticipantsCount})',
                            style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _participantSubMode == 1
                                    ? Colors.white
                                    : GlassTheme.mutedSilver)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _participantSubMode == 0
              ? _buildParticipantsTab(event)
              : _buildCheckInScannerTab(event),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 7 SUB-VIEW: PARTICIPANTS & REGISTRATION DIRECTORY
  // ===========================================================================
  Widget _buildParticipantsTab(Map<String, dynamic> event) {
    final isCreator =
        _store.getUserRoleForEvent(widget.eventCode) == EventRole.creator;
    final participants = _store.participants;
    final filtered = participants.where((p) {
      if (_selectedFilter == 'Pending' &&
          p.registrationStatus != RegistrationStatus.pending) return false;
      if (_selectedFilter == 'Confirmed' &&
          p.registrationStatus != RegistrationStatus.approved) return false;
      if (_selectedFilter == 'Checked In' &&
          p.attendanceStatus != AttendanceStatus.checkedIn) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.email.toLowerCase().contains(q) ||
            p.department.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isCreator
          ? FloatingActionButton.extended(
              backgroundColor: GlassTheme.white,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text('Add Participant',
                  style: GoogleFonts.roboto(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              onPressed: _showAddParticipantDialog,
            )
          : null,
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                      color: const Color(0xFF0F0F13),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GlassTheme.border)),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style:
                        GoogleFonts.roboto(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Search participants by name, email, department...',
                      hintStyle: GoogleFonts.roboto(
                          color: const Color(0xFF52525B), fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 16, color: GlassTheme.chrome),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'All',
                            'Confirmed',
                            'Pending',
                            'Checked In'
                          ].map((f) {
                            final isSelected = _selectedFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: isSelected,
                                showCheckmark: false,
                                backgroundColor: const Color(0xFF101014),
                                selectedColor: GlassTheme.white,
                                label: Text(f,
                                    style: GoogleFonts.roboto(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.black
                                            : GlassTheme.mutedSilver)),
                                onSelected: (_) =>
                                    setState(() => _selectedFilter = f),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                side: BorderSide(
                                    color: isSelected
                                        ? Colors.white
                                        : GlassTheme.border),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Export Attendee Ledger (CSV)',
                      icon: const Icon(Icons.file_download_rounded,
                          color: GlassTheme.accentSky, size: 20),
                      onPressed: () {
                        final csv = _store.exportParticipantsCSV(event);
                        Clipboard.setData(ClipboardData(text: csv));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '✓ Full attendee ledger exported & copied to clipboard (CSV)!'),
                            backgroundColor: GlassTheme.accentEmerald,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Participants List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No participants match your search criteria.',
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: GlassTheme.mutedSilver)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final p = filtered[idx];
                      final isCheckedIn =
                          p.attendanceStatus == AttendanceStatus.checkedIn;

                      return InkWell(
                        onTap: () => _showParticipantProfileSheet(p),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: GlassTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: GlassTheme.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF1E1E28),
                                child: Text(
                                  p.name.isNotEmpty
                                      ? p.name[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(p.name,
                                              style: GoogleFonts.roboto(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 6),
                                        _statusPill(
                                            p.participantType.displayName,
                                            GlassTheme.accentSky),
                                        const SizedBox(width: 4),
                                        _statusPill(
                                            isCheckedIn
                                                ? 'Checked In'
                                                : 'Not Attended',
                                            isCheckedIn
                                                ? GlassTheme.accentEmerald
                                                : const Color(0xFF64748B)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${p.email} • ${p.department}',
                                        style: GoogleFonts.roboto(
                                            fontSize: 11,
                                            color: GlassTheme.mutedSilver)),
                                  ],
                                ),
                              ),
                              if (p.registrationStatus ==
                                  RegistrationStatus.pending) ...[
                                IconButton(
                                  icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: GlassTheme.accentEmerald,
                                      size: 20),
                                  onPressed: () =>
                                      _store.updateParticipantRegistration(
                                          participantId: p.id,
                                          status: RegistrationStatus.approved),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.highlight_off_rounded,
                                      color: GlassTheme.statusRed, size: 20),
                                  onPressed: () =>
                                      _store.updateParticipantRegistration(
                                          participantId: p.id,
                                          status: RegistrationStatus.rejected),
                                ),
                              ] else ...[
                                // Manual Admit / Checkout Toggle
                                InkWell(
                                  onTap: () =>
                                      _store.toggleParticipantAttendance(
                                    participantId: p.id,
                                    status: isCheckedIn
                                        ? AttendanceStatus.notAttended
                                        : AttendanceStatus.checkedIn,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCheckedIn
                                          ? GlassTheme.statusRed
                                              .withValues(alpha: 0.12)
                                          : GlassTheme.accentEmerald
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isCheckedIn
                                            ? GlassTheme.statusRed
                                                .withValues(alpha: 0.3)
                                            : GlassTheme.accentEmerald
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      isCheckedIn ? 'Check Out' : 'Admit',
                                      style: GoogleFonts.roboto(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isCheckedIn
                                            ? GlassTheme.statusRed
                                            : GlassTheme.accentEmerald,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'View Ticket QR',
                                  icon: const Icon(Icons.qr_code_rounded,
                                      size: 18, color: Colors.white),
                                  onPressed: () => _showQRModal(
                                      p.ticketPassCode,
                                      '${p.name} — Ticket Pass'),
                                ),
                              ],
                            ],
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

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: GoogleFonts.roboto(
              fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _showAddParticipantDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'General Operations');
    ParticipantType pType = ParticipantType.employee;

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
              Text('Register Participant',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _fieldLabel('Full Name *'),
              _textInput(nameCtrl, 'Participant name'),
              const SizedBox(height: 12),
              _fieldLabel('Email Address *'),
              _textInput(emailCtrl, 'e.g. name@campus.edu'),
              const SizedBox(height: 12),
              _fieldLabel('Department'),
              _textInput(deptCtrl, 'e.g. Media / Security'),
              const SizedBox(height: 12),
              _fieldLabel('Participant Category'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ParticipantType>(
                    dropdownColor: const Color(0xFF141418),
                    value: pType,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: ParticipantType.values
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.displayName)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => pType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        !emailCtrl.text.contains('@')) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _store.addParticipant(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      department: deptCtrl.text.trim(),
                      participantType: pType,
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content:
                              Text('✓ Participant registered with QR ticket!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Register & Issue Pass',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 5: GATE ENTRANCE SCANNER & FAST CHECK-IN
  // ===========================================================================
  Widget _buildCheckInScannerTab(Map<String, dynamic> event) {
    final confirmed = _store.confirmedParticipantsCount;
    final checkedIn = _store.checkedInParticipantsCount;
    final capacity = (event['venueCapacity'] as num?)?.toInt() ??
        (event['expectedHeadcount'] as num?)?.toInt() ??
        100;
    final occupancyRatio =
        capacity > 0 ? (checkedIn / capacity).clamp(0.0, 1.0) : 0.0;
    final occupancyPct = (occupancyRatio * 100).toInt();
    final recentArrivals = _store.recentArrivals.take(6).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gate Stats Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: GlassTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricColumn('Confirmed', '$confirmed', Colors.white),
                _metricColumn(
                    'Checked In', '$checkedIn', GlassTheme.accentEmerald),
                _metricColumn('Remaining', '${confirmed - checkedIn}',
                    GlassTheme.accentAmber),
                _metricColumn('Capacity', '$capacity', GlassTheme.accentSky),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Occupancy Dial & Threshold Alert
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: occupancyRatio >= 0.95
                  ? GlassTheme.statusRed.withValues(alpha: 0.12)
                  : (occupancyRatio >= 0.80
                      ? GlassTheme.accentAmber.withValues(alpha: 0.12)
                      : const Color(0xFF0F1512)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: occupancyRatio >= 0.95
                    ? GlassTheme.statusRed.withValues(alpha: 0.4)
                    : (occupancyRatio >= 0.80
                        ? GlassTheme.accentAmber.withValues(alpha: 0.4)
                        : GlassTheme.accentEmerald.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          occupancyRatio >= 0.95
                              ? Icons.warning_amber_rounded
                              : (occupancyRatio >= 0.80
                                  ? Icons.info_outline_rounded
                                  : Icons.sensors_rounded),
                          size: 16,
                          color: occupancyRatio >= 0.95
                              ? GlassTheme.statusRed
                              : (occupancyRatio >= 0.80
                                  ? GlassTheme.accentAmber
                                  : GlassTheme.accentEmerald),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          occupancyRatio >= 0.95
                              ? '🚨 CRITICAL CAPACITY WARNING'
                              : (occupancyRatio >= 0.80
                                  ? '⚠️ High Venue Load Warning'
                                  : '✓ Live Floor Capacity Gauge'),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: occupancyRatio >= 0.95
                                ? GlassTheme.statusRed
                                : (occupancyRatio >= 0.80
                                    ? GlassTheme.accentAmber
                                    : GlassTheme.accentEmerald),
                          ),
                        ),
                      ],
                    ),
                    Text('$occupancyPct% Full ($checkedIn/$capacity)',
                        style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: occupancyRatio,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF1E1E26),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      occupancyRatio >= 0.95
                          ? GlassTheme.statusRed
                          : (occupancyRatio >= 0.80
                              ? GlassTheme.accentAmber
                              : GlassTheme.accentEmerald),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Camera QR Viewfinder & Fast Check-In Terminal
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Camera Header Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCameraActive
                                  ? GlassTheme.accentEmerald
                                  : Colors.grey,
                              boxShadow: _isCameraActive
                                  ? [
                                      BoxShadow(
                                        color: GlassTheme.accentEmerald
                                            .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isDesktop
                                ? 'GATE SCANNER (DESKTOP MODE)'
                                : (_isCameraActive
                                    ? 'LIVE CAMERA SCANNER'
                                    : 'CAMERA PAUSED'),
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _isDesktop
                                  ? GlassTheme.accentSky
                                  : (_isCameraActive
                                      ? GlassTheme.accentEmerald
                                      : GlassTheme.mutedSilver),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (!_isDesktop) ...[
                            // Restart / Refresh Camera Hardware
                            IconButton(
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: GlassTheme.chrome,
                              ),
                              tooltip: 'Restart Camera Hardware',
                              onPressed: _restartCamera,
                              visualDensity: VisualDensity.compact,
                            ),
                            // Torch Toggle
                            IconButton(
                              icon: Icon(
                                _isFlashOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                size: 18,
                                color: _isFlashOn
                                    ? GlassTheme.accentAmber
                                    : GlassTheme.chrome,
                              ),
                              tooltip: 'Toggle Flashlight',
                              onPressed: () {
                                _cameraController?.toggleTorch();
                                setState(() => _isFlashOn = !_isFlashOn);
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            // Camera Switch (Front/Back)
                            IconButton(
                              icon: Icon(
                                Icons.flip_camera_ios_rounded,
                                size: 18,
                                color: _isFrontCamera
                                    ? GlassTheme.accentSky
                                    : GlassTheme.chrome,
                              ),
                              tooltip: 'Switch Camera',
                              onPressed: () {
                                _cameraController?.switchCamera();
                                setState(() => _isFrontCamera = !_isFrontCamera);
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            // Toggle On/Off
                            IconButton(
                              icon: Icon(
                                _isCameraActive
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                size: 18,
                                color: _isCameraActive
                                    ? Colors.white
                                    : GlassTheme.statusRed,
                              ),
                              tooltip: 'Toggle Viewfinder',
                              onPressed: () {
                                if (_isCameraActive) {
                                  _cameraController?.stop();
                                } else {
                                  _cameraController?.start();
                                }
                                setState(() => _isCameraActive = !_isCameraActive);
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ] else ...[
                            // Desktop Mode Status Pill & Reset
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: GlassTheme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.computer_rounded, size: 12, color: GlassTheme.accentSky),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Desktop Active',
                                    style: GoogleFonts.roboto(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: GlassTheme.accentSky,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18, color: GlassTheme.chrome),
                              tooltip: 'Reset Input',
                              onPressed: () {
                                setState(() {
                                  _scanCtrl.clear();
                                  _lastScanResult = null;
                                });
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Viewfinder Screen
                if (_isCameraActive)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    child: Container(
                      height: 220,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Live Device Camera Feed (Mobile / Web) or Desktop Ops Viewport
                          if (!_isDesktop)
                            Positioned.fill(
                              child: MobileScanner(
                                controller: _cameraController,
                                fit: BoxFit.cover,
                                onDetect: (BarcodeCapture capture) {
                                  final barcodes = capture.barcodes;
                                  for (final barcode in barcodes) {
                                    final rawValue = barcode.rawValue ?? barcode.displayValue;
                                    if (rawValue != null && rawValue.trim().isNotEmpty) {
                                      final now = DateTime.now();
                                      if (_lastScanTime == null ||
                                          now.difference(_lastScanTime!).inMilliseconds > 1500) {
                                        _lastScanTime = now;
                                        HapticFeedback.mediumImpact();
                                        _handlePassScan(rawValue);
                                        break;
                                      }
                                    }
                                  }
                                },
                                errorBuilder: (context, error, child) {
                                  final isPermission = error.errorCode == MobileScannerErrorCode.permissionDenied;
                                  return Container(
                                    color: const Color(0xFF0D0F14),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPermission
                                              ? Icons.no_photography_rounded
                                              : Icons.videocam_off_rounded,
                                          size: 32,
                                          color: isPermission ? GlassTheme.statusRed : GlassTheme.accentSky,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isPermission
                                              ? 'Camera Permission Needed'
                                              : 'Live Camera Offline / Sensor Busy',
                                          style: GoogleFonts.roboto(
                                              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isPermission
                                              ? 'Enable camera permission in device settings or enter pass code below.'
                                              : 'Camera sensor unavailable. Tap retry or use manual pass code below.',
                                          style: GoogleFonts.roboto(fontSize: 10.5, color: GlassTheme.mutedSilver),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                visualDensity: VisualDensity.compact,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: _restartCamera,
                                              icon: const Icon(Icons.refresh_rounded, size: 12),
                                              label: Text('Retry Camera', style: GoogleFonts.roboto(fontSize: 10.5, fontWeight: FontWeight.w700)),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: GlassTheme.accentSky,
                                                side: const BorderSide(color: GlassTheme.border),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                visualDensity: VisualDensity.compact,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: () {
                                                if (_store.participants.isNotEmpty) {
                                                  _handlePassScan(_store.participants.first.ticketPassCode);
                                                } else {
                                                  _handlePassScan('VIP-${widget.eventCode}-OWNER');
                                                }
                                              },
                                              child: Text('Test Pass', style: GoogleFonts.roboto(fontSize: 10.5, fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            // Desktop Ops Station Viewport
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.9,
                                    colors: [
                                      Color(0xFF0F172A),
                                      Color(0xFF07080D),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Subtle darkening overlay for futuristic HUD aesthetic
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                          ),

                          // Grid texture lines
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.12,
                              child: CustomPaint(
                                painter: _ScannerGridPainter(),
                              ),
                            ),
                          ),

                          // Reticle Frame
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: GlassTheme.accentSky
                                    .withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                // Corner 1: Top-Left
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                            color: GlassTheme.accentEmerald,
                                            width: 3),
                                        left: BorderSide(
                                            color: GlassTheme.accentEmerald,
                                            width: 3),
                                      ),
                                    ),
                                  ),
                                ),
                                // Corner 2: Top-Right
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                            color: GlassTheme.accentEmerald,
                                            width: 3),
                                        right: BorderSide(
                                            color: GlassTheme.accentEmerald,
                                            width: 3),
                                      ),
                                    ),
                                  ),
                                ),
                                // Corner 3: Bottom-Left
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: GlassTheme.accentEmerald,
                                            width: 3),
                                        left: BorderSide(
                                            color: GlassTheme.accentEmerald,
                                            width: 3),
                                      ),
                                    ),
                                  ),
                                ),
                                // Corner 4: Bottom-Right
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: GlassTheme.accentEmerald,
                                            width: 3),
                                        right: BorderSide(
                                            color: GlassTheme.accentEmerald,
                                            width: 3),
                                      ),
                                    ),
                                  ),
                                ),

                                // Center Target Indicator
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 40,
                                        color: GlassTheme.accentSky.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _isDesktop ? 'DESKTOP OPS SCANNER' : 'ALIGN QR PASS',
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(alpha: 0.85),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      if (_isDesktop) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Enter code or tap attendee below',
                                          style: GoogleFonts.roboto(
                                            fontSize: 8.5,
                                            color: GlassTheme.mutedSilver,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Animated Scanning Laser Line
                                AnimatedBuilder(
                                  animation: _scannerAnimCtrl,
                                  builder: (context, _) {
                                    return Positioned(
                                      top: 10 + (_scannerAnimCtrl.value * 145),
                                      left: 6,
                                      right: 6,
                                      child: Container(
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          color: GlassTheme.accentEmerald,
                                          boxShadow: [
                                            BoxShadow(
                                              color: GlassTheme.accentEmerald
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Flashlight active indicator
                          if (_isFlashOn)
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'TORCH ON',
                                  style: GoogleFonts.robotoMono(
                                      fontSize: 8.5,
                                      color: GlassTheme.accentAmber,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      'Camera is paused. Tap the camera icon above to activate viewfinder.',
                      style: GoogleFonts.roboto(
                          color: GlassTheme.mutedSilver, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fast Camera Pass Simulator Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isDesktop
                    ? '1-Tap Attendee Check-In & Passes'
                    : 'Live Pass Detection Simulator',
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              Text(
                _isDesktop
                    ? 'Tap any pass to admit instantly'
                    : 'Tap to simulate camera scan',
                style: GoogleFonts.roboto(
                    fontSize: 10.5, color: GlassTheme.mutedSilver),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCameraScanSimChip(
                  label: '👑 Creator VIP Pass',
                  code: 'VIP-${widget.eventCode}-OWNER',
                  color: const Color(0xFFF472B6),
                ),
                ..._store.participants
                    .take(15)
                    .map((p) => _buildCameraScanSimChip(
                          label:
                              '🎟️ ${p.name} (${p.participantType.displayName})',
                          code: p.ticketPassCode,
                          color:
                              p.attendanceStatus == AttendanceStatus.checkedIn
                                  ? GlassTheme.mutedSilver
                                  : GlassTheme.accentEmerald,
                          isCheckedIn:
                              p.attendanceStatus == AttendanceStatus.checkedIn,
                        )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Manual Entry Input Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _scanCtrl,
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Scan or paste ticket code (e.g. GF-...)',
                    hintStyle: GoogleFonts.roboto(
                        color: const Color(0xFF52525B), fontSize: 13),
                    prefixIcon: const Icon(Icons.qr_code_scanner_rounded,
                        color: GlassTheme.accentSky),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (code) => _handlePassScan(code),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: GlassTheme.white,
                              foregroundColor: Colors.black),
                          onPressed: () => _handlePassScan(_scanCtrl.text),
                          child: Text('Verify & Check In Participant',
                              style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GlassTheme.border),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.paste_rounded, size: 20, color: GlassTheme.accentSky),
                        tooltip: 'Paste from Clipboard & Verify',
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          final text = data?.text?.trim() ?? '';
                          if (text.isNotEmpty) {
                            _scanCtrl.text = text;
                            _handlePassScan(text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Clipboard is empty! Copy a pass code (e.g. GF-...) first.'),
                                backgroundColor: Color(0xFF1E293B),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scan Result Clearance Feedback Banner
          if (_lastScanResult != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lastScanResult!['success'] == true
                    ? const Color(0xFF064E3B).withValues(alpha: 0.7)
                    : (_lastScanResult!['duplicate'] == true
                        ? const Color(0xFF451A03).withValues(alpha: 0.7)
                        : const Color(0xFF450A0A).withValues(alpha: 0.7)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _lastScanResult!['success'] == true
                      ? GlassTheme.accentEmerald
                      : (_lastScanResult!['duplicate'] == true
                          ? GlassTheme.accentAmber
                          : GlassTheme.statusRed),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lastScanResult!['success'] == true
                              ? GlassTheme.accentEmerald
                              : (_lastScanResult!['duplicate'] == true
                                  ? GlassTheme.accentAmber
                                  : GlassTheme.statusRed),
                        ),
                        child: Icon(
                          _lastScanResult!['success'] == true
                              ? Icons.check_rounded
                              : (_lastScanResult!['duplicate'] == true
                                  ? Icons.priority_high_rounded
                                  : Icons.close_rounded),
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lastScanResult!['success'] == true
                                  ? 'GATE CLEARANCE GRANTED'
                                  : (_lastScanResult!['duplicate'] == true
                                      ? 'DUPLICATE PASS ALERT'
                                      : 'INVALID TICKET PASS'),
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: _lastScanResult!['success'] == true
                                    ? GlassTheme.accentEmerald
                                    : (_lastScanResult!['duplicate'] == true
                                        ? GlassTheme.accentAmber
                                        : GlassTheme.statusRed),
                              ),
                            ),
                            Text(
                              _lastScanResult!['message'] as String? ?? '',
                              style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_lastScanResult!['participant'] != null) ...[
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pass: ${_lastScanResult!['participant']?.ticketPassCode ?? ''}',
                          style: GoogleFonts.robotoMono(
                              fontSize: 11, color: Colors.white70),
                        ),
                        Text(
                          'Status: ${_lastScanResult!['participant']?.attendanceStatus.displayName ?? 'Admitted'}',
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Real-Time Entrance Stream
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Entrance Stream (${recentArrivals.length})',
                  style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text('Automatic Sync',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: GlassTheme.accentEmerald)),
            ],
          ),
          const SizedBox(height: 8),

          if (recentArrivals.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: GlassTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlassTheme.border)),
              child: Center(
                child: Text('No participants admitted at this entrance yet.',
                    style: GoogleFonts.roboto(
                        fontSize: 11.5, color: GlassTheme.mutedSilver)),
              ),
            )
          else
            ...recentArrivals.map((arrival) {
              final checkInTime = arrival.checkedInAt != null
                  ? '${arrival.checkedInAt!.hour}:${arrival.checkedInAt!.minute.toString().padLeft(2, '0')}'
                  : 'Just now';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF101014),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GlassTheme.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          GlassTheme.accentEmerald.withValues(alpha: 0.2),
                      child: const Icon(Icons.check_rounded,
                          size: 14, color: GlassTheme.accentEmerald),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(arrival.name,
                                  style: GoogleFonts.roboto(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(width: 6),
                              _statusPill(arrival.participantType.displayName,
                                  GlassTheme.accentSky),
                            ],
                          ),
                          Text(
                              '${arrival.department} • Code: ${arrival.ticketPassCode}',
                              style: GoogleFonts.robotoMono(
                                  fontSize: 10, color: GlassTheme.mutedSilver)),
                        ],
                      ),
                    ),
                    Text(checkInTime,
                        style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GlassTheme.accentEmerald)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCameraScanSimChip({
    required String label,
    required String code,
    required Color color,
    bool isCheckedIn = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handlePassScan(code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCheckedIn
                  ? const Color(0xFF16161C)
                  : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCheckedIn
                    ? GlassTheme.border
                    : color.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCheckedIn
                      ? Icons.check_circle_rounded
                      : Icons.camera_alt_outlined,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCheckedIn ? GlassTheme.mutedSilver : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startCameraIfAvailable() async {
    if (_isDesktop) return;
    if (!mounted) return;
    try {
      if (_cameraController == null) {
        _cameraController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: _isFrontCamera ? CameraFacing.front : CameraFacing.back,
          torchEnabled: _isFlashOn,
          autoStart: false,
        );
        setState(() {}); // rebuild so MobileScanner widget receives the controller
      }
      // Small delay to ensure widget is fully in tree before starting
      await Future.delayed(const Duration(milliseconds: 150));
      await _cameraController?.start();
      if (mounted) setState(() => _isCameraActive = true);
    } catch (e) {
      final msg = e.toString();
      // Ignore "already started" – camera is running fine
      if (!msg.contains('already') && !msg.contains('started')) {
        debugPrint('Camera start error: $e');
      }
      if (mounted) setState(() => _isCameraActive = true);
    }
  }

  Future<void> _pauseCameraIfActive() async {
    if (_isDesktop) return;
    try {
      await _cameraController?.stop();
      if (mounted) setState(() => _isCameraActive = false);
    } catch (_) {}
  }

  Future<void> _restartCamera() async {
    if (_isDesktop) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desktop station mode active. Use ticket code, clipboard, or attendee chips below!'),
            backgroundColor: Color(0xFF1E293B),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    try {
      await _cameraController?.stop();
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: _isFrontCamera ? CameraFacing.front : CameraFacing.back,
      torchEnabled: _isFlashOn,
    );
    if (!mounted) return;
    setState(() {
      _isCameraActive = true;
    });
    try {
      await _cameraController?.start();
    } catch (e) {
      debugPrint('Camera restart start notice: $e');
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Re-initializing camera viewfinder...'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: Color(0xFF1E293B),
        ),
      );
    }
  }

  Future<void> _handlePassScan(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) return;
    _scanCtrl.text = code;
    final result = await _store.checkInParticipantByQR(code);
    setState(() {
      _lastScanResult = result;
    });

    if (result['success'] == true) {
      final p = result['participant'];
      if (p is EventParticipantModel) {
        // AUTOMATION 1: Instant Scan-to-Welcome announcement in Comms Radio
        _store.sendChatMessage(
          '🎉 [GATE ADMISSION] ${p.name} (${p.participantType.displayName}) cleared entrance turnstiles. Pass: ${p.ticketPassCode}',
          channel: 'all-ops',
        );

        // AUTOMATION 2: VIP / Keynote Arrival Protocol Escort Dispatch
        if (p.participantType == ParticipantType.vip) {
          _store.sendChatMessage(
            '⭐ [VIP PROTOCOL ALERT] Dignitary/Speaker ${p.name} has arrived at Gate Scanner! Protocol Escort Squad dispatched to Green Room.',
            channel: 'all-ops',
          );
        }
      }

      // AUTOMATION 3: Capacity Throttling & Overflow Auto-Alert
      const capacity = 500;
      final checkedIn = _store.participants
          .where((part) => part.attendanceStatus == AttendanceStatus.checkedIn)
          .length;
      final ratio = checkedIn / capacity;
      if (ratio >= 0.90) {
        _store.sendChatMessage(
          '⚠️ [CAPACITY WARNING] Venue is at ${(ratio * 100).toInt()}% capacity ($checkedIn/$capacity). Throttle walk-in admissions & prepare overflow hall.',
          channel: 'all-ops',
        );
      }
    }

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result['message'] as String? ?? '✓ Gate Clearance Validated!'),
            backgroundColor: GlassTheme.accentEmerald,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (result['duplicate'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] as String? ?? '⚠️ Duplicate Pass Alert'),
            backgroundColor: GlassTheme.accentAmber,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAddSessionDialog(Map<String, dynamic> event) {
    final titleCtrl = TextEditingController();
    final speakerCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '10:00 AM');
    final endCtrl = TextEditingController(text: '11:00 AM');
    final roomCtrl = TextEditingController(
        text: extractEventVenue(event['venue'], fallback: 'Main Hall'));
    final trackCtrl = TextEditingController(text: 'Keynote');
    int dayNumber = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Session to Master Agenda',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _fieldLabel('Session Title *'),
              _textInput(
                  titleCtrl, 'e.g. Emerging Trends & Future Architecture'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Start Time *'),
                        _textInput(startCtrl, '10:00 AM'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('End Time *'),
                        _textInput(endCtrl, '11:30 AM'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _fieldLabel('Keynote Speaker / Panelists'),
              _textInput(speakerCtrl, 'Speaker name & affiliation'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Room / Stage'),
                        _textInput(roomCtrl, 'Auditorium A'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Track / Category'),
                        _textInput(trackCtrl, 'Keynote / Tech'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _store.createSession(
                      dayNumber: dayNumber,
                      title: titleCtrl.text.trim(),
                      speaker: speakerCtrl.text.trim().isNotEmpty
                          ? speakerCtrl.text.trim()
                          : 'TBD',
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                      room: roomCtrl.text.trim(),
                      track: trackCtrl.text.trim(),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('✓ Session added to master timetable!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Add Session to Timetable',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBroadcastAnnouncementDialog(Map<String, dynamic> event) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    AnnouncementUrgency urgency = AnnouncementUrgency.info;
    AnnouncementAudience audience = AnnouncementAudience.all;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Broadcast Push Announcement',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                  'Send real-time alerts to attendees, VIPs, or operational squads.',
                  style: GoogleFonts.roboto(
                      fontSize: 11.5, color: GlassTheme.mutedSilver)),
              const SizedBox(height: 16),
              _fieldLabel('Announcement Headline *'),
              _textInput(titleCtrl, 'e.g. Keynote Moved to Auditorium B'),
              const SizedBox(height: 12),
              _fieldLabel('Urgency Level *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AnnouncementUrgency>(
                    dropdownColor: const Color(0xFF141418),
                    value: urgency,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: AnnouncementUrgency.values
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(u.displayName)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => urgency = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Target Audience *'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AnnouncementAudience>(
                    dropdownColor: const Color(0xFF141418),
                    value: audience,
                    isExpanded: true,
                    style:
                        GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                    items: AnnouncementAudience.values
                        .map((a) => DropdownMenuItem(
                            value: a, child: Text(a.displayName)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => audience = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Message Body *'),
              _textInput(
                  msgCtrl, 'Full notification instructions or details...'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: urgency == AnnouncementUrgency.emergency
                        ? GlassTheme.statusRed
                        : (urgency == AnnouncementUrgency.high
                            ? GlassTheme.accentAmber
                            : Colors.white),
                    foregroundColor: urgency == AnnouncementUrgency.emergency
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        msgCtrl.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _store.sendAnnouncement(
                      title: titleCtrl.text.trim(),
                      message: msgCtrl.text.trim(),
                      urgency: urgency,
                      audience: audience,
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text(
                              '✓ Announcement dispatched to all live portals!'),
                          backgroundColor: GlassTheme.accentEmerald),
                    );
                  },
                  child: Text('Dispatch Broadcast Alert',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MILESTONE 7: TEAM WORKSPACE HUB, CUSTOM FIELDS & ATTENDEE PROFILE
  // ===========================================================================

  void _showTeamWorkspaceModal(
      EventTeamModel team, Map<String, dynamic> event) {
    int subTab = 0;
    final memberCtrl = TextEditingController();
    final taskTitleCtrl = TextEditingController();
    final chatMsgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final deptTasks = _store.tasks
              .where((t) =>
                  t.department.toLowerCase() == team.department.toLowerCase() ||
                  t.department.toLowerCase() == team.name.toLowerCase())
              .toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(team.name,
                                  style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(width: 8),
                              _statusPill(
                                  team.department, GlassTheme.accentSky),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                              'Lead: ${team.teamLeader} • ${team.members.length + 1}/${team.requiredHeadcount} Crew',
                              style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  color: GlassTheme.mutedSilver)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sub Navigation Switcher
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                      color: const Color(0xFF101014),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GlassTheme.border)),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => subTab = 0),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: subTab == 0
                                  ? const Color(0xFF22222A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Roster (${team.members.length + 1})',
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: subTab == 0
                                        ? Colors.white
                                        : GlassTheme.mutedSilver)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => subTab = 1),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: subTab == 1
                                  ? const Color(0xFF22222A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Tasks (${deptTasks.length})',
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: subTab == 1
                                        ? Colors.white
                                        : GlassTheme.mutedSilver)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => subTab = 2),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: subTab == 2
                                  ? const Color(0xFF22222A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Squad Comms',
                                style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: subTab == 2
                                        ? Colors.white
                                        : GlassTheme.mutedSilver)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Content View
                Expanded(
                  child: subTab == 0
                      ? // ROSTER TAB
                      ListView(
                          children: [
                            // Team Leader Tile
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: GlassTheme.accentAmber
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: GlassTheme.accentAmber
                                        .withValues(alpha: 0.2),
                                    child: const Icon(Icons.star_rounded,
                                        size: 16,
                                        color: GlassTheme.accentAmber),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(team.teamLeader,
                                            style: GoogleFonts.roboto(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)),
                                        Text('Squad Team Leader',
                                            style: GoogleFonts.roboto(
                                                fontSize: 10.5,
                                                color: GlassTheme.accentAmber)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Crew Members
                            ...team.members.map((m) => Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF121216),
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: GlassTheme.border),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor:
                                            const Color(0xFF22222E),
                                        child: Text(
                                            m.isNotEmpty
                                                ? m[0].toUpperCase()
                                                : 'M',
                                            style: GoogleFonts.roboto(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(m,
                                          style: GoogleFonts.roboto(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                      const Spacer(),
                                      _statusPill(
                                          'Assigned', GlassTheme.accentSky),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 12),
                            // Add Member Row
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF0E0E12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: GlassTheme.border)),
                                    child: TextField(
                                      controller: memberCtrl,
                                      style: GoogleFonts.roboto(
                                          color: Colors.white, fontSize: 12.5),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Member name (e.g. Alex Rivera)',
                                        hintStyle: GoogleFonts.roboto(
                                            color: const Color(0xFF52525B),
                                            fontSize: 12),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: GlassTheme.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14)),
                                  onPressed: () async {
                                    final name = memberCtrl.text.trim();
                                    if (name.isEmpty) return;
                                    await _store.addTeamMember(
                                        teamId: team.id, memberName: name);
                                    memberCtrl.clear();
                                    setModalState(() {});
                                  },
                                  child: const Text('Add',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: GlassTheme.accentEmerald,
                                  side: BorderSide(
                                      color: GlassTheme.accentEmerald
                                          .withOpacity(0.5)),
                                ),
                                icon: const Icon(Icons.person_add_alt_1_rounded,
                                    size: 16),
                                label: Text(
                                    '+ Add Volunteer to ${team.department} Squad',
                                    style: GoogleFonts.roboto(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700)),
                                onPressed: () {
                                  _showRecruitVolunteerModal(
                                      defaultDepartment: team.department,
                                      defaultTeamId: team.id);
                                },
                              ),
                            ),
                          ],
                        )
                      : subTab == 1
                          ? // BURNDOWN TASKS TAB
                          ListView(
                              children: [
                                if (deptTasks.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF101014),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: GlassTheme.border)),
                                    child: Center(
                                      child: Text(
                                          'No active tasks assigned to this department squad yet.',
                                          style: GoogleFonts.roboto(
                                              fontSize: 11.5,
                                              color: GlassTheme.mutedSilver)),
                                    ),
                                  )
                                else
                                  ...deptTasks.map((t) {
                                    final isDone =
                                        t.status == TaskStatus.completed;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFF0D1E14)
                                            : const Color(0xFF101014),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: isDone
                                                ? GlassTheme.accentEmerald
                                                    .withValues(alpha: 0.4)
                                                : GlassTheme.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isDone
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .radio_button_unchecked_rounded,
                                            size: 18,
                                            color: isDone
                                                ? GlassTheme.accentEmerald
                                                : GlassTheme.mutedSilver,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(t.title,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                      decoration: isDone
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                    )),
                                                Text(
                                                    '${t.category} • Priority: ${t.priority.toUpperCase()}',
                                                    style: GoogleFonts.roboto(
                                                        fontSize: 10,
                                                        color: GlassTheme
                                                            .mutedSilver)),
                                              ],
                                            ),
                                          ),
                                          if (!isDone)
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    GlassTheme.accentEmerald,
                                                side: const BorderSide(
                                                    color: GlassTheme
                                                        .accentEmerald),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                textStyle: GoogleFonts.roboto(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                              onPressed: () async {
                                                await _store.updateTaskStatus(
                                                    taskId: t.id,
                                                    status:
                                                        TaskStatus.completed);
                                                setModalState(() {});
                                              },
                                              child: const Text('Complete'),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF0E0E12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: GlassTheme.border)),
                                        child: TextField(
                                          controller: taskTitleCtrl,
                                          style: GoogleFonts.roboto(
                                              color: Colors.white,
                                              fontSize: 12.5),
                                          decoration: InputDecoration(
                                            hintText: 'New squad task...',
                                            hintStyle: GoogleFonts.roboto(
                                                color: const Color(0xFF52525B),
                                                fontSize: 12),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: GlassTheme.accentSky,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14)),
                                      onPressed: () async {
                                        final title = taskTitleCtrl.text.trim();
                                        if (title.isEmpty) return;
                                        await _store.createTask(
                                          title: title,
                                          department: team.department,
                                          category: team.department,
                                          priority: 'High',
                                        );
                                        taskTitleCtrl.clear();
                                        setModalState(() {});
                                      },
                                      child: const Text('Add Task',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : // SQUAD COMMS TAB
                          Column(
                              children: [
                                Expanded(
                                  child: _store.chatMessages.isEmpty
                                      ? Center(
                                          child: Text(
                                              'No operational messages yet. Send a radio dispatch below.',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 11.5,
                                                  color:
                                                      GlassTheme.mutedSilver)),
                                        )
                                      : ListView.builder(
                                          itemCount: _store.chatMessages.length,
                                          itemBuilder: (ctx, idx) {
                                            final m = _store.chatMessages[idx];
                                            final isMe = m['isMe'] == true;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              alignment: isMe
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: isMe
                                                      ? const Color(0xFF1E3A5F)
                                                      : const Color(0xFF1A1A22),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: GlassTheme.border),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: isMe
                                                      ? CrossAxisAlignment.end
                                                      : CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                        m['sender']
                                                                as String? ??
                                                            'Squad',
                                                        style: GoogleFonts.roboto(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: GlassTheme
                                                                .accentSky)),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                        m['text'] as String? ??
                                                            '',
                                                        style:
                                                            GoogleFonts.roboto(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white)),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF0E0E12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: GlassTheme.border)),
                                        child: TextField(
                                          controller: chatMsgCtrl,
                                          style: GoogleFonts.roboto(
                                              color: Colors.white,
                                              fontSize: 12.5),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Transmit operational update...',
                                            hintStyle: GoogleFonts.roboto(
                                                color: const Color(0xFF52525B),
                                                fontSize: 12),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.send_rounded,
                                          color: GlassTheme.accentSky),
                                      onPressed: () {
                                        final msg = chatMsgCtrl.text.trim();
                                        if (msg.isEmpty) return;
                                        _store.sendChatMessage(msg);
                                        chatMsgCtrl.clear();
                                        setModalState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCustomFieldsManagementModal(Map<String, dynamic> event) {
    final labelCtrl = TextEditingController();
    final optionsCtrl = TextEditingController();
    CustomFieldType selectedType = CustomFieldType.shortText;
    bool isRequired = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final fields = _store.customFields;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dynamic Custom Fields Engine',
                        style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                    'Configured fields dynamically appear on attendee registration and tickets.',
                    style: GoogleFonts.roboto(
                        fontSize: 11.5, color: GlassTheme.mutedSilver)),
                const SizedBox(height: 16),

                // Existing Fields List
                Text('Active Custom Fields (${fields.length})',
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Expanded(
                  child: fields.isEmpty
                      ? Center(
                          child: Text(
                              'No custom fields defined. Add your first field below.',
                              style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  color: GlassTheme.mutedSilver)),
                        )
                      : ListView.builder(
                          itemCount: fields.length,
                          itemBuilder: (ctx, idx) {
                            final f = fields[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101014),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: GlassTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(f.label,
                                                style: GoogleFonts.roboto(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white)),
                                            if (f.isRequired) ...[
                                              const SizedBox(width: 4),
                                              const Text('*',
                                                  style: TextStyle(
                                                      color:
                                                          GlassTheme.statusRed,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ],
                                          ],
                                        ),
                                        Text(
                                            'Type: ${f.type.displayName} • Key: ${f.key}',
                                            style: GoogleFonts.robotoMono(
                                                fontSize: 10,
                                                color: GlassTheme.mutedSilver)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: GlassTheme.statusRed,
                                        size: 18),
                                    onPressed: () async {
                                      await _store.deleteCustomField(f.key);
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),

                // Add New Field Form
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D11),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Define New Field',
                          style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 10),
                      _fieldLabel('Field Label *'),
                      _textInput(labelCtrl,
                          'e.g. T-Shirt Size, Company ID, Flight Number'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Field Type *'),
                                Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF0E0E12),
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: GlassTheme.border)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<CustomFieldType>(
                                      dropdownColor: const Color(0xFF141418),
                                      value: selectedType,
                                      isExpanded: true,
                                      style: GoogleFonts.roboto(
                                          fontSize: 12, color: Colors.white),
                                      items: CustomFieldType.values
                                          .map((t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(t.displayName)))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null)
                                          setModalState(() => selectedType = v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Required?'),
                              Switch(
                                value: isRequired,
                                activeColor: GlassTheme.accentEmerald,
                                onChanged: (v) =>
                                    setModalState(() => isRequired = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (selectedType == CustomFieldType.dropdown) ...[
                        const SizedBox(height: 10),
                        _fieldLabel('Options (Comma-separated)'),
                        _textInput(optionsCtrl, 'e.g. S, M, L, XL, 2XL'),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: GlassTheme.white,
                              foregroundColor: Colors.black),
                          onPressed: () async {
                            final label = labelCtrl.text.trim();
                            if (label.isEmpty) return;
                            final opts = optionsCtrl.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            await _store.addCustomField(
                              label: label,
                              type: selectedType,
                              isRequired: isRequired,
                              options: opts,
                            );
                            labelCtrl.clear();
                            optionsCtrl.clear();
                            setModalState(() {});
                          },
                          child: const Text('Add Field Definition',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showParticipantProfileSheet(EventParticipantModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1E2838),
                  child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : 'U',
                      style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(
                          '${p.email} • ${p.phone.isNotEmpty ? p.phone : "No phone"}',
                          style: GoogleFonts.roboto(
                              fontSize: 11.5, color: GlassTheme.mutedSilver)),
                    ],
                  ),
                ),
                _statusPill(
                    p.participantType.displayName, GlassTheme.accentSky),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GlassTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricColumn('Status', p.registrationStatus.displayName,
                      GlassTheme.accentEmerald),
                  _metricColumn(
                      'Gate Entry',
                      p.attendanceStatus.displayName,
                      p.attendanceStatus == AttendanceStatus.checkedIn
                          ? GlassTheme.accentEmerald
                          : GlassTheme.mutedSilver),
                  _metricColumn(
                      'Ticket Code', p.ticketPassCode, GlassTheme.accentSky),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Custom Field Answers Section
            Text('Custom Registration Attributes',
                style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 8),
            if (p.customFields.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No custom fields submitted for this attendee.',
                    style: GoogleFonts.roboto(
                        fontSize: 11.5, color: GlassTheme.mutedSilver)),
              )
            else
              ...p.customFields.entries.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141419),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.robotoMono(
                              fontSize: 11, color: GlassTheme.mutedSilver)),
                      Text('${e.value}',
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF818CF8),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.shield_rounded, size: 16),
                    label: const Text('Change Role',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAssignRoleDialog(p);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: GlassTheme.border)),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MILESTONE 8 / RBAC: ROLE-BASED ACCESS CONTROL & PERMISSIONS MODAL
  // ===========================================================================

  void _showRolePermissionsModal(Map<String, dynamic> event) {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final userRole = _store.getUserRoleForEvent(widget.eventCode);
          final permissions = _store.getUserPermissions(widget.eventCode);
          final participants = _store.participants.where((p) {
            if (search.isEmpty) return true;
            return p.name.toLowerCase().contains(search.toLowerCase()) ||
                p.email.toLowerCase().contains(search.toLowerCase()) ||
                p.department.toLowerCase().contains(search.toLowerCase());
          }).toList();

          const creatorCount = 1;
          final headCount = _store.participants
              .where((p) => p.assignedRole.toLowerCase().contains('head'))
              .length;
          final coordCount = _store.participants
              .where((p) => p.assignedRole.toLowerCase().contains('coord'))
              .length;
          final volCount = _store.participants
              .where((p) =>
                  p.assignedRole.toLowerCase().contains('volunt') ||
                  p.participantType == ParticipantType.volunteer)
              .length;
          final attendeeCount = _store.participants.length;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded,
                                color: Color(0xFF818CF8), size: 20),
                            const SizedBox(width: 8),
                            Text('Access & Permissions Hub',
                                style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                            'Role-Based Authority • Department Squad Delegation',
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: GlassTheme.mutedSilver)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Active User Role Badge Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: userRole == EventRole.creator
                            ? const Color(0xFF818CF8).withOpacity(0.5)
                            : GlassTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: userRole == EventRole.creator
                              ? const Color(0xFF818CF8).withOpacity(0.15)
                              : Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          userRole == EventRole.creator
                              ? Icons.verified_user_rounded
                              : Icons.shield_outlined,
                          color: userRole == EventRole.creator
                              ? const Color(0xFF818CF8)
                              : GlassTheme.accentSky,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR ACTIVE PRIVILEGE LEVEL',
                                style: GoogleFonts.robotoMono(
                                    fontSize: 9.5,
                                    letterSpacing: 0.8,
                                    color: GlassTheme.mutedSilver)),
                            Text(userRole.displayName,
                                style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      _statusPill(
                        userRole == EventRole.creator
                            ? 'Super Admin'
                            : (permissions.isDepartmentHead
                                ? 'Head'
                                : 'Member'),
                        userRole == EventRole.creator
                            ? const Color(0xFF818CF8)
                            : GlassTheme.accentSky,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Multi-Tier Headcount Breakdown
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _roleStatBadge(
                          'Creator', '$creatorCount', const Color(0xFF818CF8)),
                      const SizedBox(width: 8),
                      _roleStatBadge(
                          'Heads', '$headCount', GlassTheme.accentSky),
                      const SizedBox(width: 8),
                      _roleStatBadge('Coordinators', '$coordCount',
                          GlassTheme.accentAmber),
                      const SizedBox(width: 8),
                      _roleStatBadge(
                          'Volunteers', '$volCount', GlassTheme.accentEmerald),
                      const SizedBox(width: 8),
                      _roleStatBadge('Total Crew & Guests', '$attendeeCount',
                          Colors.white70),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Actions: Add / Recruit Volunteer under Department
                if (permissions.isCreator || permissions.isDepartmentHead)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.accentEmerald,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded,
                            size: 18),
                        label: Text(
                          permissions.isCreator
                              ? '+ Assign Volunteer to Department'
                              : '+ Add Volunteer Under My Department',
                          style: GoogleFonts.roboto(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          _showRecruitVolunteerModal(
                              defaultDepartment: permissions.isDepartmentHead
                                  ? permissions.department
                                  : null);
                        },
                      ),
                    ),
                  ),

                // Search Bar
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.border),
                  ),
                  child: TextField(
                    style:
                        GoogleFonts.roboto(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText:
                          'Search participant, volunteer, or department...',
                      hintStyle: GoogleFonts.roboto(
                          color: const Color(0xFF52525B), fontSize: 11.5),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: GlassTheme.mutedSilver, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) {
                      setSheetState(() => search = val);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Member Directory
                Expanded(
                  child: participants.isEmpty
                      ? Center(
                          child: Text('No members found.',
                              style: GoogleFonts.roboto(
                                  color: GlassTheme.mutedSilver, fontSize: 12)),
                        )
                      : ListView.builder(
                          itemCount: participants.length,
                          itemBuilder: (ctx, idx) {
                            final p = participants[idx];
                            final isOwner = p.email.toLowerCase() ==
                                (event['createdBy'] as String? ?? '')
                                    .toLowerCase();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF121217),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isOwner
                                        ? const Color(0xFF818CF8)
                                            .withOpacity(0.4)
                                        : GlassTheme.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isOwner
                                        ? const Color(0xFF818CF8)
                                            .withOpacity(0.2)
                                        : Colors.white10,
                                    child: Text(
                                      p.name.isNotEmpty
                                          ? p.name[0].toUpperCase()
                                          : 'U',
                                      style: GoogleFonts.roboto(
                                          color: isOwner
                                              ? const Color(0xFF818CF8)
                                              : Colors.white,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(p.name,
                                                style: GoogleFonts.roboto(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white)),
                                            if (isOwner) ...[
                                              const SizedBox(width: 6),
                                              _statusPill('Owner',
                                                  const Color(0xFF818CF8)),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('${p.email} • ${p.department}',
                                            style: GoogleFonts.roboto(
                                                fontSize: 11,
                                                color: GlassTheme.mutedSilver)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _statusPill(p.assignedRole,
                                          _roleColor(p.assignedRole)),
                                      if (permissions.canAssignRoles &&
                                          !isOwner) ...[
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () => _showAssignRoleDialog(p),
                                          child: Text('Change Role',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: GlassTheme.accentSky)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
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

  Widget _roleStatBadge(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF14141A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: GlassTheme.mutedSilver)),
          Text(count,
              style: GoogleFonts.roboto(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    final clean = role.toLowerCase();
    if (clean.contains('creator') ||
        clean.contains('owner') ||
        clean.contains('admin')) return const Color(0xFF818CF8);
    if (clean.contains('head') || clean.contains('lead'))
      return GlassTheme.accentSky;
    if (clean.contains('coord')) return GlassTheme.accentAmber;
    if (clean.contains('volunt') || clean.contains('crew'))
      return GlassTheme.accentEmerald;
    return GlassTheme.mutedSilver;
  }

  void _showAssignRoleDialog(EventParticipantModel p) {
    EventRole chosenRole = EventRole.fromString(p.assignedRole);
    String chosenDept = p.department;
    final departments = [
      'Media',
      'Security',
      'Registration',
      'Logistics',
      'Stage AV',
      'Hospitality',
      'Finance',
      'General'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: GlassTheme.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Assign Role & Department',
              style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${p.name} (${p.email})',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: GlassTheme.mutedSilver)),
                const SizedBox(height: 14),
                _fieldLabel('Assigned Operational Role'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0E0E12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GlassTheme.border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EventRole>(
                      value: chosenRole,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF141419),
                      items: EventRole.values.map((r) {
                        return DropdownMenuItem<EventRole>(
                          value: r,
                          child: Text(r.displayName,
                              style: GoogleFonts.roboto(
                                  color: Colors.white, fontSize: 12.5)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => chosenRole = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _fieldLabel('Assigned Department'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0E0E12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GlassTheme.border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: departments.contains(chosenDept)
                          ? chosenDept
                          : departments.first,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF141419),
                      items: departments.map((d) {
                        return DropdownMenuItem<String>(
                          value: d,
                          child: Text(d,
                              style: GoogleFonts.roboto(
                                  color: Colors.white, fontSize: 12.5)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => chosenDept = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.accentSky,
                  foregroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final success = await _store.assignParticipantRole(
                  participantId: p.id,
                  newRole: chosenRole,
                  department: chosenDept,
                );
                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text(
                            '✓ Role updated to ${chosenRole.displayName} for ${p.name}!')),
                  );
                }
              },
              child: const Text('Save Role',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecruitVolunteerModal(
      {String? defaultDepartment, String? defaultTeamId}) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final departments = [
      'Security',
      'Logistics',
      'Registration',
      'Media',
      'Stage AV',
      'Hospitality',
      'Finance'
    ];
    String chosenDept = defaultDepartment ??
        (departments.contains(_store.currentDepartment)
            ? _store.currentDepartment
            : departments.first);
    String? chosenTeam = defaultTeamId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final deptTeams = _store.teams
              .where(
                  (t) => t.department.toLowerCase() == chosenDept.toLowerCase())
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recruit Volunteer Under Department',
                        style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Text(
                    'Enrolls a volunteer into the department squad roster with field scanner authority',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: GlassTheme.mutedSilver)),
                const SizedBox(height: 14),
                _fieldLabel('Volunteer Full Name'),
                _textInput(nameCtrl, 'e.g. Rahul Verma'),
                const SizedBox(height: 12),
                _fieldLabel('Volunteer Email'),
                _textInput(emailCtrl, 'e.g. rahul.verma@campus.edu'),
                const SizedBox(height: 12),
                _fieldLabel('Department Assignment'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0E0E12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GlassTheme.border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: departments.contains(chosenDept)
                          ? chosenDept
                          : departments.first,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF141419),
                      items: departments
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: GoogleFonts.roboto(
                                      color: Colors.white, fontSize: 12.5))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => chosenDept = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (deptTeams.isNotEmpty) ...[
                  _fieldLabel('Assign to Field Squad Team (Optional)'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0E0E12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GlassTheme.border)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: chosenTeam,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF141419),
                        hint: Text('Select Squad Team',
                            style: GoogleFonts.roboto(
                                color: Colors.white60, fontSize: 12)),
                        items: [
                          DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No Specific Squad',
                                  style: GoogleFonts.roboto(
                                      color: Colors.white60, fontSize: 12.5))),
                          ...deptTeams.map((t) => DropdownMenuItem<String?>(
                              value: t.id,
                              child: Text('${t.name} (Lead: ${t.teamLeader})',
                                  style: GoogleFonts.roboto(
                                      color: Colors.white, fontSize: 12.5)))),
                        ],
                        onChanged: (val) =>
                            setModalState(() => chosenTeam = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: GlassTheme.accentEmerald,
                        foregroundColor: Colors.black),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      if (name.isEmpty || email.isEmpty) return;

                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      final success =
                          await _store.assignVolunteerUnderDepartmentHead(
                        department: chosenDept,
                        volunteerName: name,
                        volunteerEmail: email,
                        teamId: chosenTeam,
                      );
                      if (success) {
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(
                                  '✓ Volunteer $name successfully enrolled under $chosenDept!')),
                        );
                      }
                    },
                    child: Text('Enroll Volunteer to $chosenDept',
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
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
  // EMAIL CONFIRMATION & OWNER PASS MODAL
  // ===========================================================================

  void _showOwnerConfirmationEmailModal(Map<String, dynamic> event) {
    final isCreator =
        _store.getUserRoleForEvent(widget.eventCode) == EventRole.creator;
    if (!isCreator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '🔒 Access Denied: VIP Owner Pass and master recovery keys are strictly reserved for the verified Event Creator.'),
          backgroundColor: GlassTheme.statusRed,
        ),
      );
      return;
    }

    final title = event['title'] as String? ?? widget.eventCode;
    final code = widget.eventCode;
    final password = event['password'] as String? ?? '';
    final dept = event['department'] as String? ?? 'General Operations';
    final venue =
        extractEventVenue(event['venue'], fallback: 'Designated Event Venue');
    final ownerEmail = event['createdBy'] as String? ?? 'Event Creator';
    final ownerPassCode = 'VIP-$code-OWNER';

    final confirmation = _store.latestOwnerConfirmation ??
        EventEmailConfirmation(
          id: 'CONF-$code',
          eventId: code,
          recipientEmail: ownerEmail,
          ownerName: ownerEmail.split('@').first,
          eventTitle: title,
          eventCode: code,
          passcode: password,
          ownerPassCode: ownerPassCode,
          venue: venue,
          schedule: 'Active Operational Period',
          timezone: 'Asia/Kolkata',
          organizingDepartment: dept,
          sentAt: DateTime.now(),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_email_read_rounded,
                        color: Color(0xFFF472B6), size: 20),
                    const SizedBox(width: 8),
                    Text('Owner Event Pass & Email Certificate',
                        style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
                IconButton(
                    icon:
                        const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text(
                'Dispatched confirmation ledger and emergency credentials backup',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: GlassTheme.mutedSilver)),
            const SizedBox(height: 14),

            // Certificate VIP Card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1E1B4B),
                            Color(0xFF0F172A),
                            Color(0xFF141419)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFF472B6).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('GROUNDFLOW OFFICIAL CERTIFICATE',
                                  style: GoogleFonts.robotoMono(
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                      color: const Color(0xFFF472B6))),
                              _statusPill(
                                  'CONFIRMED', GlassTheme.accentEmerald),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(title,
                              style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Event Code: $code',
                              style: GoogleFonts.robotoMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: GlassTheme.accentSky)),
                          const Divider(color: Colors.white12, height: 24),
                          _certRow(
                              'Security Passcode',
                              password.isNotEmpty
                                  ? password
                                  : 'Open Access (No Password)'),
                          _certRow('Primary Department', dept),
                          _certRow('Venue / Facility', venue),
                          _certRow('Registered To', ownerEmail),
                          _certRow(
                              'Dispatched Time',
                              confirmation.sentAt
                                  .toIso8601String()
                                  .split('.')
                                  .first
                                  .replaceAll('T', ' ')),
                          const Divider(color: Colors.white12, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('OWNER VIP PASS TOKEN',
                                      style: GoogleFonts.robotoMono(
                                          fontSize: 9.5,
                                          color: GlassTheme.mutedSilver)),
                                  const SizedBox(height: 2),
                                  Text(ownerPassCode,
                                      style: GoogleFonts.robotoMono(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: GlassTheme.accentAmber)),
                                ],
                              ),
                              QrImageView(
                                data: ownerPassCode,
                                size: 60,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Instructions Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101016),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GlassTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: GlassTheme.accentSky, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A copy of these credentials and VIP pass was automatically compiled and stored in Cloud Firestore. If you lose access, restore anytime with your email.',
                              style: GoogleFonts.roboto(
                                  fontSize: 11, color: GlassTheme.mutedSilver),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF472B6),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Pass',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: confirmation.plainTextContent));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '✓ Full Event Pass & Credentials copied to clipboard!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.accentSky,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text('Gmail',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    onPressed: () async {
                      await EventEmailService().launchGmailWeb(
                        recipientEmail: confirmation.recipientEmail,
                        subject: confirmation.subject,
                        body: confirmation.plainTextContent,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.mark_email_read_rounded, size: 16),
                    label: const Text('Email App',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    onPressed: () async {
                      await EventEmailService().launchEmailApp(confirmation);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: GlassTheme.border),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 10),
                  ),
                  icon: const Icon(Icons.send_rounded,
                      size: 14, color: GlassTheme.accentEmerald),
                  label: const Text('Queue Mail',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _store.resendOwnerConfirmationEmail(widget.eventCode);
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(
                              '✓ Official Confirmation Email queued for $ownerEmail!')),
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

  Widget _certRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 11.5, color: GlassTheme.mutedSilver)),
          Text(value,
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // Common Form UI Helpers
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: GoogleFonts.roboto(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: GlassTheme.chrome)),
    );
  }

  Widget _textInput(TextEditingController ctrl, String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
          color: const Color(0xFF0E0E12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GlassTheme.border)),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(
              color: const Color(0xFF52525B), fontSize: 12.5),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class _ScannerGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
