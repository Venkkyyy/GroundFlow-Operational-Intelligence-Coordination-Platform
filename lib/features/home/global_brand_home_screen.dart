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
  final TextEditingController _joinCodeCtrl = TextEditingController();
  final TextEditingController _joinPasswordCtrl = TextEditingController();
  final TextEditingController _newEventCodeCtrl = TextEditingController();
  final TextEditingController _newEventTitleCtrl = TextEditingController();
  final TextEditingController _newEventVenueCtrl = TextEditingController();

  @override
  void dispose() {
    _joinCodeCtrl.dispose();
    _joinPasswordCtrl.dispose();
    _newEventCodeCtrl.dispose();
    _newEventTitleCtrl.dispose();
    _newEventVenueCtrl.dispose();
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
          appBar: AppBar(
            backgroundColor: GlassTheme.black,
            elevation: 0,
            title: Row(
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
              // User Profile & Sign Out
              PopupMenuButton<String>(
                color: GlassTheme.cardBg,
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF27272A),
                  backgroundImage: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                      ? NetworkImage(store.photoUrl!)
                      : null,
                  child: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                      ? null
                      : Text(
                          store.userAvatar,
                          style: GoogleFonts.roboto(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                ),
                onSelected: (val) {
                  if (val == 'signout') {
                    store.signOut();
                    widget.onSignOut();
                  } else if (val == 'test_cloud') {
                    _showCloudDiagnosticDialog(context);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.userName, style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(store.userEmail, style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.mutedSilver)),
                        const SizedBox(height: 4),
                        Text(
                          store.hasAssignedRole ? 'Role: ${store.displayRoleTitle}' : 'Role: Not Assigned Yet',
                          style: GoogleFonts.roboto(fontSize: 11, color: store.hasAssignedRole ? GlassTheme.accentSky : GlassTheme.accentAmber),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'test_cloud',
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_sync_rounded, size: 16, color: GlassTheme.accentSky),
                        const SizedBox(width: 8),
                        Text('Check Cloud Connection', style: GoogleFonts.roboto(fontSize: 12.5, color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, size: 16, color: GlassTheme.statusRed),
                        const SizedBox(width: 8),
                        Text('Sign Out', style: GoogleFonts.roboto(fontSize: 12.5, color: GlassTheme.statusRed)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            color: GlassTheme.white,
            backgroundColor: const Color(0xFF1B1B22),
            onRefresh: () async => await store.refreshEvents(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
              // 1. User Operational Control Card
              Container(
                padding: const EdgeInsets.all(22),
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
                          radius: 20,
                          backgroundColor: const Color(0xFF222228),
                          backgroundImage: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                              ? NetworkImage(store.photoUrl!)
                              : null,
                          child: (store.photoUrl != null && store.photoUrl!.isNotEmpty)
                              ? null
                              : Text(
                                  store.userAvatar,
                                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                        ),
                        const SizedBox(width: 12),
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
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver),
                                  children: [
                                    const TextSpan(text: 'Active Session • '),
                                    TextSpan(
                                      text: store.hasAssignedRole ? store.displayRoleTitle : 'Awaiting Role Assignment',
                                      style: TextStyle(
                                        color: store.hasAssignedRole ? GlassTheme.accentEmerald : GlassTheme.accentAmber,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: ' • '),
                                    TextSpan(text: store.userEmail, style: const TextStyle(color: Colors.white70)),
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
                                      const Icon(Icons.badge_outlined, size: 13, color: GlassTheme.accentSky),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Assign or Select Role',
                                        style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.accentSky, decoration: TextDecoration.underline),
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
                    const SizedBox(height: 18),

                    // Primary Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlassTheme.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text('Create an Event', style: GoogleFonts.roboto(fontSize: 13.5, fontWeight: FontWeight.w700)),
                            onPressed: () => _showCreateEventDialog(context, store),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GlassTheme.white,
                              side: const BorderSide(color: GlassTheme.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: Text('Join with Code', style: GoogleFonts.roboto(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            onPressed: () => _showJoinEventDialog(context, store),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Real Campus Events Section (ZERO DUMMY EVENTS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Events (${store.events.length})',
                    style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  if (hasActiveEvents)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GlassTheme.accentEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GlassTheme.accentEmerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: GlassTheme.accentEmerald),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE PROTOCOL',
                            style: GoogleFonts.roboto(fontSize: 9.5, fontWeight: FontWeight.w700, color: GlassTheme.accentEmerald),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // If no events exist, show clean empty state (zero dummy events)
              if (!hasActiveEvents)
                _buildNoEventsCard(context, store)
              else ...[
                // SECTION 1: Events Created by the User
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFF472B6)),
                    const SizedBox(width: 6),
                    Text(
                      'Created by You (${createdEvents.length})',
                      style: GoogleFonts.roboto(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (createdEvents.isEmpty)
                  _buildEmptySectionCard(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'No Events Created',
                    subtitle: 'You haven\'t organized any events yet. Tap "Create an Event" to start.',
                  )
                else
                  ...createdEvents.map((event) => _buildEventCard(context, store, event)),

                const SizedBox(height: 16),

                // SECTION 2: Events Where User Participates
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 16, color: GlassTheme.accentSky),
                    const SizedBox(width: 6),
                    Text(
                      'Participating Events (${participatingEvents.length})',
                      style: GoogleFonts.roboto(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (participatingEvents.isEmpty)
                  _buildEmptySectionCard(
                    icon: Icons.login_rounded,
                    title: 'No Joined Events',
                    subtitle: 'You haven\'t joined any external events yet. Tap "Join with Code" to enter.',
                  )
                else
                  ...participatingEvents.map((event) => _buildEventCard(context, store, event)),
              ],

              const SizedBox(height: 36),
            ],
          ),
        ),
      );
    },
  );
}

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
                  style: GoogleFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.mutedSilver),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Clean Empty State when no events have been created or joined
  Widget _buildNoEventsCard(BuildContext context, GroundFlowRealtimeStore store) {
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
            child: const Icon(Icons.event_available_outlined, size: 28, color: GlassTheme.accentSky),
          ),
          const SizedBox(height: 14),
          Text(
            'No Events Created or Joined Yet',
            style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your campus event or enter an event passcode to launch the live volunteer ledger.',
            style: GoogleFonts.roboto(fontSize: 12.5, color: GlassTheme.mutedSilver),
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
                const Icon(Icons.arrow_upward_rounded, size: 14, color: GlassTheme.accentSky),
                const SizedBox(width: 6),
                Text(
                  'Use "Create an Event" or "Join with Code" above to begin',
                  style: GoogleFonts.roboto(fontSize: 12, color: GlassTheme.chrome),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, GroundFlowRealtimeStore store, Map<String, dynamic> event) {
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
                    color: isCreator ? const Color(0xFF3B1D28) : const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCreator ? const Color(0xFFF472B6).withValues(alpha: 0.3) : GlassTheme.border,
                    ),
                  ),
                  child: Icon(
                    isCreator ? Icons.stars_rounded : Icons.confirmation_number_outlined,
                    color: isCreator ? const Color(0xFFF472B6) : GlassTheme.accentSky,
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
                          style: GoogleFonts.roboto(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white),
                          children: [
                            TextSpan(
                              text: code,
                              style: TextStyle(
                                color: isCreator ? const Color(0xFFF472B6) : GlassTheme.accentSky,
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
                        style: GoogleFonts.roboto(fontSize: 12, color: GlassTheme.chrome),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isCreator ? const Color(0xFF3B1D28) : const Color(0xFF0F2537),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isCreator ? const Color(0xFFF472B6).withValues(alpha: 0.4) : GlassTheme.accentSky.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isCreator ? '👑 Organized by You' : '🎟️ Participant',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isCreator ? const Color(0xFFF472B6) : GlassTheme.accentSky,
                              ),
                            ),
                          ),
                          Text(
                            isCreator ? 'Tap to manage →' : 'Tap for details & pass →',
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
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: GlassTheme.statusRed),
                    tooltip: 'Delete Event',
                    onPressed: () => _confirmDeleteEvent(context, store, code, title),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: GlassTheme.mutedSilver),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context, GroundFlowRealtimeStore store) {
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

  void _showJoinEventDialog(BuildContext context, GroundFlowRealtimeStore store) {
    _joinCodeCtrl.clear();
    _joinPasswordCtrl.clear();
    String? joinError;
    bool isJoining = false;
    bool obscurePass = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                    child: const Icon(Icons.meeting_room_rounded, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Join Campus Event',
                    style: GoogleFonts.roboto(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the Event Code and Password provided by your organizer to join the live operational ledger.',
                style: GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver, height: 1.3),
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
                onToggleObscure: () => setModalState(() => obscurePass = !obscurePass),
              ),

              if (joinError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: GlassTheme.statusRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlassTheme.statusRed.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: GlassTheme.statusRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          joinError!,
                          style: GoogleFonts.roboto(color: GlassTheme.statusRed, fontSize: 11.5, fontWeight: FontWeight.w500),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isJoining
                      ? null
                      : () async {
                          final code = _joinCodeCtrl.text.trim();
                          final pass = _joinPasswordCtrl.text.trim();

                          if (code.isEmpty) {
                            setModalState(() => joinError = 'Please enter an Event Code.');
                            return;
                          }

                          setModalState(() {
                            isJoining = true;
                            joinError = null;
                          });

                          final result = await store.joinEventWithPassword(code: code, password: pass);

                          if (!ctx.mounted) return;

                          if (result['success'] == true) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] as String? ?? '✓ Joined event!'),
                                backgroundColor: GlassTheme.accentEmerald,
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EventOperationsWorkspaceScreen(eventCode: code)),
                            );
                          } else {
                            setModalState(() {
                              isJoining = false;
                              joinError = result['message'] as String? ?? 'Failed to join event.';
                            });
                          }
                        },
                  child: isJoining
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text('Verify & Join Operational Hub', style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleSelectionDialog(BuildContext context, GroundFlowRealtimeStore store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GlassTheme.border),
        ),
        title: Text('Select Your Operational Role', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppRole.values.map((role) {
            final isCurrent = role == store.currentRole && store.hasAssignedRole;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF222228) : const Color(0xFF0E0E12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isCurrent ? GlassTheme.accentEmerald : GlassTheme.border),
              ),
              child: ListTile(
                leading: Icon(
                  isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isCurrent ? GlassTheme.accentEmerald : Colors.grey,
                  size: 20,
                ),
                title: Text(role.title, style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: Text(
                  role == AppRole.departmentHead
                      ? 'Event / Department Administrator'
                      : (role == AppRole.teamLead ? 'Squad Lead (Field Coordinator)' : 'Ground Volunteer / Crew Member'),
                  style: GoogleFonts.roboto(color: GlassTheme.mutedSilver, fontSize: 11),
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
            child: Text('Cancel', style: GoogleFonts.roboto(color: GlassTheme.chrome)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, GroundFlowRealtimeStore store, String code, String title) {
    final permissions = store.getUserPermissions(code);
    if (!permissions.canDeleteEvent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Access Denied: Only the Event Creator / Super Admin has authority to delete this event.'),
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
              child: const Icon(Icons.delete_forever_rounded, color: GlassTheme.statusRed, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Event',
                style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This will remove the event, its operational tasks, and clear its live cloud ledger on Firestore. This action cannot be undone.',
              style: GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.roboto(color: GlassTheme.chrome)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.statusRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            child: Text('Delete Event', style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
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
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: GlassTheme.accentSky)),
            const SizedBox(width: 12),
            Text('Testing Cloud Firestore...', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        content: Text('Testing real-time read and write connectivity to Firebase Project: groundflow-acca3', style: GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver)),
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
          side: BorderSide(color: isSuccess ? GlassTheme.accentEmerald : GlassTheme.statusRed),
        ),
        title: Row(
          children: [
            Icon(isSuccess ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, color: isSuccess ? GlassTheme.accentEmerald : GlassTheme.statusRed, size: 22),
            const SizedBox(width: 10),
            Text(isSuccess ? 'Cloud Connected' : 'Cloud Sync Notice', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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
              style: GoogleFonts.roboto(fontSize: 12.5, color: Colors.white70, height: 1.4),
            ),
            if (!isSuccess && (result['error']?.toString().contains('permission-denied') ?? false)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF221516), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Action Required: Open Firebase Console > Firestore Database > Rules and ensure read/write is allowed.',
                  style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.statusRed),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GlassTheme.white, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
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
        Text(label, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
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
              hintStyle: GoogleFonts.roboto(color: const Color(0xFF52525B), fontSize: 12.5),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: GlassTheme.chrome, size: 16) : null,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
