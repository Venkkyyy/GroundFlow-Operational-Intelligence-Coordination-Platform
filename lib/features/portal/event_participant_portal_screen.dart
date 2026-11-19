import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/state/ground_flow_realtime_store.dart';
import '../../core/models/universal_event_model.dart';

class EventParticipantPortalScreen extends StatefulWidget {
  final String eventCode;
  final VoidCallback? onBack;

  const EventParticipantPortalScreen({
    super.key,
    required this.eventCode,
    this.onBack,
  });

  @override
  State<EventParticipantPortalScreen> createState() => _EventParticipantPortalScreenState();
}

class _EventParticipantPortalScreenState extends State<EventParticipantPortalScreen> {
  final GroundFlowRealtimeStore _store = GroundFlowRealtimeStore();

  // Registration Form Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _orgCtrl = TextEditingController();
  ParticipantType _selectedType = ParticipantType.guest;
  String _dietaryPref = 'None';
  final Map<String, dynamic> _customFieldAnswers = {};
  bool _isRegistering = false;
  bool _showQrCode = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _store.userName;
    _emailCtrl.text = _store.userEmail;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getEventData() {
    return _store.events.firstWhere(
      (e) => e['code'] == widget.eventCode,
      orElse: () => {
        'code': widget.eventCode,
        'title': '${widget.eventCode} Summit',
        'venue': 'Campus Grand Arena',
        'status': 'Live Protocol',
        'lifecycle': 'published',
      },
    );
  }

