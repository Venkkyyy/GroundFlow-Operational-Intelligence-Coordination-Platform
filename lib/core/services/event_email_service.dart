import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/universal_event_model.dart';
import 'firestore_service.dart';

/// Reminder Milestones supported by GroundFlow
enum ReminderMilestone {
  twoDaysToGo('2 Days to Go', 'T-2 Days'),
  oneDayToGo('1 Day to Go (Tomorrow)', 'T-1 Day'),
  eventDay('Happening Today', 'Today'),
  postEvent('Post-Event Wrap-up', 'Wrap Up'),
  custom('Operational Alert', 'Alert');

  final String title;
  final String badge;
  const ReminderMilestone(this.title, this.badge);

  static ReminderMilestone fromString(String val) {
    return ReminderMilestone.values.firstWhere(
      (m) => m.name.toLowerCase() == val.toLowerCase() || m.badge.toLowerCase() == val.toLowerCase(),
      orElse: () => ReminderMilestone.twoDaysToGo,
    );
  }
}

/// Target Roles for Email Reminders
enum ReminderTargetRole {
  all('All Participants & Staff', 'All'),
  guests('Guests & Attendees Only', 'Guests'),
  volunteers('Volunteers & Squad Crew Only', 'Volunteers'),
  vips('VIPs & Keynote Speakers Only', 'VIPs');

  final String title;
  final String label;
  const ReminderTargetRole(this.title, this.label);

  static ReminderTargetRole fromString(String val) {
    return ReminderTargetRole.values.firstWhere(
      (r) => r.name.toLowerCase() == val.toLowerCase() || r.label.toLowerCase() == val.toLowerCase(),
      orElse: () => ReminderTargetRole.all,
    );
  }
}

/// Content bundle holding subject, plain text, and HTML formatting
class EventReminderContent {
  final String subject;
  final String plainText;
  final String html;

  const EventReminderContent({
    required this.subject,
    required this.plainText,
    required this.html,
  });
}

/// GroundFlow Event Reminder Data Model
class EventReminderModel {
  final String id;
  final String eventCode;
  final String eventTitle;
  final ReminderMilestone milestone;
  final ReminderTargetRole targetRole;
  final int recipientCount;
  final List<String> recipients;
  final String subject;
  final String plainTextContent;
  final String htmlContent;
  final DateTime sentAt;
  final String sentBy;
  final String deliveryMethod;

  const EventReminderModel({
    required this.id,
    required this.eventCode,
    required this.eventTitle,
    required this.milestone,
    required this.targetRole,
    required this.recipientCount,
    required this.recipients,
    required this.subject,
    required this.plainTextContent,
    required this.htmlContent,
    required this.sentAt,
    required this.sentBy,
    this.deliveryMethod = 'Cloud & Email Relay',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventCode': eventCode,
    'eventTitle': eventTitle,
    'milestone': milestone.name,
    'targetRole': targetRole.name,
    'recipientCount': recipientCount,
    'recipients': recipients,
    'subject': subject,
    'plainTextContent': plainTextContent,
    'htmlContent': htmlContent,
    'sentAt': sentAt.toIso8601String(),
    'sentBy': sentBy,
    'deliveryMethod': deliveryMethod,
  };

  factory EventReminderModel.fromJson(Map<String, dynamic> json) {
    return EventReminderModel(
      id: json['id'] as String? ?? '',
      eventCode: json['eventCode'] as String? ?? '',
      eventTitle: json['eventTitle'] as String? ?? '',
      milestone: ReminderMilestone.fromString(json['milestone'] as String? ?? 'twoDaysToGo'),
      targetRole: ReminderTargetRole.fromString(json['targetRole'] as String? ?? 'all'),
      recipientCount: json['recipientCount'] as int? ?? (json['recipients'] is List ? (json['recipients'] as List).length : 0),
      recipients: json['recipients'] is List ? List<String>.from(json['recipients']) : [],
      subject: json['subject'] as String? ?? '',
      plainTextContent: json['plainTextContent'] as String? ?? '',
      htmlContent: json['htmlContent'] as String? ?? '',
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now() : DateTime.now(),
      sentBy: json['sentBy'] as String? ?? 'Organizer',
      deliveryMethod: json['deliveryMethod'] as String? ?? 'Cloud & Email Relay',
    );
  }
}

/// GroundFlow Event Confirmation & Owner Pass Email Model
class EventEmailConfirmation {
  final String id;
  final String eventId;
  final String recipientEmail;
  final String ownerName;
  final String eventTitle;
  final String eventCode;
  final String passcode;
  final String ownerPassCode;
  final String venue;
  final String schedule;
  final String timezone;
  final String organizingDepartment;
  final DateTime sentAt;

  const EventEmailConfirmation({
    required this.id,
    required this.eventId,
    required this.recipientEmail,
    required this.ownerName,
    required this.eventTitle,
    required this.eventCode,
    required this.passcode,
    required this.ownerPassCode,
    required this.venue,
    required this.schedule,
    required this.timezone,
    required this.organizingDepartment,
    required this.sentAt,
  });

