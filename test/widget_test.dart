import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ground_flow/main.dart';
import 'package:ground_flow/core/state/ground_flow_realtime_store.dart';
import 'package:ground_flow/core/models/universal_event_model.dart';
import 'package:ground_flow/features/auth/groundflow_login_screen.dart';
import 'package:ground_flow/features/home/global_brand_home_screen.dart';
import 'package:ground_flow/features/workspace/event_operations_workspace_screen.dart';
import 'package:ground_flow/core/services/event_email_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'gf_auth': false});
    final store = GroundFlowRealtimeStore();
    await store.signOut();
  });

  testWidgets('GroundFlow Full Real User Auth, Real Event Creation & Navigation Flow Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: GroundFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State: Should display Login Screen with Google Sign In Exclusive
    expect(find.byType(GroundFlowLoginScreen), findsOneWidget);
    expect(find.text('GroundFlow'), findsWidgets);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Continue with Gmail Address'), findsOneWidget);

    // 2. Test Real User Google Authentication via Gmail Address
    final gmailField = find.byKey(const Key('gmail_input_field'));
    expect(gmailField, findsOneWidget);
    await tester.enterText(gmailField, 'rohan.sharma@gmail.com');
    await tester.pumpAndSettle();

    final continueBtn = find.byKey(const Key('continue_gmail_button'));
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // 3. Verification: Must navigate to Global Brand Home Page with Real User Name!
    expect(find.byType(GlobalBrandHomeScreen), findsOneWidget);
    expect(find.text('Welcome, Rohan sharma'), findsOneWidget);

    // 4. ZERO DUMMY EVENTS: Verified that it starts with NO dummy events!
    expect(find.text('Your Events (0)'), findsOneWidget);
    expect(find.text('No Events Created or Joined Yet'), findsOneWidget);

    // 5. Test Real Event Creation via Store
    final store = GroundFlowRealtimeStore();
    store.createEvent(
      title: 'Bharatiya Chhatra Sansad',
      venue: 'MIT-WPU Pune Campus',
      code: 'BCS-2026',
    );
    await tester.pumpAndSettle();

    // Now verified: The newly created real event appears under Your Events (1)!
    expect(find.text('Your Events (1)'), findsOneWidget);
    expect(find.text('Created by You (1)'), findsOneWidget);
    expect(find.textContaining('Bharatiya Chhatra Sansad'), findsWidgets);

    // 6. Tapping the whole event section redirects to Event Operations / Manage Page
    await tester.tap(find.textContaining('Bharatiya Chhatra Sansad').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Event Operations Workspace is rendered with Sections & Comms Channel
    expect(find.byType(EventOperationsWorkspaceScreen), findsOneWidget);
    expect(find.text('Communication Channel'), findsOneWidget);
    expect(find.text('#all-ops'), findsWidgets);
    expect(find.text('Venue & Space Logistics'), findsOneWidget);
    expect(find.text('Show QR'), findsOneWidget);

    // 7. Navigate back to Global Brand Home & Test Delete Event Option
    final backBtn = find.byIcon(Icons.arrow_back_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verify Delete Event button is present on the event card
    final deleteIconBtn = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteIconBtn, findsOneWidget);
    await tester.tap(deleteIconBtn);
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog
    expect(find.text('Delete Event'), findsWidgets);

    // Tap Confirm Delete
    final confirmDeleteBtn = find.widgetWithText(ElevatedButton, 'Delete Event');
    expect(confirmDeleteBtn, findsOneWidget);
    await tester.tap(confirmDeleteBtn);
    await tester.pumpAndSettle();

    // Verify event is deleted and empty state restored!
    expect(find.text('Your Events (0)'), findsOneWidget);
    expect(find.text('No Events Created or Joined Yet'), findsOneWidget);

    // 10. Verify that joining non-existent BCS-2026 FAILS and DOES NOT fabricate dummy data!
    final joinNonExistent = await store.joinEventWithPassword(code: 'BCS-2026', password: 'any');
    expect(joinNonExistent['success'], false);
    expect(store.events.isEmpty, true);

    // 11. Verify password protection on real events
    store.createEvent(
      title: 'Protected Annual Summit',
      venue: 'Main Auditorium',
      code: 'PAS-2026',
      password: 'SecurePass@2026',
    );
    expect(store.events.length, 1);

    // Attempt join with wrong password
    final wrongPassJoin = await store.joinEventWithPassword(code: 'PAS-2026', password: 'WrongPassword');
    expect(wrongPassJoin['success'], false);
    expect(wrongPassJoin['message'], contains('Incorrect password'));

    // Attempt join with correct password
    final correctPassJoin = await store.joinEventWithPassword(code: 'PAS-2026', password: 'SecurePass@2026');
    expect(correctPassJoin['success'], true);
  });

  test('Milestone 6: Universal Invitation Engine, Live Attendance Flow & CSV Audit Export Test', () async {
    final store = GroundFlowRealtimeStore();
    store.createEvent(
      title: 'Global Tech Conclave 2026',
      venue: 'Silicon Hall',
      code: 'GTC-2026',
    );

    // 1. Create Invitation Link & Toggle Status
    final created = await store.createInvitationLink(
      name: 'VIP Keynote Pass',
      type: InvitationLinkType.vip,
      maxUses: 50,
    );
    expect(created, true);
    expect(store.invitationLinks.any((l) => l.name == 'VIP Keynote Pass'), true);
    final link = store.invitationLinks.firstWhere((l) => l.name == 'VIP Keynote Pass');
    expect(link.isActive, true);

    await store.toggleInvitationLinkStatus(linkId: link.id, isActive: false);
    final revoked = store.invitationLinks.firstWhere((l) => l.id == link.id);
    expect(revoked.isActive, false);

    // 2. Add Participant & QR Check-in with Duplicate Prevention
    final added = await store.addParticipant(
      name: 'Dr. Jane Doe',
      email: 'jane.doe@techconclave.org',
      department: 'Keynote Speaker',
      participantType: ParticipantType.speaker,
    );
    expect(added, true);
    expect(store.participants.length, 1);
    final p = store.participants.first;
    expect(store.checkedInParticipantsCount, 0);

    // Initial QR check-in
    final checkIn1 = await store.checkInParticipantByQR(p.ticketPassCode);
    expect(checkIn1['success'], true);
    expect(store.checkedInParticipantsCount, 1);
    expect(store.recentArrivals.length, 1);
    expect(store.recentArrivals.first.name, 'Dr. Jane Doe');

    // Duplicate check-in prevention
    final checkIn2 = await store.checkInParticipantByQR(p.ticketPassCode);
    expect(checkIn2['success'], false);
    expect(checkIn2['duplicate'], true);
    expect(store.checkedInParticipantsCount, 1);

    // 3. Manual Attendance Override
    await store.toggleParticipantAttendance(participantId: p.id, status: AttendanceStatus.notAttended);
    expect(store.checkedInParticipantsCount, 0);

    await store.toggleParticipantAttendance(participantId: p.id, status: AttendanceStatus.checkedIn);
    expect(store.checkedInParticipantsCount, 1);

    // 4. CSV Audit Export Verification
    final csv = store.exportParticipantsCSV(store.events.first);
    expect(csv, contains('GROUNDFLOW PARTICIPANT LEDGER'));
    expect(csv, contains('Dr. Jane Doe'));
    expect(csv, contains('jane.doe@techconclave.org'));
    expect(csv, contains(p.ticketPassCode));
  });

  test('Milestone 7: Dynamic Custom Fields Engine, Attendee Responses & Department Team Squad Hub Test', () async {
    final store = GroundFlowRealtimeStore();
    store.createEvent(
      title: 'Global Autonomous Summit 2026',
      venue: 'Quantum Expo Center',
      code: 'GAS-2026',
    );

    // 1. Dynamic Custom Fields Engine: Add custom fields
    final addedField1 = await store.addCustomField(
      label: 'Dietary Preference',
      type: CustomFieldType.dropdown,
      options: ['Standard Omnivore', 'Vegetarian', 'Vegan', 'Halal', 'Kosher'],
      isRequired: true,
      department: 'Logistics & Hospitality',
    );
    expect(addedField1, true);

    final addedField2 = await store.addCustomField(
      label: 'Govt Photo ID',
      type: CustomFieldType.shortText,
      isRequired: true,
      department: 'Security & Access Control',
    );
    expect(addedField2, true);

    expect(store.customFields.any((f) => f.label == 'Dietary Preference'), true);
    expect(store.customFields.any((f) => f.label == 'Govt Photo ID'), true);

    // 2. Register Participant with Custom Field Answers
    final regSuccess = await store.addParticipant(
      name: 'Samantha Wright',
      email: 'samantha.wright@ai-summit.io',
      department: 'Keynote Speaker',
      participantType: ParticipantType.speaker,
      customFields: {
        'dietary_preference': 'Vegan',
        'govt_photo_id': 'PASSPORT-A98765432',
      },
    );
    expect(regSuccess, true);

    final samantha = store.participants.firstWhere((p) => p.email == 'samantha.wright@ai-summit.io');
    expect(samantha.customFields['dietary_preference'], 'Vegan');
    expect(samantha.customFields['govt_photo_id'], 'PASSPORT-A98765432');

    // 3. Department Team Workspace & Squad Roster
    final teamCreated = await store.createTeam(
      name: 'Alpha Response Squad',
      department: 'Security',
      teamLeader: 'Captain Miller',
      requiredHeadcount: 5,
      responsibilities: 'Gate perimeter enforcement & VIP escort.',
    );
    expect(teamCreated, true);

    final alphaTeam = store.teams.firstWhere((t) => t.name == 'Alpha Response Squad');
    expect(alphaTeam.members.isEmpty, true);

    // Add squad crew members
    await store.addTeamMember(teamId: alphaTeam.id, memberName: 'Officer Davis');
    await store.addTeamMember(teamId: alphaTeam.id, memberName: 'Officer Chen');

    final updatedTeam = store.teams.firstWhere((t) => t.id == alphaTeam.id);
    expect(updatedTeam.members.length, 2);
    expect(updatedTeam.members, contains('Officer Davis'));
    expect(updatedTeam.members, contains('Officer Chen'));

    // 4. Delete Custom Field verification
    await store.deleteCustomField('govt_photo_id');
    expect(store.customFields.any((f) => f.key == 'govt_photo_id'), false);
  });

  test('Milestone 8: RBAC Permissions, Department Head Volunteer Delegation & Owner Email Pass Confirmation', () async {
    final store = GroundFlowRealtimeStore();
    store.createEvent(
      title: 'National Leadership Conclave',
      venue: 'Vigyan Bhawan',
      code: 'NLC-2026',
      password: 'ConclaveLeader@2026',
      department: 'Security',
    );

    // 1. Verify Event Creator Role & Permissions
    final creatorRole = store.getUserRoleForEvent('NLC-2026');
    expect(creatorRole, EventRole.creator);

    final creatorPerms = store.getUserPermissions('NLC-2026');
    expect(creatorPerms.isCreator, true);
    expect(creatorPerms.canAssignRoles, true);
    expect(creatorPerms.canDeleteEvent, true);
    expect(creatorPerms.canManageVolunteersInDepartment('Security'), true);

    // 2. Verify Owner Email Confirmation & VIP Pass Generation
    final confirmation = store.latestOwnerConfirmation;
    expect(confirmation, isNotNull);
    expect(confirmation!.eventCode, 'NLC-2026');
    expect(confirmation.eventTitle, 'National Leadership Conclave');
    expect(confirmation.passcode, 'ConclaveLeader@2026');
    expect(confirmation.ownerPassCode, 'VIP-NLC-2026-OWNER');
    expect(confirmation.plainTextContent, contains('GROUNDFLOW ENTERPRISE EVENT CONFIRMATION'));
    expect(confirmation.plainTextContent, contains('VIP-NLC-2026-OWNER'));

    // 3. Register standard attendee and assign roles dynamically (Creator Privileges)
    await store.addParticipant(
      name: 'Rohan Deshmukh',
      email: 'rohan.deshmukh@conclave.org',
      department: 'Logistics',
      participantType: ParticipantType.employee,
    );

    final rohan = store.participants.firstWhere((p) => p.email == 'rohan.deshmukh@conclave.org');
    expect(rohan.assignedRole, 'Attendee');

    // Creator promotes Rohan to Department Head of Logistics
    final promoted = await store.assignParticipantRole(
      participantId: rohan.id,
      newRole: EventRole.departmentHead,
      department: 'Logistics',
    );
    expect(promoted, true);

    final updatedRohan = store.participants.firstWhere((p) => p.id == rohan.id);
    expect(updatedRohan.assignedRole, EventRole.departmentHead.displayName);
    expect(updatedRohan.department, 'Logistics');

    // 4. Department Head authority: Logistics Head recruits a volunteer under their department
    const headPerms = EventRolePermissions(role: EventRole.departmentHead, department: 'Logistics');
    expect(headPerms.canManageVolunteersInDepartment('Logistics'), true);
    expect(headPerms.canManageVolunteersInDepartment('Security'), false); // Cannot manage outside department!
    expect(headPerms.canDeleteEvent, false); // Only Creator can delete!

    final volunteerEnrolled = await store.assignVolunteerUnderDepartmentHead(
      department: 'Logistics',
      volunteerName: 'Aarav Mehta',
      volunteerEmail: 'aarav.mehta@volunteer.org',
    );
    expect(volunteerEnrolled, true);

    final aarav = store.participants.firstWhere((p) => p.email == 'aarav.mehta@volunteer.org');
    expect(aarav.assignedRole, EventRole.volunteer.displayName);
    expect(aarav.department, 'Logistics');
    expect(aarav.participantType, ParticipantType.volunteer);

    // 5. Verify Resending Owner Confirmation Email
    final resent = await store.resendOwnerConfirmationEmail('NLC-2026');
    expect(resent, isNotNull);
    expect(resent!.ownerPassCode, 'VIP-NLC-2026-OWNER');
  });

  testWidgets('Milestone 9: Automated Email Reminders Engine (1-Day, 2-Days, Guests, Volunteers & VIPs) Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final store = GroundFlowRealtimeStore();

    // 1. Create real event with a schedule 2 days from now
    final inTwoDays = DateTime.now().add(const Duration(days: 2)).toString().split(' ').first;
    store.createEvent(
      title: 'National Technology Conclave',
      venue: 'Innovation Hub Auditorium',
      code: 'NTC-2026',
      additionalData: {'startDate': inTwoDays},
    );

    // 2. Add sample Guest, Volunteer, and VIP
    await store.addParticipant(
      name: 'Dev Kumar',
      email: 'dev.kumar@guest.org',
      participantType: ParticipantType.guest,
    );
    await store.addParticipant(
      name: 'Riya Sen',
      email: 'riya.sen@volunteer.org',
      participantType: ParticipantType.volunteer,
      department: 'Security',
    );
    await store.addParticipant(
      name: 'Dr. Vikram Sarabhai',
      email: 'dr.vikram@vip.org',
      participantType: ParticipantType.vip,
    );

    // 3. Test Template Generator for 2 Days to Go (Guests vs Volunteers)
    final guestT2 = EventEmailService().generateReminderTemplate(
      event: store.currentEvent!,
      milestone: ReminderMilestone.twoDaysToGo,
      targetRole: ReminderTargetRole.guests,
    );
    expect(guestT2.subject.contains('2 Days to Go'), true);
    expect(guestT2.plainText.contains('Digital Ticket'), true);

    final volunteerT2 = EventEmailService().generateReminderTemplate(
      event: store.currentEvent!,
      milestone: ReminderMilestone.twoDaysToGo,
      targetRole: ReminderTargetRole.volunteers,
    );
    expect(volunteerT2.subject.contains('Volunteer Briefing'), true);
    expect(volunteerT2.plainText.contains('Squad Comms'), true);

    // 4. Test Template Generator for 1 Day to Go (Tomorrow)
    final volunteerT1 = EventEmailService().generateReminderTemplate(
      event: store.currentEvent!,
      milestone: ReminderMilestone.oneDayToGo,
      targetRole: ReminderTargetRole.volunteers,
    );
    expect(volunteerT1.subject.contains('Tomorrow: Action Stations!'), true);
    expect(volunteerT1.plainText.contains('07:30 AM Sharp'), true);

    final guestT1 = EventEmailService().generateReminderTemplate(
      event: store.currentEvent!,
      milestone: ReminderMilestone.oneDayToGo,
      targetRole: ReminderTargetRole.guests,
    );
    expect(guestT1.subject.contains('Tomorrow is the Day!'), true);
    expect(guestT1.plainText.contains('Fast-Track Gate'), true);

    // 5. Test Role-Targeted Email Gathering
    final volunteerRecipients = store.getRecipientsForTargetRole(ReminderTargetRole.volunteers);
    expect(volunteerRecipients.contains('riya.sen@volunteer.org'), true);

    final guestRecipients = store.getRecipientsForTargetRole(ReminderTargetRole.guests);
    expect(guestRecipients.contains('dev.kumar@guest.org'), true);

    final vipRecipients = store.getRecipientsForTargetRole(ReminderTargetRole.vips);
    expect(vipRecipients.contains('dr.vikram@vip.org'), true);

    // 6. Dispatch 2 Days to Go Reminder to Volunteers
    final dispatched = await store.dispatchEventReminder(
      milestone: ReminderMilestone.twoDaysToGo,
      targetRole: ReminderTargetRole.volunteers,
    );
    expect(dispatched, isNotNull);
    expect(dispatched!.eventCode, 'NTC-2026');
    expect(dispatched.milestone, ReminderMilestone.twoDaysToGo);
    expect(dispatched.targetRole, ReminderTargetRole.volunteers);
    expect(store.reminders.isNotEmpty, true);

    // 7. Verify UI Rendering in EventOperationsWorkspaceScreen
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: EventOperationsWorkspaceScreen(eventCode: 'NTC-2026'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Email & Automated Reminders Section is rendered!
    expect(find.text('Email & Automated Reminders'), findsOneWidget);
    expect(find.textContaining('Guests'), findsWidgets);
    expect(find.textContaining('Volunteers'), findsWidgets);
    expect(find.textContaining('VIPs'), findsWidgets);
    expect(find.text('New Reminder'), findsOneWidget);
  });

  testWidgets(
      'Milestone 10: Automated Welcome & Digital Pass Email, Colorful Cyber Template, Reminders to All & Gate Alerts Test',
      (tester) async {
    final store = GroundFlowRealtimeStore();
    await store.signInWithGoogle(
      name: 'Event Director',
      email: 'director@groundflow.app',
      role: AppRole.departmentHead,
    );

    // 1. Create Event
    store.createEvent(
      title: 'Global Tech Summit 2026',
      venue: 'Main Innovation Arena',
      code: 'GTS-2026',
    );

    // 2. Add Participants: Guest, Volunteer, and VIP Speaker
    await store.addParticipant(
      name: 'Ananya Roy',
      email: 'ananya.roy@guest.com',
      participantType: ParticipantType.guest,
    );
    await store.addParticipant(
      name: 'Kabir Verma',
      email: 'kabir.verma@volunteer.com',
      participantType: ParticipantType.volunteer,
      assignedTeam: 'Gate Squad',
    );
    await store.addParticipant(
      name: 'Dr. Sarah Connor',
      email: 'sarah.connor@keynote.com',
      participantType: ParticipantType.vip,
    );

    // 3. Verify Automated Welcome Email was dispatched for every participant
    final welcomeHistory = EventEmailService().welcomeHistory;
    expect(welcomeHistory.isNotEmpty, true);
    final ananyaWelcome = welcomeHistory.firstWhere((w) => w.participantEmail == 'ananya.roy@guest.com');
    expect(ananyaWelcome.eventCode, 'GTS-2026');
    expect(ananyaWelcome.participantRole, 'Guest');
    expect(ananyaWelcome.ticketPassCode, startsWith('GF-GTS-2026-'));

    // 4. Verify Colorful HTML Email Template matching GroundFlow dark-glass aesthetics
    expect(ananyaWelcome.htmlContent, contains('#38BDF8')); // Sky cyan
    expect(ananyaWelcome.htmlContent, contains('#10B981')); // Emerald
    expect(ananyaWelcome.htmlContent, contains('#0F1016')); // Dark glass
    expect(ananyaWelcome.htmlContent, contains('GroundFlow-Guest')); // WiFi
    expect(ananyaWelcome.htmlContent, contains('DIGITAL GATE ACCESS TOKEN'));

    // 5. Test Automated Batch Reminders to ALL Participants
    final reminderRes = await store.triggerAutomatedReminderToAll(
      milestone: ReminderMilestone.oneDayToGo,
      targetRole: ReminderTargetRole.all,
    );
    expect(reminderRes['success'], true);
    expect(reminderRes['recipientCount'], greaterThanOrEqualTo(3));
    expect(reminderRes['recipients'], contains('ananya.roy@guest.com'));
    expect(reminderRes['recipients'], contains('kabir.verma@volunteer.com'));
    expect(reminderRes['recipients'], contains('sarah.connor@keynote.com'));

    // 6. Test Gate Scanner Check-in & VIP Arrival Protocol
    final sarah = store.participants.firstWhere((p) => p.email == 'sarah.connor@keynote.com');
    final scanResult = await store.checkInParticipantByQR(sarah.ticketPassCode);
    expect(scanResult['success'], true);
    expect(scanResult['participant'].attendanceStatus, AttendanceStatus.checkedIn);

    // Verify activity stream logged check-in
    expect(store.participants.where((p) => p.attendanceStatus == AttendanceStatus.checkedIn).isNotEmpty, true);
  });
}