  EventParticipantModel? _findUserParticipant() {
    final email = _store.userEmail.toLowerCase().trim();
    if (email.isEmpty) return null;
    try {
      return _store.participants.firstWhere((p) => p.email.toLowerCase().trim() == email);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final event = _getEventData();
        final participant = _findUserParticipant();

        return Scaffold(
          backgroundColor: GlassTheme.black,
          appBar: AppBar(
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
              children: [
                Text(
                  event['title'] as String? ?? widget.eventCode,
                  style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Attendee Portal & Digital Wallet',
                  style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.mutedSilver),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GlassTheme.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GlassTheme.accentEmerald.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: GlassTheme.accentEmerald),
                    const SizedBox(width: 4),
                    Text(
                      widget.eventCode,
                      style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: GlassTheme.accentEmerald),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0. Live Broadcast & Emergency Push Alert Banner
                _buildBroadcastAlertBanner(),

                // 1. Digital Ticket Wallet Card (if already registered)
                if (participant != null) ...[
                  _buildDigitalTicketCard(event, participant),
                  const SizedBox(height: 24),
                ],

                // 2. Event Overview & Briefing Card
                _buildEventBriefingCard(event),
                const SizedBox(height: 20),

                // 3. Self-Registration Form (if not yet registered)
                if (participant == null) ...[
                  _buildRegistrationFormCard(event),
                  const SizedBox(height: 20),
                ],

                // 4. Interactive Live Agenda & Sessions Schedule
                _buildAgendaTimelineCard(event),
                const SizedBox(height: 20),

                // 5. Venue & Logistical Facilities Card
                _buildVenueDetailsCard(event),
                const SizedBox(height: 20),

                // 6. Help & Event Coordinator Desk
                _buildCoordinatorCard(event),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 0. BROADCAST & EMERGENCY ALERT BANNER
  // ===========================================================================
  Widget _buildBroadcastAlertBanner() {
    if (_store.announcements.isEmpty) return const SizedBox.shrink();
    final latest = _store.announcements.first;
    Color bg = const Color(0xFF0F172A);
    Color fg = GlassTheme.accentSky;
    IconData icon = Icons.campaign_rounded;

    if (latest.urgency == AnnouncementUrgency.emergency) {
      bg = const Color(0xFF450A0A);
      fg = GlassTheme.statusRed;
      icon = Icons.warning_amber_rounded;
    } else if (latest.urgency == AnnouncementUrgency.high) {
      bg = const Color(0xFF451A03);
      fg = GlassTheme.accentAmber;
      icon = Icons.priority_high_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        latest.title,
                        style: GoogleFonts.roboto(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: fg.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text(latest.urgency.displayName.toUpperCase(), style: GoogleFonts.roboto(fontSize: 9.5, fontWeight: FontWeight.w800, color: fg)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(latest.message, style: GoogleFonts.roboto(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Broadcast by ${latest.sentBy}', style: GoogleFonts.roboto(fontSize: 10, color: GlassTheme.chrome)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. INTERACTIVE LIVE AGENDA & TIMELINE CARD
  // ===========================================================================
  Widget _buildAgendaTimelineCard(Map<String, dynamic> event) {
    final sessions = _store.sessions;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Event Agenda & Sessions', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(6)),
                child: Text('${sessions.length} Sessions', style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: GlassTheme.mutedSilver)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Real-time timetable across tracks and rooms.', style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver)),
          const SizedBox(height: 16),

          if (sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Sessions will be posted by the organizer soon.', style: GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver)),
              ),
            )
          else
            ...sessions.map((ses) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ses.isLiveNow ? const Color(0xFF0F1E19) : const Color(0xFF0F0F13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ses.isLiveNow ? GlassTheme.accentEmerald : GlassTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 14, color: GlassTheme.accentSky),
                            const SizedBox(width: 4),
                            Text('${ses.startTime} – ${ses.endTime}', style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w700, color: GlassTheme.accentSky)),
                          ],
                        ),
                        if (ses.isLiveNow)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: GlassTheme.accentEmerald.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: GlassTheme.accentEmerald),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: GlassTheme.accentEmerald),
                                const SizedBox(width: 4),
                                Text('LIVE NOW', style: GoogleFonts.roboto(fontSize: 9.5, fontWeight: FontWeight.w800, color: GlassTheme.accentEmerald)),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF1C1C24), borderRadius: BorderRadius.circular(4)),
                            child: Text(ses.track, style: GoogleFonts.roboto(fontSize: 10, color: GlassTheme.mutedSilver)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ses.title, style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 14, color: GlassTheme.mutedSilver),
                        const SizedBox(width: 4),
                        Text(ses.speaker, style: GoogleFonts.roboto(fontSize: 11.5, color: Colors.white70)),
                        const SizedBox(width: 12),
                        const Icon(Icons.meeting_room_rounded, size: 14, color: GlassTheme.mutedSilver),
                        const SizedBox(width: 4),
                        Text(ses.room, style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. DIGITAL TICKET PASS WALLET
  // ===========================================================================
  Widget _buildDigitalTicketCard(Map<String, dynamic> event, EventParticipantModel participant) {
    final isCheckedIn = participant.attendanceStatus == AttendanceStatus.checkedIn;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141A29), Color(0xFF0F172A), Color(0xFF090D16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCheckedIn ? GlassTheme.accentEmerald : GlassTheme.accentSky),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn ? GlassTheme.accentEmerald : GlassTheme.accentSky).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'OFFICIAL DIGITAL PASS',
                      style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCheckedIn ? GlassTheme.accentEmerald.withValues(alpha: 0.2) : GlassTheme.accentSky.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isCheckedIn ? GlassTheme.accentEmerald : GlassTheme.accentSky),
                  ),
                  child: Text(
                    isCheckedIn ? '✓ CHECKED IN' : 'GATE PASS ACTIVE',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isCheckedIn ? GlassTheme.accentEmerald : GlassTheme.accentSky,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Attendee Info
                Text(
                  participant.name,
                  style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${participant.participantType.displayName} • ${participant.department}',
                  style: GoogleFonts.roboto(fontSize: 12.5, color: GlassTheme.mutedSilver),
                ),
                const SizedBox(height: 10),

                // Pass Code string & Toggle Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090D16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GlassTheme.border),
                      ),
                      child: Text(
                        participant.ticketPassCode,
                        style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w700, color: GlassTheme.accentSky),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showQrCode ? const Color(0xFF22222A) : GlassTheme.accentSky,
                        foregroundColor: _showQrCode ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: Icon(_showQrCode ? Icons.visibility_off_rounded : Icons.qr_code_rounded, size: 14),
                      label: Text(
                        _showQrCode ? 'Hide QR Code' : 'Show QR Code',
                        style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        setState(() {
                          _showQrCode = !_showQrCode;
                        });
                      },
                    ),
                  ],
                ),

                // ONLY VISIBLE IF USER SELECTS/TAPS TO SHOW QR CODE
                if (_showQrCode) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10),
                      ],
                    ),
                    child: QrImageView(
                      data: participant.ticketPassCode,
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Perforated Divider Graphic
                Row(
                  children: List.generate(
                    24,
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Ticket Details Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ticketSubDetail('Venue', extractEventVenue(event['venue'], fallback: 'Campus Arena')),
                    _ticketSubDetail('Event Code', widget.eventCode),
                    _ticketSubDetail('Access Scope', participant.participantType.displayName),
                  ],
                ),
                if (participant.customFields.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: participant.customFields.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141926),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: GlassTheme.border),
                        ),
                        child: Text(
                          '${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value}',
                          style: GoogleFonts.robotoMono(fontSize: 10, color: GlassTheme.accentSky),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Copy & Share Button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: GlassTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16, color: GlassTheme.accentSky),
                    label: Text('Copy Pass Credentials', style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: 'GroundFlow Ticket Pass: ${participant.ticketPassCode}\nEvent: ${event['title']} (${widget.eventCode})\nAttendee: ${participant.name}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Ticket pass credentials copied to clipboard!'), backgroundColor: GlassTheme.accentEmerald),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketSubDetail(String label, String val) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.roboto(fontSize: 9.5, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
        const SizedBox(height: 2),
        Text(val, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  // ===========================================================================
  // 2. EVENT BRIEFING CARD
  // ===========================================================================
  Widget _buildEventBriefingCard(Map<String, dynamic> event) {
    final title = event['title'] as String? ?? widget.eventCode;
    final venue = extractEventVenue(event['venue'], fallback: 'Campus Venue');
    final desc = event['description'] as String? ?? 'Comprehensive operational summit and campus collaboration platform.';
    final category = event['category'] as String? ?? 'Departmental';

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(6)),
                child: Text(category, style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: GlassTheme.accentSky)),
              ),
              const Spacer(),
              const Icon(Icons.event_seat_rounded, size: 16, color: GlassTheme.mutedSilver),
              const SizedBox(width: 4),
              Text('Live Event Space', style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.mutedSilver)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text(desc, style: GoogleFonts.roboto(fontSize: 12.5, color: GlassTheme.mutedSilver, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: GlassTheme.accentEmerald),
              const SizedBox(width: 6),
              Expanded(
                child: Text(venue, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SELF-REGISTRATION FORM
  // ===========================================================================
  Widget _buildRegistrationFormCard(Map<String, dynamic> event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Self-Registration & Pass Issuance', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Enter your details to generate your digital gate access pass.', style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver)),
          const SizedBox(height: 16),

          _fieldLabel('Full Name *'),
          _textInput(_nameCtrl, 'Your full name'),
          const SizedBox(height: 12),

          _fieldLabel('Email Address *'),
          _textInput(_emailCtrl, 'name@organization.com'),
          const SizedBox(height: 12),

          _fieldLabel('Organization / Affiliation'),
          _textInput(_orgCtrl, 'e.g. University / Company name'),
          const SizedBox(height: 12),

          _fieldLabel('Role Type *'),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF0E0E12), borderRadius: BorderRadius.circular(8), border: Border.all(color: GlassTheme.border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ParticipantType>(
                dropdownColor: const Color(0xFF141418),
                value: _selectedType,
                isExpanded: true,
                style: GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                items: [ParticipantType.guest, ParticipantType.employee, ParticipantType.speaker, ParticipantType.vip, ParticipantType.volunteer]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          _fieldLabel('Dietary Preference'),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF0E0E12), borderRadius: BorderRadius.circular(8), border: Border.all(color: GlassTheme.border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF141418),
                value: _dietaryPref,
                isExpanded: true,
                style: GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                items: ['None', 'Vegetarian', 'Non-Vegetarian', 'Vegan', 'Jain Meal'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _dietaryPref = v);
                },
              ),
            ),
          ),
          if (_store.customFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 14, color: GlassTheme.accentSky),
                const SizedBox(width: 6),
                Text('Additional Custom Information', style: GoogleFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            ..._store.customFields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('${field.label}${field.isRequired ? " *" : ""}'),
                    if (field.type == CustomFieldType.dropdown && field.options.isNotEmpty)
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFF0E0E12), borderRadius: BorderRadius.circular(8), border: Border.all(color: GlassTheme.border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: const Color(0xFF141418),
                            value: _customFieldAnswers[field.key] as String? ?? field.options.first,
                            isExpanded: true,
                            style: GoogleFonts.roboto(fontSize: 13, color: Colors.white),
                            items: field.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _customFieldAnswers[field.key] = v);
                            },
                          ),
                        ),
                      )
                    else if (field.type == CustomFieldType.toggle)
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFF0E0E12), borderRadius: BorderRadius.circular(8), border: Border.all(color: GlassTheme.border)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(field.label, style: GoogleFonts.roboto(fontSize: 12.5, color: Colors.white)),
                            Switch(
                              value: _customFieldAnswers[field.key] == true,
                              activeColor: GlassTheme.accentEmerald,
                              onChanged: (v) => setState(() => _customFieldAnswers[field.key] = v),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 44,
                        decoration: BoxDecoration(color: const Color(0xFF0E0E12), borderRadius: BorderRadius.circular(8), border: Border.all(color: GlassTheme.border)),
                        child: TextField(
                          onChanged: (v) => _customFieldAnswers[field.key] = v.trim(),
                          style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
                          keyboardType: (field.type == CustomFieldType.number || field.type == CustomFieldType.currency)
                              ? TextInputType.number
                              : TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Enter ${field.label.toLowerCase()}',
                            hintStyle: GoogleFonts.roboto(color: const Color(0xFF52525B), fontSize: 12.5),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: _isRegistering ? null : _registerForEvent,
              child: _isRegistering
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('Issue My Digital Pass', style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerForEvent() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    if (name.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name and email address.'), backgroundColor: GlassTheme.statusRed),
      );
      return;
    }

    setState(() => _isRegistering = true);
    final messenger = ScaffoldMessenger.of(context);

    // Merge standard dietary into answers map if not already set
    if (_dietaryPref != 'None') {
      _customFieldAnswers['dietary_preference'] ??= _dietaryPref;
    }

    final success = await _store.addParticipant(
      name: name,
      email: email,
      phone: _phoneCtrl.text.trim(),
      organization: _orgCtrl.text.trim().isNotEmpty ? _orgCtrl.text.trim() : 'External Delegate',
      department: _selectedType.displayName,
      participantType: _selectedType,
      registrationStatus: RegistrationStatus.approved,
      customFields: Map<String, dynamic>.from(_customFieldAnswers),
    );

    setState(() => _isRegistering = false);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('✓ Registration complete! Your Digital Pass has been generated.'), backgroundColor: GlassTheme.accentEmerald),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Registration stored locally.'), backgroundColor: GlassTheme.accentAmber),
      );
    }
  }

  // ===========================================================================
  // 4. VENUE & LOGISTICAL FACILITIES
  // ===========================================================================
  Widget _buildVenueDetailsCard(Map<String, dynamic> event) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Venue Amenities & Logistics', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _amenityChip(Icons.wifi_rounded, 'High-Density Wi-Fi'),
              _amenityChip(Icons.local_parking_rounded, 'Dedicated Parking'),
              _amenityChip(Icons.accessible_rounded, 'Wheelchair Accessible'),
              _amenityChip(Icons.restaurant_rounded, 'Catering Booths'),
              _amenityChip(Icons.security_rounded, 'Perimeter Security'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GlassTheme.accentSky),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.roboto(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. COORDINATOR & HELP DESK
  // ===========================================================================
  Widget _buildCoordinatorCard(Map<String, dynamic> event) {
    final createdBy = event['createdBy'] as String? ?? 'organizer@groundflow.app';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.support_agent_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event Support & Coordinator', style: GoogleFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text('Contact: $createdBy', style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.mutedSilver)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
    );
  }

  Widget _textInput(TextEditingController ctrl, String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: const Color(0xFF0E0E12), borderRadius: BorderRadius.circular(8), border: Border.all(color: GlassTheme.border)),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(color: const Color(0xFF52525B), fontSize: 12.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