  String get subject => '[GroundFlow] Official Event Confirmation & Owner VIP Pass: $eventTitle ($eventCode)';

  String get plainTextContent => '''
================================================================================
GROUNDFLOW ENTERPRISE EVENT CONFIRMATION & OWNER PASS
================================================================================

Hello ${ownerName.isNotEmpty ? ownerName : 'Event Creator'},

Your event "$eventTitle" has been initialized and synchronized with GroundFlow Central Cloud.
Below are your credentials, recovery keys, and VIP digital pass code. Keep this email safe.

--------------------------------------------------------------------------------
EVENT CREDENTIALS & ACCESS KEYS
--------------------------------------------------------------------------------
• Event Title        : $eventTitle
• Event Code (ID)    : $eventCode
• Security Passcode  : ${passcode.isNotEmpty ? passcode : 'Open Access (No Password)'}
• Primary Department : $organizingDepartment
• Venue / Location   : $venue
• Event Schedule     : $schedule
• Timezone           : $timezone

--------------------------------------------------------------------------------
YOUR ORGANIZER VIP DIGITAL PASS
--------------------------------------------------------------------------------
• Owner Pass Token   : $ownerPassCode
• Privilege Level    : Super Administrator / Event Creator
• Gate Entry Status  : Universal All-Access VIP

--------------------------------------------------------------------------------
DISASTER RECOVERY & RE-LOGIN
--------------------------------------------------------------------------------
If you switch devices or log out:
1. Open GroundFlow App.
2. Sign in with $recipientEmail.
3. Your event "$eventCode" will automatically restore from GroundFlow Cloud.
4. You can also join via "Join Event" using Code: $eventCode and Passcode: ${passcode.isNotEmpty ? passcode : '(None)'}.

Need support or real-time assistance?
Access GroundFlow Central Workspace or consult the live audit ledger.

Issued by GroundFlow Cloud Operations Engine
Timestamp: ${sentAt.toIso8601String()}
================================================================================
''';

  String get mailtoUrl {
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(plainTextContent);
    return 'mailto:$recipientEmail?subject=$encodedSubject&body=$encodedBody';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'recipientEmail': recipientEmail,
    'ownerName': ownerName,
    'eventTitle': eventTitle,
    'eventCode': eventCode,
    'passcode': passcode,
    'ownerPassCode': ownerPassCode,
    'venue': venue,
    'schedule': schedule,
    'timezone': timezone,
    'organizingDepartment': organizingDepartment,
    'sentAt': sentAt.toIso8601String(),
    'subject': subject,
  };

  factory EventEmailConfirmation.fromJson(Map<String, dynamic> json) {
    return EventEmailConfirmation(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      recipientEmail: json['recipientEmail'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? 'Event Creator',
      eventTitle: json['eventTitle'] as String? ?? '',
      eventCode: json['eventCode'] as String? ?? '',
      passcode: json['passcode'] as String? ?? '',
      ownerPassCode: json['ownerPassCode'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'UTC',
      organizingDepartment: json['organizingDepartment'] as String? ?? 'General',
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Official Participant Welcome & Digital Pass Email Model
class ParticipantWelcomeEmail {
  final String id;
  final String eventId;
  final String eventCode;
  final String eventTitle;
  final String participantName;
  final String participantEmail;
  final String participantRole;
  final String ticketPassCode;
  final String venue;
  final String schedule;
  final String subject;
  final String plainTextContent;
  final String htmlContent;
  final DateTime sentAt;

  const ParticipantWelcomeEmail({
    required this.id,
    required this.eventId,
    required this.eventCode,
    required this.eventTitle,
    required this.participantName,
    required this.participantEmail,
    required this.participantRole,
    required this.ticketPassCode,
    required this.venue,
    required this.schedule,
    required this.subject,
    required this.plainTextContent,
    required this.htmlContent,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'eventCode': eventCode,
    'eventTitle': eventTitle,
    'participantName': participantName,
    'participantEmail': participantEmail,
    'participantRole': participantRole,
    'ticketPassCode': ticketPassCode,
    'venue': venue,
    'schedule': schedule,
    'subject': subject,
    'plainTextContent': plainTextContent,
    'htmlContent': htmlContent,
    'sentAt': sentAt.toIso8601String(),
  };

  factory ParticipantWelcomeEmail.fromJson(Map<String, dynamic> json) {
    return ParticipantWelcomeEmail(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      eventCode: json['eventCode'] as String? ?? '',
      eventTitle: json['eventTitle'] as String? ?? '',
      participantName: json['participantName'] as String? ?? 'Participant',
      participantEmail: json['participantEmail'] as String? ?? '',
      participantRole: json['participantRole'] as String? ?? 'Attendee',
      ticketPassCode: json['ticketPassCode'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      plainTextContent: json['plainTextContent'] as String? ?? '',
      htmlContent: json['htmlContent'] as String? ?? '',
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Service to compile, dispatch, and persist Event Emails and Countdown Reminders
class EventEmailService {
  static final EventEmailService _instance = EventEmailService._internal();
  factory EventEmailService() => _instance;
  EventEmailService._internal();

  final List<EventEmailConfirmation> _sentHistory = [];
  List<EventEmailConfirmation> get sentHistory => List.unmodifiable(_sentHistory);

  final List<EventReminderModel> _reminderHistory = [];
  List<EventReminderModel> get reminderHistory => List.unmodifiable(_reminderHistory);

  final List<ParticipantWelcomeEmail> _welcomeHistory = [];
  List<ParticipantWelcomeEmail> get welcomeHistory => List.unmodifiable(_welcomeHistory);

  EventEmailConfirmation? getLatestConfirmationForEvent(String eventCode) {
    try {
      return _sentHistory.lastWhere((e) => e.eventCode.toUpperCase() == eventCode.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  List<EventReminderModel> getRemindersForEvent(String eventCode) {
    return _reminderHistory.where((r) => r.eventCode.toUpperCase() == eventCode.toUpperCase()).toList();
  }

  /// Launch email via web Gmail composer directly
  Future<bool> launchGmailWeb({
    required String recipientEmail,
    required String subject,
    required String body,
    List<String>? bcc,
  }) async {
    try {
      final bccParam = (bcc != null && bcc.isNotEmpty) ? '&bcc=${Uri.encodeComponent(bcc.join(','))}' : '';
      final url = 'https://mail.google.com/mail/?view=cm&fs=1&to=${Uri.encodeComponent(recipientEmail)}$bccParam&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Launch Gmail web notice: $e');
      return false;
    }
  }

  /// Universal Email Launcher: tries platform default mail handler, then falls back to Gmail web
  Future<bool> launchEmail({
    required String recipientEmail,
    required String subject,
    required String body,
    List<String>? bcc,
  }) async {
    try {
      final queryParams = <String, String>{
        'subject': subject,
        'body': body,
      };
      if (bcc != null && bcc.isNotEmpty) {
        queryParams['bcc'] = bcc.join(',');
      }
      final Uri uri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        queryParameters: queryParams,
      );

      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (ok) return true;
      }

      // Try direct parse fallback
      final direct = Uri.parse(uri.toString());
      if (await canLaunchUrl(direct)) {
        final ok = await launchUrl(direct, mode: LaunchMode.platformDefault);
        if (ok) return true;
      }

      // Fallback to Gmail Web
      return await launchGmailWeb(
        recipientEmail: recipientEmail,
        subject: subject,
        body: body,
        bcc: bcc,
      );
    } catch (e) {
      debugPrint('Launch email app notice: $e');
      return await launchGmailWeb(
        recipientEmail: recipientEmail,
        subject: subject,
        body: body,
        bcc: bcc,
      );
    }
  }

  /// Compatibility wrapper for existing launchEmailApp
  Future<bool> launchEmailApp(EventEmailConfirmation confirmation) async {
    return await launchEmail(
      recipientEmail: confirmation.recipientEmail,
      subject: confirmation.subject,
      body: confirmation.plainTextContent,
    );
  }

  /// Compile and send confirmation email to the event owner
  Future<EventEmailConfirmation> sendOwnerEventConfirmation({
    required Map<String, dynamic> event,
    required String ownerEmail,
    String? ownerName,
  }) async {
    final code = (event['code'] as String? ?? 'EVENT').toUpperCase().trim();
    final title = event['title'] as String? ?? 'GroundFlow Event';
    final venue = extractEventVenue(event['venue'], fallback: 'Designated Event Venue');
    final password = event['password'] as String? ?? '';
    final dept = event['department'] as String? ?? (event['departments'] is List && (event['departments'] as List).isNotEmpty ? event['departments'][0].toString() : 'General Operations');
    final tz = event['timezone'] as String? ?? 'Asia/Kolkata';
    final startDate = event['startDate'] as String? ?? DateTime.now().toString().split(' ').first;
    final endDate = event['endDate'] as String? ?? startDate;
    final scheduleStr = '$startDate to $endDate ($tz)';
    final ownerPass = 'VIP-$code-OWNER';

    final confirmation = EventEmailConfirmation(
      id: 'CONF-$code-${DateTime.now().millisecondsSinceEpoch}',
      eventId: code,
      recipientEmail: ownerEmail.trim().toLowerCase(),
      ownerName: ownerName?.trim() ?? ownerEmail.split('@').first,
      eventTitle: title,
      eventCode: code,
      passcode: password,
      ownerPassCode: ownerPass,
      venue: venue,
      schedule: scheduleStr,
      timezone: tz,
      organizingDepartment: dept,
      sentAt: DateTime.now(),
    );

    _sentHistory.add(confirmation);

    // 1. Persist to Cloud Firestore under event subcollection 'email_confirmations'
    await FirestoreService().saveEmailConfirmation(eventCode: code, confirmation: confirmation);

    // 2. Log in activity stream
    try {
      await FirestoreService().logEventActivity(
        eventCode: code,
        userEmail: ownerEmail,
        action: 'OWNER_CONFIRMATION_EMAILED',
        details: 'Official Event Confirmation & VIP Pass ($ownerPass) compiled and sent to $ownerEmail',
      );
    } catch (_) {}

    debugPrint('✓ Event Email Confirmation generated & saved for $ownerEmail (Event: $code)');
    return confirmation;
  }

  /// Compile and send colorful Welcome & Digital Pass email to any attendee/guest/volunteer
  Future<ParticipantWelcomeEmail> sendParticipantWelcomeEmail({
    required Map<String, dynamic> event,
    required EventParticipantModel participant,
  }) async {
    final code = (event['code'] as String? ?? participant.eventId).toUpperCase().trim();
    final title = event['title'] as String? ?? 'GroundFlow Event';
    final venue = extractEventVenue(event['venue'], fallback: 'Designated Event Venue');
    final startDate = event['startDate'] as String? ?? DateTime.now().toString().split(' ').first;
    final endDate = event['endDate'] as String? ?? startDate;
    final scheduleStr = '$startDate to $endDate';
    final roleName = participant.participantType.displayName;
    final cleanEmail = participant.email.trim().toLowerCase();

    final subject = '🎫 [GroundFlow Pass] Welcome to $title ($code) - Your Digital Entry Pass';

    final plainText = '''
================================================================================
GROUNDFLOW ENTERPRISE EVENT CONFIRMATION & DIGITAL PASS
================================================================================

Hello \${participant.name.isNotEmpty ? participant.name : 'Participant'},

Welcome to "$title" ($code)!
Your registration is officially confirmed and registered in GroundFlow Central Cloud.

--------------------------------------------------------------------------------
YOUR DIGITAL GATE ENTRY PASS
--------------------------------------------------------------------------------
• Pass Holder       : \${participant.name} ($cleanEmail)
• Role Category     : $roleName
• Event Title       : $title
• Event Code        : $code
• Pass Token        : \${participant.ticketPassCode}
• Venue Location    : $venue
• Event Schedule    : $scheduleStr

--------------------------------------------------------------------------------
CHECK-IN & ARRIVAL INSTRUCTIONS
--------------------------------------------------------------------------------
1. Present your Pass Token (\${participant.ticketPassCode}) or QR code on arrival.
2. Fast-Track Check-In: Hold your pass to any GroundFlow Gate Scanner kiosk.
3. Campus Wi-Fi Network: GroundFlow-Guest (Password: GroundFlow2026).
4. Real-time tracks and announcements are live in GroundFlow App.

We look forward to hosting you!

Issued by GroundFlow Cloud Autonomous Operations Engine
Timestamp: \${DateTime.now().toIso8601String()}
================================================================================
''';

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#08080B;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#FFFFFF;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#08080B;padding:24px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width:600px;background-color:#0F1016;border-radius:20px;border:1px solid #27272A;overflow:hidden;box-shadow:0 12px 40px rgba(0,0,0,0.8);">
          <tr>
            <td style="height:4px;background:linear-gradient(90deg, #38BDF8 0%, #818CF8 50%, #10B981 100%);"></td>
          </tr>
          <tr>
            <td style="padding:28px 28px 16px 28px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                <tr>
                  <td>
                    <div style="display:inline-block;background:#FFFFFF;color:#000000;font-weight:900;font-size:15px;padding:6px 14px;border-radius:10px;letter-spacing:-0.4px;">
                      ⬡ GroundFlow
                    </div>
                    <div style="color:#71717A;font-size:11px;font-weight:600;margin-top:6px;letter-spacing:0.5px;">
                      CAMPUS &amp; SUMMIT VOLUNTEER OPERATIONS TERMINAL
                    </div>
                  </td>
                  <td align="right">
                    <span style="background:rgba(16,185,129,0.15);color:#10B981;border:1px solid #10B981;padding:5px 12px;border-radius:20px;font-size:10px;font-weight:800;letter-spacing:0.8px;display:inline-block;">
                      ✓ CONFIRMED PASS
                    </span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 20px 28px;">
              <h1 style="color:#FFFFFF;font-size:24px;font-weight:800;letter-spacing:-0.5px;margin:0 0 8px 0;line-height:1.2;">
                Welcome to $title!
              </h1>
              <p style="color:#A1A1AA;font-size:13.5px;line-height:1.55;margin:0;">
                Hello <strong>\${participant.name}</strong>, your registration is confirmed! Below is your official digital entry pass for gate access.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 24px 28px;">
              <div style="background:linear-gradient(135deg, #141724 0%, #10121A 100%);border:1.5px solid #38BDF8;border-radius:16px;padding:24px;box-shadow:0 0 25px rgba(56,189,248,0.15);">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                  <tr>
                    <td>
                      <span style="background:#38BDF8;color:#000000;font-weight:900;font-size:10.5px;padding:4px 10px;border-radius:6px;letter-spacing:0.8px;display:inline-block;">
                        \${roleName.toUpperCase()} PASS
                      </span>
                    </td>
                    <td align="right">
                      <span style="color:#71717A;font-family:monospace;font-size:11px;font-weight:700;">
                        EVENT CODE: <strong style="color:#38BDF8;">$code</strong>
                      </span>
                    </td>
                  </tr>
                </table>
                <div style="margin:20px 0 16px 0;text-align:center;background:#090A0F;border:1px dashed #38BDF8;border-radius:12px;padding:16px;">
                  <div style="color:#94A3B8;font-size:10.5px;font-weight:700;letter-spacing:1px;margin-bottom:4px;">
                    DIGITAL GATE ACCESS TOKEN
                  </div>
                  <div style="color:#38BDF8;font-family:monospace;font-size:24px;font-weight:900;letter-spacing:2px;">
                    \${participant.ticketPassCode}
                  </div>
                  <div style="color:#10B981;font-size:11px;font-weight:700;margin-top:6px;">
                    ⚡ Universal Turnstile &amp; Scanner Clearance
                  </div>
                </div>
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top:14px;border-top:1px solid #1E293B;padding-top:14px;">
                  <tr>
                    <td width="50%" style="vertical-align:top;padding-right:8px;">
                      <div style="color:#64748B;font-size:10px;font-weight:700;letter-spacing:0.5px;text-transform:uppercase;">VENUE &amp; HALL</div>
                      <div style="color:#F1F5F9;font-size:12.5px;font-weight:700;margin-top:2px;">$venue</div>
                    </td>
                    <td width="50%" style="vertical-align:top;padding-left:8px;">
                      <div style="color:#64748B;font-size:10px;font-weight:700;letter-spacing:0.5px;text-transform:uppercase;">TIMELINE &amp; DATES</div>
                      <div style="color:#F1F5F9;font-size:12.5px;font-weight:700;margin-top:2px;">$scheduleStr</div>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 24px 28px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#13141C;border-radius:12px;border:1px solid #27272A;padding:18px;">
                <tr>
                  <td>
                    <div style="color:#38BDF8;font-size:12px;font-weight:800;letter-spacing:0.5px;margin-bottom:8px;">
                      🚀 ARRIVAL &amp; CHECK-IN GUIDELINES
                    </div>
                    <ul style="color:#CBD5E1;font-size:12px;line-height:1.6;margin:0;padding-left:18px;">
                      <li>Present this email or save your <strong>Digital Pass Code (\${participant.ticketPassCode})</strong> on your phone.</li>
                      <li>Hold your phone up to the GroundFlow Gate Scanner at any entrance kiosk for instant check-in.</li>
                      <li>Campus WiFi Network: <strong>GroundFlow-Guest</strong> (Password: <strong>GroundFlow2026</strong>).</li>
                      <li>Live schedule and track announcements update continuously in the GroundFlow App.</li>
                    </ul>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 28px;background:#0A0B0E;border-top:1px solid #1E2028;text-align:center;">
              <p style="color:#64748B;font-size:11px;margin:0 0 6px 0;">
                Dispatched automatically by GroundFlow Real-Time Operations Engine
              </p>
              <p style="color:#475569;font-family:monospace;font-size:10px;margin:0;">
                SEC-HASH: SHA256-\${participant.ticketPassCode.hashCode.abs()} • \${DateTime.now().toIso8601String()}
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';

    final welcomeEmail = ParticipantWelcomeEmail(
      id: 'WELC-$code-\${DateTime.now().millisecondsSinceEpoch}',
      eventId: code,
      eventCode: code,
      eventTitle: title,
      participantName: participant.name,
      participantEmail: cleanEmail,
      participantRole: roleName,
      ticketPassCode: participant.ticketPassCode,
      venue: venue,
      schedule: scheduleStr,
      subject: subject,
      plainTextContent: plainText,
      htmlContent: html,
      sentAt: DateTime.now(),
    );

    _welcomeHistory.add(welcomeEmail);

    // Save and queue to Firestore and Cloud relay
    if (cleanEmail.isNotEmpty && cleanEmail.contains('@')) {
      await FirestoreService().saveParticipantWelcomeEmail(
        eventCode: code,
        participantEmail: cleanEmail,
        subject: subject,
        plainTextContent: plainText,
        htmlContent: html,
        emailPayload: welcomeEmail.toJson(),
      );
    }

    try {
      await FirestoreService().logEventActivity(
        eventCode: code,
        userEmail: cleanEmail,
        action: 'PARTICIPANT_PASS_EMAILED',
        details: 'Automated Welcome & Digital Pass (\${participant.ticketPassCode}) dispatched to $cleanEmail ($roleName)',
      );
    } catch (_) {}

    debugPrint('✓ Automated Welcome & Pass Email dispatched to $cleanEmail (Event: $code)');
    return welcomeEmail;
  }

  /// Generate rich role-specific reminder templates (2 Days, 1 Day, Event Day, Wrap-up)
  EventReminderContent generateReminderTemplate({
    required Map<String, dynamic> event,
    required ReminderMilestone milestone,
    required ReminderTargetRole targetRole,
    String? organizerName,
  }) {
    final code = (event['code'] as String? ?? 'EVENT').toUpperCase().trim();
    final title = event['title'] as String? ?? 'GroundFlow Event';
    final venue = extractEventVenue(event['venue'], fallback: 'Campus Main Arena');
    final password = event['password'] as String? ?? '';
    final startDate = event['startDate'] as String? ?? DateTime.now().toString().split(' ').first;
    final endDate = event['endDate'] as String? ?? startDate;
    final organizer = organizerName ?? 'GroundFlow Operations Team';

    String subject = '';
    String plainText = '';

    switch (milestone) {
      case ReminderMilestone.twoDaysToGo:
        if (targetRole == ReminderTargetRole.volunteers) {
          subject = '📢 [Volunteer Briefing: 2 Days to Go] Squad Duty & Shift Roster - $title ($code)';
          plainText = '''
================================================================================
GROUNDFLOW VOLUNTEER OPERATIONS: 2 DAYS TO GO BRIEFING
================================================================================

Hello Squad Member / Volunteer,

We are exactly 2 DAYS AWAY from "$title" ($code)!
Here is your operational readiness briefing and checklist:

--------------------------------------------------------------------------------
DUTY STATIONS & REPORTING TIMELINE
--------------------------------------------------------------------------------
• Event Code        : $code
• Venue             : $venue
• Event Date        : $startDate to $endDate
• Volunteer Report  : 1 Hour Prior to General Attendee Gates
• Squad Comms       : Active on GroundFlow #all-ops & department channels

--------------------------------------------------------------------------------
VOLUNTEER CHECKLIST (NEXT 48 HOURS)
--------------------------------------------------------------------------------
1. Open GroundFlow App and confirm your department assignment.
2. Check in with your Squad Lead via the Comms Radio tab.
3. Collect your Volunteer Lanyard & RFID/QR pass at Gate 1 on arrival.
4. Dress Code: Designated event polo/badge and comfortable footwear.

If you have questions or duty conflicts, report them in GroundFlow immediately.

Issued by $organizer & GroundFlow Operations Hub
================================================================================
''';
        } else if (targetRole == ReminderTargetRole.vips) {
          subject = '⭐ [VIP Briefing: 2 Days to Go] Access Pass & Arrival Protocol - $title ($code)';
          plainText = '''
================================================================================
GROUNDFLOW VIP & KEYNOTE SPEAKER BRIEFING: 2 DAYS TO GO
================================================================================

Distinguished Guest,

We are honored to welcome you to "$title" ($code) in 2 days.
Below is your priority access itinerary and escort details:

--------------------------------------------------------------------------------
EXECUTIVE ARRIVAL & PROTOCOL
--------------------------------------------------------------------------------
• Event Title        : $title
• Code               : $code
• Venue              : $venue
• VIP Gate Entry     : Gate A (Priority Escort & Reserved Parking)
• Schedule           : $startDate to $endDate

--------------------------------------------------------------------------------
VIP PRIVILEGES & GREEN ROOM ACCESS
--------------------------------------------------------------------------------
• Digital VIP Pass   : VIP-$code-ALL-ACCESS
• Green Room / Lounge: Central Executive Pavilion
• Stage AV Liaison   : Dedicated coordinator on standby on arrival
• Wi-Fi & Workspaces : High-speed enterprise network active

Our Protocol Lead will greet you at Gate A upon arrival.

Warm regards,
$organizer
GroundFlow Central Operations
================================================================================
''';
        } else {
          // Guests & All
          subject = '⏰ [2 Days to Go] Access Pass & Venue Instructions - $title ($code)';
          plainText = '''
================================================================================
GROUNDFLOW ATTENDEE REMINDER: 2 DAYS TO GO!
================================================================================

Dear Participant,

Only 48 hours to go until "$title" ($code)!
Get ready for an incredible campus experience. Here is your essential guide:

--------------------------------------------------------------------------------
EVENT DETAILS & VENUE
--------------------------------------------------------------------------------
• Event Title        : $title
• Event ID / Code    : $code
• Venue Location     : $venue
• Dates              : $startDate to $endDate
• Security Passcode  : ${password.isNotEmpty ? password : 'Open (No password required)'}

--------------------------------------------------------------------------------
ENTRY GUIDELINES & DIGITAL PASS
--------------------------------------------------------------------------------
1. Digital Ticket: Keep your digital pass QR code open on your phone.
2. Fast-Track Kiosks: Scan your QR code at any entry turnstile for instant check-in.
3. Timings: Gates open 45 minutes prior to first keynote.
4. What to Bring: Government/Campus Photo ID & your GroundFlow Digital Ticket.

Need help or directions? Access the live portal in the GroundFlow App.

We look forward to seeing you!
$organizer
================================================================================
''';
        }
        break;

      case ReminderMilestone.oneDayToGo:
        if (targetRole == ReminderTargetRole.volunteers) {
          subject = '⚡ [Tomorrow: Action Stations!] Final Volunteer Roll Call - $title ($code)';
          plainText = '''
================================================================================
GROUNDFLOW VOLUNTEERS: TOMORROW IS EXECUTION DAY!
================================================================================

Squad Crew,

Tomorrow is the big day! "$title" ($code) goes live in 24 hours.

--------------------------------------------------------------------------------
FINAL SHIFT ROLL CALL & INSTRUCTIONS
--------------------------------------------------------------------------------
• Reporting Time    : 07:30 AM Sharp at Central Hub (Gate 1)
• Venue             : $venue
• Kit Pickup        : ID Badge, Radio headset & Volunteer pass
• Rapid Gate Scan   : Ensure your GroundFlow App scanner is synced

Stay tuned on GroundFlow Comms `#all-ops` for real-time dispatches throughout tomorrow.

Let's make this event extraordinary!
$organizer
================================================================================
''';
        } else if (targetRole == ReminderTargetRole.vips) {
          subject = '⚡ [Tomorrow!] VIP Stage Itinerary & Host Welcome - $title ($code)';
          plainText = '''
================================================================================
GROUNDFLOW VIP & KEYNOTE: TOMORROW IS THE EVENT!
================================================================================

Distinguished Guest,

We look forward to hosting you tomorrow at "$title" ($code).
Your executive team is on standby at Gate A.

• Keynote Venue     : $venue
• Arrival Reception : Gate A Executive Lounge
• Direct Coordinator: Standby at Arrival

Warm regards,
$organizer
================================================================================
''';
        } else {
          subject = '⚡ [Tomorrow is the Day!] Gate Entry & Live Schedule - $title ($code)';
          plainText = '''
================================================================================
GROUNDFLOW ATTENDEES: TOMORROW IS THE DAY!
================================================================================

Hello,

The wait is almost over! "$title" ($code) starts TOMORROW.

--------------------------------------------------------------------------------
FAST-TRACK ARRIVAL INSTRUCTIONS
--------------------------------------------------------------------------------
• Venue             : $venue
• Check-in Opens    : 08:30 AM
• Fast-Track Gate   : Show your GroundFlow Digital Pass QR at entry
• Live Timetable    : Real-time track schedule is live in your GroundFlow portal

Travel safe, arrive early, and prepare for an exceptional day!

See you tomorrow,
$organizer
================================================================================
''';
        }
        break;

      case ReminderMilestone.eventDay:
        if (targetRole == ReminderTargetRole.volunteers) {
          subject = '🚨 [Event Day: Stations Active!] Live Squad Operational Protocol - $title ($code)';
          plainText = '''
================================================================================
ALL VOLUNTEER STATIONS ACTIVE: $title IS LIVE!
================================================================================

Squad,

Today is the day! All teams are on live operational mode:
• Reporting         : Report to your department leads immediately.
• Gate Scanners     : Launch Rapid Scanner in GroundFlow.
• Radio             : `#all-ops` and squad channels are live.

Have a powerful, seamless execution!
$organizer
================================================================================
''';
        } else {
          subject = '🚨 [Happening Today!] Gates Are Open - Welcome to $title ($code)';
          plainText = '''
================================================================================
$title IS LIVE TODAY!
================================================================================

Welcome to "$title"! Gates are officially open at $venue.

• Event Code        : $code
• Location          : $venue
• Entry             : Scan your QR at Gate Kiosks
• Live Comms & Help : Contact Info Desk or open GroundFlow Live Portal

Have a phenomenal day!
$organizer
================================================================================
''';
        }
        break;

      case ReminderMilestone.postEvent:
        subject = '🎉 [Thank You!] Certificate & Event Wrap-up - $title ($code)';
        plainText = '''
================================================================================
THANK YOU FOR JOINING $title!
================================================================================

Dear Participant,

Thank you for being part of "$title" ($code) at $venue.
Your attendance has been recorded in the GroundFlow official audit ledger.

• Verified Status  : Attended
• Event Code       : $code
• Certificates     : Accessible through your GroundFlow Participant Portal

We hope you had a fantastic experience!

With gratitude,
$organizer
================================================================================
''';
        break;

      case ReminderMilestone.custom:
        subject = '📢 [Important Notice] $title ($code) Operational Update';
        plainText = '''
================================================================================
GROUNDFLOW OPERATIONAL NOTICE: $title ($code)
================================================================================

Dear Participant / Squad Member,

Please take note of the following operational briefing for "$title":
• Event Venue       : $venue
• Event Code        : $code
• Schedule          : $startDate to $endDate

Please check your GroundFlow portal for real-time track updates and room allocations.

Issued by $organizer
================================================================================
''';
        break;
    }

    final html = '''
<div style="font-family:'Segoe UI',Roboto,Helvetica,sans-serif;max-width:640px;margin:auto;padding:24px;background:#09090b;color:#f4f4f5;border-radius:16px;border:1px solid #27272a;">
  <div style="border-bottom:1px solid #27272a;padding-bottom:16px;margin-bottom:20px;">
    <span style="background:#1e293b;color:#38bdf8;padding:4px 10px;border-radius:20px;font-size:11px;font-weight:700;letter-spacing:0.5px;">${milestone.badge}</span>
    <span style="background:#14532d;color:#4ade80;padding:4px 10px;border-radius:20px;font-size:11px;font-weight:700;margin-left:6px;">${targetRole.label}</span>
    <h2 style="color:#ffffff;margin:12px 0 4px 0;font-size:20px;letter-spacing:-0.3px;">$title</h2>
    <p style="color:#a1a1aa;margin:0;font-size:12px;">Official GroundFlow Notification • Code: <strong>$code</strong></p>
  </div>
  <pre style="background:#141418;padding:16px;border-radius:10px;color:#e4e4e7;white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.5;border:1px solid #27272a;">$plainText</pre>
  <div style="margin-top:20px;padding-top:14px;border-top:1px solid #27272a;text-align:center;">
    <p style="color:#71717a;font-size:11px;margin:0;">Dispatched via GroundFlow Unified Event Operations Engine</p>
  </div>
</div>
''';

    return EventReminderContent(subject: subject, plainText: plainText, html: html);
  }

  /// Dispatch an official Event Reminder to attendees and squad
  Future<EventReminderModel> dispatchReminder({
    required Map<String, dynamic> event,
    required ReminderMilestone milestone,
    required ReminderTargetRole targetRole,
    required List<String> recipients,
    required String senderEmail,
    String? customSubject,
    String? customBody,
  }) async {
    final code = (event['code'] as String? ?? 'EVENT').toUpperCase().trim();
    final title = event['title'] as String? ?? 'GroundFlow Event';

    final template = generateReminderTemplate(
      event: event,
      milestone: milestone,
      targetRole: targetRole,
      organizerName: senderEmail.split('@').first,
    );

    final subject = customSubject?.trim().isNotEmpty == true ? customSubject!.trim() : template.subject;
    final plainText = customBody?.trim().isNotEmpty == true ? customBody!.trim() : template.plainText;

    final reminder = EventReminderModel(
      id: 'REM-$code-${milestone.name}-${DateTime.now().millisecondsSinceEpoch}',
      eventCode: code,
      eventTitle: title,
      milestone: milestone,
      targetRole: targetRole,
      recipientCount: recipients.length,
      recipients: recipients,
      subject: subject,
      plainTextContent: plainText,
      htmlContent: template.html,
      sentAt: DateTime.now(),
      sentBy: senderEmail,
      deliveryMethod: 'Cloud Firestore Queue & Gmail Relay',
    );

    _reminderHistory.add(reminder);

    // Save to Firestore subcollection and queue
    await FirestoreService().saveEventReminder(eventCode: code, reminder: reminder);

    debugPrint('✓ Event Reminder [${milestone.badge}] dispatched for $code to ${recipients.length} recipients');
    return reminder;
  }

  /// Automated Batch Dispatcher: Dispatches reminder emails to ALL participants registered for the event
  Future<Map<String, dynamic>> sendAutomatedRemindersToAll({
    required Map<String, dynamic> event,
    required List<EventParticipantModel> participants,
    required ReminderMilestone milestone,
    required String senderEmail,
    ReminderTargetRole targetRole = ReminderTargetRole.all,
  }) async {
    final code = (event['code'] as String? ?? 'EVENT').toUpperCase().trim();
    List<String> targetRecipients;

    if (targetRole == ReminderTargetRole.volunteers) {
      targetRecipients = participants
          .where((p) => p.participantType == ParticipantType.volunteer)
          .map((p) => p.email.trim().toLowerCase())
          .where((e) => e.contains('@'))
          .toSet()
          .toList();
    } else if (targetRole == ReminderTargetRole.vips) {
      targetRecipients = participants
          .where((p) => p.participantType == ParticipantType.vip)
          .map((p) => p.email.trim().toLowerCase())
          .where((e) => e.contains('@'))
          .toSet()
          .toList();
    } else if (targetRole == ReminderTargetRole.guests) {
      targetRecipients = participants
          .where((p) => p.participantType == ParticipantType.guest || p.participantType == ParticipantType.employee)
          .map((p) => p.email.trim().toLowerCase())
          .where((e) => e.contains('@'))
          .toSet()
          .toList();
    } else {
      targetRecipients = participants
          .map((p) => p.email.trim().toLowerCase())
          .where((e) => e.contains('@'))
          .toSet()
          .toList();
    }

    if (targetRecipients.isEmpty && senderEmail.contains('@')) {
      targetRecipients = [senderEmail.trim().toLowerCase()];
    }

    final reminder = await dispatchReminder(
      event: event,
      milestone: milestone,
      targetRole: targetRole,
      recipients: targetRecipients,
      senderEmail: senderEmail,
    );

    return {
      'success': true,
      'eventCode': code,
      'reminderId': reminder.id,
      'milestone': milestone.title,
      'targetRole': targetRole.title,
      'recipientCount': reminder.recipientCount,
      'recipients': targetRecipients,
      'message': '✓ Dispatched ${milestone.title} reminder to ${reminder.recipientCount} participants!',
    };
  }
}
