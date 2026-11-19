import 'package:flutter/foundation.dart';

// =============================================================================
// ENUMS FOR UNIVERSAL EVENT SYSTEM
// =============================================================================

enum EventCategory {
  internal,
  externalEvent,
  corporate,
  departmental,
  training,
  workshop,
  conference,
  meeting,
  celebration,
  productLaunch,
  campaign,
  emergencyIncident,
  other;

  String get displayName {
    switch (this) {
      case EventCategory.internal:
        return 'Internal';
      case EventCategory.externalEvent:
        return 'External';
      case EventCategory.corporate:
        return 'Corporate';
      case EventCategory.departmental:
        return 'Departmental';
      case EventCategory.training:
        return 'Training';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.conference:
        return 'Conference';
      case EventCategory.meeting:
        return 'Meeting';
      case EventCategory.celebration:
        return 'Celebration';
      case EventCategory.productLaunch:
        return 'Product Launch';
      case EventCategory.campaign:
        return 'Campaign';
      case EventCategory.emergencyIncident:
        return 'Emergency / Incident';
      case EventCategory.other:
        return 'Other';
    }
  }

  static EventCategory fromString(String val) {
    return EventCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => EventCategory.departmental,
    );
  }
}

enum EventPriority {
  critical,
  high,
  medium,
  low;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static EventPriority fromString(String val) {
    return EventPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => EventPriority.medium,
    );
  }
}

enum EventStatus {
  draft,
  planned,
  approved,
  active,
  completed,
  cancelled;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static EventStatus fromString(String val) {
    return EventStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => EventStatus.planned,
    );
  }
}

enum LocationMode {
  physical,
  online,
  hybrid;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static LocationMode fromString(String val) {
    return LocationMode.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => LocationMode.physical,
    );
  }
}

enum ApprovalType {
  single,
  sequential,
  parallel;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

enum RegistrationType {
  open,
  invitationOnly;

  String get displayName => this == RegistrationType.open ? 'Open' : 'Invitation Only';
}

enum EventVisibility {
  private,
  organization,
  department,
  public,
  unlisted;

  String get displayName {
    switch (this) {
      case EventVisibility.private:
        return 'Private (Invited Only)';
      case EventVisibility.organization:
        return 'Organization Members';
      case EventVisibility.department:
        return 'Selected Departments';
      case EventVisibility.public:
        return 'Public Landing Page';
      case EventVisibility.unlisted:
        return 'Unlisted (Shared Link)';
    }
  }

  static EventVisibility fromString(String val) {
    return EventVisibility.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => EventVisibility.organization,
    );
  }
}

enum EventLifecycleState {
  draft,
  pendingApproval,
  approved,
  published,
  preparation,
  live,
  completed,
  cancelled,
  closed;

  String get displayName {
    switch (this) {
      case EventLifecycleState.draft:
        return 'Draft';
      case EventLifecycleState.pendingApproval:
        return 'Pending Approval';
      case EventLifecycleState.approved:
        return 'Approved';
      case EventLifecycleState.published:
        return 'Published';
      case EventLifecycleState.preparation:
        return 'In Preparation';
      case EventLifecycleState.live:
        return 'Live Operations';
      case EventLifecycleState.completed:
        return 'Completed';
      case EventLifecycleState.cancelled:
        return 'Cancelled';
      case EventLifecycleState.closed:
        return 'Archived & Closed';
    }
  }

  static EventLifecycleState fromString(String val) {
    return EventLifecycleState.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => EventLifecycleState.published,
    );
  }
}

enum CustomFieldType {
  shortText,
  longText,
  number,
  currency,
  date,
  dropdown,
  toggle,
  url;

  String get displayName {
    switch (this) {
      case CustomFieldType.shortText:
        return 'Short Text';
      case CustomFieldType.longText:
        return 'Long Text';
      case CustomFieldType.number:
        return 'Number';
      case CustomFieldType.currency:
        return 'Currency (₹)';
      case CustomFieldType.date:
        return 'Date';
      case CustomFieldType.dropdown:
        return 'Single Select (Dropdown)';
      case CustomFieldType.toggle:
        return 'Yes / No Toggle';
      case CustomFieldType.url:
        return 'Web Link / URL';
    }
  }

  static CustomFieldType fromString(String val) {
    return CustomFieldType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => CustomFieldType.shortText,
    );
  }
}

enum InvitationLinkType {
  general,
  public,
  restricted,
  department,
  singleUse,
  vip;

  String get displayName {
    switch (this) {
      case InvitationLinkType.general:
        return 'General Registration';
      case InvitationLinkType.public:
        return 'Public Link';
      case InvitationLinkType.restricted:
        return 'Restricted (Approval Required)';
      case InvitationLinkType.department:
        return 'Department Pass';
      case InvitationLinkType.singleUse:
        return 'Single-Use VIP Pass';
      case InvitationLinkType.vip:
        return 'VIP Delegation';
    }
  }

  static InvitationLinkType fromString(String val) {
    return InvitationLinkType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => InvitationLinkType.general,
    );
  }
}

enum ParticipantType {
  employee,
  guest,
  vip,
  speaker,
  organizer,
  volunteer,
  vendor,
  security,
  media;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static ParticipantType fromString(String val) {
    return ParticipantType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ParticipantType.employee,
    );
  }
}

enum RegistrationStatus {
  pending,
  approved,
  rejected,
  cancelled,
  waitlisted;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static RegistrationStatus fromString(String val) {
    return RegistrationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RegistrationStatus.approved,
    );
  }
}

enum AttendanceStatus {
  notAttended,
  checkedIn,
  checkedOut;

  String get displayName {
    switch (this) {
      case AttendanceStatus.notAttended:
        return 'Not Checked In';
      case AttendanceStatus.checkedIn:
        return 'Checked In';
      case AttendanceStatus.checkedOut:
        return 'Checked Out';
    }
  }

  static AttendanceStatus fromString(String val) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AttendanceStatus.notAttended,
    );
  }
}

// =============================================================================
// ROLE-BASED ACCESS CONTROL (RBAC) & PERMISSIONS
// =============================================================================

enum EventRole {
  creator,
  departmentHead,
  coordinator,
  volunteer,
  participant;

  String get displayName {
    switch (this) {
      case EventRole.creator:
        return 'Event Creator / Super Admin';
      case EventRole.departmentHead:
        return 'Department Head';
      case EventRole.coordinator:
        return 'Operations Coordinator';
      case EventRole.volunteer:
        return 'Field Squad Volunteer';
      case EventRole.participant:
        return 'Registered Attendee';
    }
  }

  static EventRole fromString(String val) {
    final clean = val.toLowerCase().trim();
    if (clean.contains('creator') || clean.contains('owner') || clean.contains('admin')) {
      return EventRole.creator;
    }
    if (clean.contains('head') || clean.contains('lead') || clean.contains('manager')) {
      return EventRole.departmentHead;
    }
    if (clean.contains('coordinator')) {
      return EventRole.coordinator;
    }
    if (clean.contains('volunteer') || clean.contains('crew') || clean.contains('squad')) {
      return EventRole.volunteer;
    }
    return EventRole.participant;
  }
}

class EventRolePermissions {
  final EventRole role;
  final String? department;

  const EventRolePermissions({required this.role, this.department});

  bool get isCreator => role == EventRole.creator;
  bool get isDepartmentHead => role == EventRole.departmentHead || isCreator;
  bool get isCoordinator => role == EventRole.coordinator || isDepartmentHead;
  bool get isVolunteer => role == EventRole.volunteer || isCoordinator;

  bool get canAssignRoles => isCreator;
  bool get canDeleteEvent => isCreator;
  bool get canEditEventSettings => isCreator;
  bool get canManageBudget => isCreator || role == EventRole.departmentHead;
  
  bool canManageVolunteersInDepartment(String targetDept) {
    if (isCreator) return true;
    if (role == EventRole.departmentHead) {
      return department == null || department?.toLowerCase().trim() == targetDept.toLowerCase().trim();
    }
    return false;
  }

  bool canCreateTasksInDepartment(String targetDept) {
    if (isCreator) return true;
    if (role == EventRole.departmentHead || role == EventRole.coordinator) {
      return department == null || department?.toLowerCase().trim() == targetDept.toLowerCase().trim();
    }
    return false;
  }

  bool get canScanTickets => isVolunteer; // Volunteers, Coordinators, Heads, Creator can scan tickets!
  bool get canBroadcastAlerts => isCoordinator; // Coordinator, Head, Creator
}

// =============================================================================
// SUB-MODELS
// =============================================================================

@immutable
class ScheduleInfo {
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final String timeZone;
  final bool isAllDay;
  final bool isMultiDay;
  final DateTime? setupStart;
  final int setupDurationHours;
  final DateTime? breakdownStart;
  final int breakdownDurationHours;
  final DateTime? registrationDeadline;
  final DateTime? rehearsalDate;
  final int bufferMinutes;
  final String recurrence;

  const ScheduleInfo({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.timeZone = 'Asia/Kolkata',
    this.isAllDay = false,
    this.isMultiDay = false,
    this.setupStart,
    this.setupDurationHours = 2,
    this.breakdownStart,
    this.breakdownDurationHours = 2,
    this.registrationDeadline,
    this.rehearsalDate,
    this.bufferMinutes = 15,
    this.recurrence = 'Does not repeat',
  });

  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'startTime': startTime,
    'endTime': endTime,
    'timeZone': timeZone,
    'isAllDay': isAllDay,
    'isMultiDay': isMultiDay,
    'setupStart': setupStart?.toIso8601String(),
    'setupDurationHours': setupDurationHours,
    'breakdownStart': breakdownStart?.toIso8601String(),
    'breakdownDurationHours': breakdownDurationHours,
    'registrationDeadline': registrationDeadline?.toIso8601String(),
    'rehearsalDate': rehearsalDate?.toIso8601String(),
    'bufferMinutes': bufferMinutes,
    'recurrence': recurrence,
  };

  factory ScheduleInfo.fromJson(Map<String, dynamic> json) {
    return ScheduleInfo(
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 1)),
      startTime: json['startTime'] as String? ?? '09:00 AM',
      endTime: json['endTime'] as String? ?? '05:00 PM',
      timeZone: json['timeZone'] as String? ?? 'Asia/Kolkata',
      isAllDay: json['isAllDay'] as bool? ?? false,
      isMultiDay: json['isMultiDay'] as bool? ?? false,
      setupStart: json['setupStart'] != null ? DateTime.tryParse(json['setupStart'] as String) : null,
      setupDurationHours: json['setupDurationHours'] as int? ?? 2,
      breakdownStart: json['breakdownStart'] != null ? DateTime.tryParse(json['breakdownStart'] as String) : null,
      breakdownDurationHours: json['breakdownDurationHours'] as int? ?? 2,
      registrationDeadline: json['registrationDeadline'] != null ? DateTime.tryParse(json['registrationDeadline'] as String) : null,
      rehearsalDate: json['rehearsalDate'] != null ? DateTime.tryParse(json['rehearsalDate'] as String) : null,
      bufferMinutes: json['bufferMinutes'] as int? ?? 15,
      recurrence: json['recurrence'] as String? ?? 'Does not repeat',
    );
  }
}

@immutable
class VenueInfo {
  final LocationMode locationMode;
  final String venueName;
  final String venueType;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pinCode;
  final String indoorOutdoor;
  final int totalCapacity;
  final List<String> facilities;
  // Online / Hybrid specifics
  final String? virtualPlatform;
  final String? virtualMeetingUrl;
  final String? virtualMeetingPasscode;
  final String? technicalHost;

  const VenueInfo({
    required this.locationMode,
    required this.venueName,
    this.venueType = 'Auditorium',
    this.address = '',
    this.city = 'Pune',
    this.state = 'Maharashtra',
    this.country = 'India',
    this.pinCode = '',
    this.indoorOutdoor = 'Indoor',
    this.totalCapacity = 500,
    this.facilities = const ['Wi-Fi', 'Projector', 'Audio System', 'Microphones', 'Seating', 'Washrooms', 'Power Backup'],
    this.virtualPlatform,
    this.virtualMeetingUrl,
    this.virtualMeetingPasscode,
    this.technicalHost,
  });

  Map<String, dynamic> toJson() => {
    'locationMode': locationMode.name,
    'venueName': venueName,
    'venueType': venueType,
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'pinCode': pinCode,
    'indoorOutdoor': indoorOutdoor,
    'totalCapacity': totalCapacity,
    'facilities': facilities,
    'virtualPlatform': virtualPlatform,
    'virtualMeetingUrl': virtualMeetingUrl,
    'virtualMeetingPasscode': virtualMeetingPasscode,
    'technicalHost': technicalHost,
  };

  factory VenueInfo.fromJson(Map<String, dynamic> json) {
    return VenueInfo(
      locationMode: LocationMode.fromString(json['locationMode'] as String? ?? 'physical'),
      venueName: json['venueName'] as String? ?? 'Campus Arena',
      venueType: json['venueType'] as String? ?? 'Auditorium',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? 'Pune',
      state: json['state'] as String? ?? 'Maharashtra',
      country: json['country'] as String? ?? 'India',
      pinCode: json['pinCode'] as String? ?? '',
      indoorOutdoor: json['indoorOutdoor'] as String? ?? 'Indoor',
      totalCapacity: json['totalCapacity'] as int? ?? 500,
      facilities: (json['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['Wi-Fi', 'Projector', 'Audio System', 'Microphones', 'Seating', 'Washrooms', 'Power Backup'],
      virtualPlatform: json['virtualPlatform'] as String?,
      virtualMeetingUrl: json['virtualMeetingUrl'] as String?,
      virtualMeetingPasscode: json['virtualMeetingPasscode'] as String?,
      technicalHost: json['technicalHost'] as String?,
    );
  }
}

@immutable
class DepartmentOwnership {
  final String primaryDepartment;
  final String organizingDepartment;
  final List<String> participatingDepartments;
  final String eventOwnerEmail;
  final String departmentHeadEmail;
  final String coordinatorEmail;
  final List<String> coOrganizers;
  final List<String> supportingDepartments;

  const DepartmentOwnership({
    required this.primaryDepartment,
    required this.organizingDepartment,
    this.participatingDepartments = const [],
    required this.eventOwnerEmail,
    required this.departmentHeadEmail,
    required this.coordinatorEmail,
    this.coOrganizers = const [],
    this.supportingDepartments = const ['Administration', 'Security', 'Media'],
  });

  Map<String, dynamic> toJson() => {
    'primaryDepartment': primaryDepartment,
    'organizingDepartment': organizingDepartment,
    'participatingDepartments': participatingDepartments,
    'eventOwnerEmail': eventOwnerEmail,
    'departmentHeadEmail': departmentHeadEmail,
    'coordinatorEmail': coordinatorEmail,
    'coOrganizers': coOrganizers,
    'supportingDepartments': supportingDepartments,
  };

  factory DepartmentOwnership.fromJson(Map<String, dynamic> json) {
    return DepartmentOwnership(
      primaryDepartment: json['primaryDepartment'] as String? ?? 'Operations',
      organizingDepartment: json['organizingDepartment'] as String? ?? 'Operations',
      participatingDepartments: (json['participatingDepartments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      eventOwnerEmail: json['eventOwnerEmail'] as String? ?? '',
      departmentHeadEmail: json['departmentHeadEmail'] as String? ?? '',
      coordinatorEmail: json['coordinatorEmail'] as String? ?? '',
      coOrganizers: (json['coOrganizers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      supportingDepartments: (json['supportingDepartments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Administration', 'Security', 'Media'],
    );
  }
}

@immutable
class HeadcountBreakdown {
  final int expectedTotalAttendance;
  final int maxCapacity;
  final int minRequiredAttendance;
  final int expectedEmployees;
  final int expectedExternalGuests;
  final int vipGuests;
  final int speakers;
  final int volunteers;
  final int organizingCommittee;
  final int staffMembers;
  final int vendors;
  final int securityPersonnel;
  final int mediaPersonnel;

  const HeadcountBreakdown({
    this.expectedTotalAttendance = 250,
    this.maxCapacity = 300,
    this.minRequiredAttendance = 50,
    this.expectedEmployees = 150,
    this.expectedExternalGuests = 100,
    this.vipGuests = 5,
    this.speakers = 4,
    this.volunteers = 30,
    this.organizingCommittee = 12,
    this.staffMembers = 15,
    this.vendors = 6,
    this.securityPersonnel = 8,
    this.mediaPersonnel = 6,
  });

  Map<String, dynamic> toJson() => {
    'expectedTotalAttendance': expectedTotalAttendance,
    'maxCapacity': maxCapacity,
    'minRequiredAttendance': minRequiredAttendance,
    'expectedEmployees': expectedEmployees,
    'expectedExternalGuests': expectedExternalGuests,
    'vipGuests': vipGuests,
    'speakers': speakers,
    'volunteers': volunteers,
    'organizingCommittee': organizingCommittee,
    'staffMembers': staffMembers,
    'vendors': vendors,
    'securityPersonnel': securityPersonnel,
    'mediaPersonnel': mediaPersonnel,
  };

  factory HeadcountBreakdown.fromJson(Map<String, dynamic> json) {
    return HeadcountBreakdown(
      expectedTotalAttendance: json['expectedTotalAttendance'] as int? ?? 250,
      maxCapacity: json['maxCapacity'] as int? ?? 300,
      minRequiredAttendance: json['minRequiredAttendance'] as int? ?? 50,
      expectedEmployees: json['expectedEmployees'] as int? ?? 150,
      expectedExternalGuests: json['expectedExternalGuests'] as int? ?? 100,
      vipGuests: json['vipGuests'] as int? ?? 5,
      speakers: json['speakers'] as int? ?? 4,
      volunteers: json['volunteers'] as int? ?? 30,
      organizingCommittee: json['organizingCommittee'] as int? ?? 12,
      staffMembers: json['staffMembers'] as int? ?? 15,
      vendors: json['vendors'] as int? ?? 6,
      securityPersonnel: json['securityPersonnel'] as int? ?? 8,
      mediaPersonnel: json['mediaPersonnel'] as int? ?? 6,
    );
  }
}

@immutable
class BudgetInfo {
  final double estimatedBudget;
  final double approvedBudget;
  final double actualExpense;
  final double contingencyBudget;
  final String fundingDepartment;
  final String costCenter;

  const BudgetInfo({
    this.estimatedBudget = 50000.0,
    this.approvedBudget = 50000.0,
    this.actualExpense = 0.0,
    this.contingencyBudget = 5000.0,
    this.fundingDepartment = 'Operations',
    this.costCenter = 'CC-EVENTS-2026',
  });

  double get remainingBudget => approvedBudget - actualExpense;

  Map<String, dynamic> toJson() => {
    'estimatedBudget': estimatedBudget,
    'approvedBudget': approvedBudget,
    'actualExpense': actualExpense,
    'contingencyBudget': contingencyBudget,
    'fundingDepartment': fundingDepartment,
    'costCenter': costCenter,
  };

  factory BudgetInfo.fromJson(Map<String, dynamic> json) {
    return BudgetInfo(
      estimatedBudget: (json['estimatedBudget'] as num?)?.toDouble() ?? 50000.0,
      approvedBudget: (json['approvedBudget'] as num?)?.toDouble() ?? 50000.0,
      actualExpense: (json['actualExpense'] as num?)?.toDouble() ?? 0.0,
      contingencyBudget: (json['contingencyBudget'] as num?)?.toDouble() ?? 5000.0,
      fundingDepartment: json['fundingDepartment'] as String? ?? 'Operations',
      costCenter: json['costCenter'] as String? ?? 'CC-EVENTS-2026',
    );
  }
}

@immutable
class SafetyEmergencyConfig {
  final String riskAssessment; // Low, Medium, High
  final String emergencyContact;
  final bool medicalTeamRequired;
  final bool firstAidAvailability;
  final bool fireSafetyArrangements;
  final String evacuationAssemblyPoint;
  final int securityPersonnelCount;

  const SafetyEmergencyConfig({
    this.riskAssessment = 'Low',
    this.emergencyContact = '+91 98765 43210',
    this.medicalTeamRequired = true,
    this.firstAidAvailability = true,
    this.fireSafetyArrangements = true,
    this.evacuationAssemblyPoint = 'Campus East Ground Gate 2',
    this.securityPersonnelCount = 8,
  });

  Map<String, dynamic> toJson() => {
    'riskAssessment': riskAssessment,
    'emergencyContact': emergencyContact,
    'medicalTeamRequired': medicalTeamRequired,
    'firstAidAvailability': firstAidAvailability,
    'fireSafetyArrangements': fireSafetyArrangements,
    'evacuationAssemblyPoint': evacuationAssemblyPoint,
    'securityPersonnelCount': securityPersonnelCount,
  };

  factory SafetyEmergencyConfig.fromJson(Map<String, dynamic> json) {
    return SafetyEmergencyConfig(
      riskAssessment: json['riskAssessment'] as String? ?? 'Low',
      emergencyContact: json['emergencyContact'] as String? ?? '+91 98765 43210',
      medicalTeamRequired: json['medicalTeamRequired'] as bool? ?? true,
      firstAidAvailability: json['firstAidAvailability'] as bool? ?? true,
      fireSafetyArrangements: json['fireSafetyArrangements'] as bool? ?? true,
      evacuationAssemblyPoint: json['evacuationAssemblyPoint'] as String? ?? 'Campus East Ground Gate 2',
      securityPersonnelCount: json['securityPersonnelCount'] as int? ?? 8,
    );
  }
}

// =============================================================================
// DEPARTMENT TEMPLATES
// =============================================================================

class DepartmentTemplate {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String defaultPrimaryDept;
  final EventCategory defaultCategory;
  final Map<String, dynamic> dynamicFields;
  final List<String> defaultTasks;
  final List<String> participatingDepartments;

  const DepartmentTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.defaultPrimaryDept,
    required this.defaultCategory,
    required this.dynamicFields,
    required this.defaultTasks,
    required this.participatingDepartments,
  });

  static const List<DepartmentTemplate> allTemplates = [
    DepartmentTemplate(
      id: 'template_hr',
      name: 'HR Training & Employee Event',
      icon: 'people',
      description: 'Employee onboarding, internal training, certifications, and cultural celebrations.',
      defaultPrimaryDept: 'Human Resources',
      defaultCategory: EventCategory.training,
      dynamicFields: {
        'trainerName': 'Lead Corporate Trainer',
        'trainingObjectives': 'Team alignment, skills upgrade, and compliance certification.',
        'attendanceRequirement': 'Mandatory (100% check-in required for credits)',
        'materialsProvided': 'Handbook, Digital LMS credentials, Assessment Kit',
      },
      defaultTasks: [
        'Send training calendar invite to registered employees',
        'Provision LMS course assessment portal',
        'Verify attendance with biometric / QR check-in',
        'Issue completion digital certificates',
      ],
      participatingDepartments: ['Human Resources', 'Administration', 'IT'],
    ),
    DepartmentTemplate(
      id: 'template_marketing',
      name: 'Marketing Campaign & Launch',
      icon: 'campaign',
      description: 'Product launches, sponsor campaigns, PR press meets, and branding activations.',
      defaultPrimaryDept: 'Marketing',
      defaultCategory: EventCategory.productLaunch,
      dynamicFields: {
        'campaignName': 'GroundFlow Q1 Launch',
        'targetAudience': 'Campus delegates, industry sponsors, and tech media',
        'marketingChannels': 'LinkedIn, Instagram Live, Campus Radio, Press Release',
        'expectedReach': '50,000+ impressions',
        'sponsorsList': 'Google Developers, Local Campus Partners',
      },
      defaultTasks: [
        'Finalize banner backdrop and LED wall visuals',
        'Prepare press kits and delegate gift bags',
        'Coordinate live social media stream team',
        'Review sponsor stage placement and logos',
      ],
      participatingDepartments: ['Marketing', 'Media', 'Design', 'Finance'],
    ),
    DepartmentTemplate(
      id: 'template_engineering',
      name: 'IT & Engineering Deployment / Hackathon',
      icon: 'code',
      description: 'System rollouts, hackathons, technical workshops, and server maintenance windows.',
      defaultPrimaryDept: 'Engineering / IT',
      defaultCategory: EventCategory.workshop,
      dynamicFields: {
        'systemsInvolved': 'Primary Cloud Ledger, Local NAS Cluster, Wi-Fi 6 Routers',
        'technicalOwner': 'Lead Cloud SRE',
        'deploymentSchedule': 'Pre-event staging verification at T-4h',
        'rollbackPlan': 'Instant snapshot restore to local SQLite container',
      },
      defaultTasks: [
        'Deploy dedicated high-bandwidth Wi-Fi SSID for venue',
        'Setup local NAS storage dump for high-resolution video streams',
        'Perform load test on QR verification backend',
        'Standby technical on-call rotation during keynote',
      ],
      participatingDepartments: ['Engineering / IT', 'Operations', 'Security'],
    ),
    DepartmentTemplate(
      id: 'template_finance',
      name: 'Finance & Annual General Meeting',
      icon: 'account_balance',
      description: 'Investor meets, fiscal audits, budget reconciliations, and board conferences.',
      defaultPrimaryDept: 'Finance',
      defaultCategory: EventCategory.corporate,
      dynamicFields: {
        'costCenter': 'CC-FIN-GLOBAL-2026',
        'budgetApprovalLimit': '₹5,00,000 INR',
        'paymentMilestones': '50% Advance, 50% Post-Audit Settlement',
        'auditLedgerRequired': 'Yes (Receipt verification mandatory)',
      },
      defaultTasks: [
        'Validate vendor advance payment vouchers',
        'Record on-site catering invoice approvals',
        'Reconcile actual vs approved budget variance',
        'Generate fiscal compliance summary report',
      ],
      participatingDepartments: ['Finance', 'Administration', 'Operations'],
    ),
    DepartmentTemplate(
      id: 'template_operations',
      name: 'Campus Summit & Volunteer Operations',
      icon: 'hub',
      description: 'Multi-track campus summits, stage AV coordination, volunteer dispatch, and gear custody.',
      defaultPrimaryDept: 'Operations',
      defaultCategory: EventCategory.conference,
      dynamicFields: {
        'operationalLead': 'Ground Operations Commander',
        'shiftSchedule': 'Morning Crew (08:00–14:00), Evening Crew (14:00–21:00)',
        'equipmentCustody': 'FX3 Cameras, Radio Walkie-talkies, Wireless Mics',
        'contingencyPlan': 'Backup stage generator and localized offline mesh',
      },
      defaultTasks: [
        'Distribute gear kits with signed custody tokens',
        'Execute Anti-Cheat rotating QR volunteer check-in',
        'Run OR-Tools travel-aware shoot schedule dispatch',
        'Monitor live 5-minute squad incident escalation queue',
      ],
      participatingDepartments: ['Operations', 'Media', 'Security', 'Registration', 'Logistics'],
    ),
  ];

  static DepartmentTemplate getById(String id) {
    return allTemplates.firstWhere((t) => t.id == id, orElse: () => allTemplates[4]);
  }
}

// =============================================================================
// MAIN UNIVERSAL EVENT MODEL
// =============================================================================

@immutable
class UniversalEvent {
  final String code; // Unique Reference Code (e.g. BCS-2026)
  final String title;
  final String shortName;
  final String description;
  final EventCategory category;
  final EventPriority priority;
  final EventStatus status;
  final String templateId;
  final String createdBy;
  final DateTime createdAt;
  final List<String> tags;

  // Sub-sections
  final ScheduleInfo schedule;
  final VenueInfo venue;
  final DepartmentOwnership ownership;
  final HeadcountBreakdown headcount;
  final BudgetInfo budget;
  final SafetyEmergencyConfig safety;
  final Map<String, dynamic> customDepartmentFields;
  final List<String> automatedTasks;
  final String? password;
  final EventVisibility visibility;
  final EventLifecycleState lifecycle;

  const UniversalEvent({
    required this.code,
    required this.title,
    this.shortName = '',
    required this.description,
    this.category = EventCategory.conference,
    this.priority = EventPriority.high,
    this.status = EventStatus.planned,
    this.visibility = EventVisibility.organization,
    this.lifecycle = EventLifecycleState.published,
    required this.templateId,
    required this.createdBy,
    required this.createdAt,
    this.tags = const [],
    this.password,
    required this.schedule,
    required this.venue,
    required this.ownership,
    required this.headcount,
    required this.budget,
    required this.safety,
    this.customDepartmentFields = const {},
    this.automatedTasks = const [],
  });

  Map<String, dynamic> toJson() => {
    'code': code.toUpperCase().trim(),
    'title': title,
    'shortName': shortName.isEmpty ? code : shortName,
    'description': description,
    'password': password,
    'category': category.name,
    'priority': priority.name,
    'status': status.name,
    'visibility': visibility.name,
    'lifecycle': lifecycle.name,
    'templateId': templateId,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'tags': tags,
    'schedule': schedule.toJson(),
    'venue': venue.toJson(),
    'ownership': ownership.toJson(),
    'headcount': headcount.toJson(),
    'budget': budget.toJson(),
    'safety': safety.toJson(),
    'customDepartmentFields': customDepartmentFields,
    'automatedTasks': automatedTasks,
    // Flattened fields for backwards compatibility with legacy modules
    'venue_name': venue.venueName,
    'departments': ownership.supportingDepartments,
  };

  factory UniversalEvent.fromJson(Map<String, dynamic> json) {
    return UniversalEvent(
      code: (json['code'] as String? ?? 'EVT-${DateTime.now().millisecondsSinceEpoch}').toUpperCase(),
      title: json['title'] as String? ?? 'Campus Event',
      shortName: json['shortName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      password: json['password'] as String?,
      category: EventCategory.fromString(json['category'] as String? ?? 'conference'),
      priority: EventPriority.fromString(json['priority'] as String? ?? 'medium'),
      status: EventStatus.fromString(json['status'] as String? ?? 'planned'),
      visibility: EventVisibility.fromString(json['visibility'] as String? ?? 'organization'),
      lifecycle: EventLifecycleState.fromString(json['lifecycle'] as String? ?? 'published'),
      templateId: json['templateId'] as String? ?? 'template_operations',
      createdBy: json['createdBy'] as String? ?? 'admin@groundflow.org',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      schedule: json['schedule'] is Map<String, dynamic>
          ? ScheduleInfo.fromJson(json['schedule'] as Map<String, dynamic>)
          : ScheduleInfo(startDate: DateTime.now(), endDate: DateTime.now().add(const Duration(days: 1)), startTime: '09:00 AM', endTime: '05:00 PM'),
      venue: json['venue'] is Map<String, dynamic>
          ? VenueInfo.fromJson(json['venue'] as Map<String, dynamic>)
          : VenueInfo(locationMode: LocationMode.physical, venueName: json['venue'] as String? ?? json['venue_name'] as String? ?? 'Main Campus Pavilion'),
      ownership: json['ownership'] is Map<String, dynamic>
          ? DepartmentOwnership.fromJson(json['ownership'] as Map<String, dynamic>)
          : DepartmentOwnership(
              primaryDepartment: 'Operations',
              organizingDepartment: 'Operations',
              eventOwnerEmail: json['createdBy'] as String? ?? '',
              departmentHeadEmail: json['createdBy'] as String? ?? '',
              coordinatorEmail: json['createdBy'] as String? ?? '',
            ),
      headcount: json['headcount'] is Map<String, dynamic>
          ? HeadcountBreakdown.fromJson(json['headcount'] as Map<String, dynamic>)
          : const HeadcountBreakdown(),
      budget: json['budget'] is Map<String, dynamic>
          ? BudgetInfo.fromJson(json['budget'] as Map<String, dynamic>)
          : const BudgetInfo(),
      safety: json['safety'] is Map<String, dynamic>
          ? SafetyEmergencyConfig.fromJson(json['safety'] as Map<String, dynamic>)
          : const SafetyEmergencyConfig(),
      customDepartmentFields: json['customDepartmentFields'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['customDepartmentFields'] as Map)
          : {},
      automatedTasks: (json['automatedTasks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

// =============================================================================
// CUSTOM FIELD DEFINITION
// =============================================================================

@immutable
class CustomFieldDefinition {
  final String key;
  final String label;
  final CustomFieldType type;
  final bool isRequired;
  final String defaultValue;
  final List<String> options;
  final String department;

  const CustomFieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.defaultValue = '',
    this.options = const [],
    this.department = 'General',
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'type': type.name,
    'isRequired': isRequired,
    'defaultValue': defaultValue,
    'options': options,
    'department': department,
  };

  factory CustomFieldDefinition.fromJson(Map<String, dynamic> json) {
    return CustomFieldDefinition(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: CustomFieldType.fromString(json['type'] as String? ?? 'shortText'),
      isRequired: json['isRequired'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      department: json['department'] as String? ?? 'General',
    );
  }
}

// =============================================================================
// INVITATION LINK MODEL
// =============================================================================

@immutable
class InvitationLinkModel {
  final String id;
  final String token;
  final String name;
  final InvitationLinkType type;
  final String eventId;
  final DateTime? expiresAt;
  final int maxUses;
  final int currentUses;
  final bool requiresApproval;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;

  const InvitationLinkModel({
    required this.id,
    required this.token,
    required this.name,
    required this.type,
    required this.eventId,
    this.expiresAt,
    this.maxUses = 100,
    this.currentUses = 0,
    this.requiresApproval = false,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'token': token,
    'name': name,
    'type': type.name,
    'eventId': eventId,
    'expiresAt': expiresAt?.toIso8601String(),
    'maxUses': maxUses,
    'currentUses': currentUses,
    'requiresApproval': requiresApproval,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
  };

  factory InvitationLinkModel.fromJson(Map<String, dynamic> json) {
    return InvitationLinkModel(
      id: json['id'] as String? ?? '',
      token: json['token'] as String? ?? '',
      name: json['name'] as String? ?? 'General Link',
      type: InvitationLinkType.fromString(json['type'] as String? ?? 'general'),
      eventId: json['eventId'] as String? ?? '',
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'] as String) : null,
      maxUses: json['maxUses'] as int? ?? 100,
      currentUses: json['currentUses'] as int? ?? 0,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  InvitationLinkModel copyWith({
    String? name,
    InvitationLinkType? type,
    DateTime? expiresAt,
    int? maxUses,
    int? currentUses,
    bool? requiresApproval,
    bool? isActive,
  }) {
    return InvitationLinkModel(
      id: id,
      token: token,
      name: name ?? this.name,
      type: type ?? this.type,
      eventId: eventId,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}

// =============================================================================
// EVENT PARTICIPANT MODEL
// =============================================================================

@immutable
class EventParticipantModel {
  final String id;
  final String eventId;
  final String name;
  final String email;
  final String phone;
  final String organization;
  final String department;
  final String designation;
  final ParticipantType participantType;
  final RegistrationStatus registrationStatus;
  final AttendanceStatus attendanceStatus;
  final String ticketPassCode; // Unique Opaque Signed Code for QR
  final String assignedTeam;
  final String assignedRole;
  final DateTime registeredAt;
  final DateTime? checkedInAt;
  final Map<String, dynamic> customFields;

  const EventParticipantModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.email,
    this.phone = '',
    this.organization = '',
    this.department = 'General',
    this.designation = 'Participant',
    this.participantType = ParticipantType.employee,
    this.registrationStatus = RegistrationStatus.approved,
    this.attendanceStatus = AttendanceStatus.notAttended,
    required this.ticketPassCode,
    this.assignedTeam = '',
    this.assignedRole = 'Attendee',
    required this.registeredAt,
    this.checkedInAt,
    this.customFields = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'name': name,
    'email': email.toLowerCase().trim(),
    'phone': phone,
    'organization': organization,
    'department': department,
    'designation': designation,
    'participantType': participantType.name,
    'registrationStatus': registrationStatus.name,
    'attendanceStatus': attendanceStatus.name,
    'ticketPassCode': ticketPassCode,
    'assignedTeam': assignedTeam,
    'assignedRole': assignedRole,
    'registeredAt': registeredAt.toIso8601String(),
    'checkedInAt': checkedInAt?.toIso8601String(),
    'customFields': customFields,
  };

  factory EventParticipantModel.fromJson(Map<String, dynamic> json) {
    return EventParticipantModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      name: json['name'] as String? ?? 'Anonymous',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      department: json['department'] as String? ?? 'General',
      designation: json['designation'] as String? ?? 'Participant',
      participantType: ParticipantType.fromString(json['participantType'] as String? ?? 'employee'),
      registrationStatus: RegistrationStatus.fromString(json['registrationStatus'] as String? ?? 'approved'),
      attendanceStatus: AttendanceStatus.fromString(json['attendanceStatus'] as String? ?? 'notAttended'),
      ticketPassCode: json['ticketPassCode'] as String? ?? '',
      assignedTeam: json['assignedTeam'] as String? ?? '',
      assignedRole: json['assignedRole'] as String? ?? 'Attendee',
      registeredAt: json['registeredAt'] != null ? DateTime.tryParse(json['registeredAt'] as String) ?? DateTime.now() : DateTime.now(),
      checkedInAt: json['checkedInAt'] != null ? DateTime.tryParse(json['checkedInAt'] as String) : null,
      customFields: json['customFields'] != null ? Map<String, dynamic>.from(json['customFields'] as Map) : const {},
    );
  }

  EventParticipantModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? department,
    String? designation,
    ParticipantType? participantType,
    RegistrationStatus? registrationStatus,
    AttendanceStatus? attendanceStatus,
    DateTime? checkedInAt,
    String? assignedTeam,
    String? assignedRole,
    Map<String, dynamic>? customFields,
  }) {
    return EventParticipantModel(
      id: id,
      eventId: eventId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      organization: organization,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      participantType: participantType ?? this.participantType,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      ticketPassCode: ticketPassCode,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      assignedRole: assignedRole ?? this.assignedRole,
      registeredAt: registeredAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      customFields: customFields ?? this.customFields,
    );
  }
}

// =============================================================================
// EVENT TEAM MODEL
// =============================================================================

@immutable
class EventTeamModel {
  final String id;
  final String eventId;
  final String name;
  final String department;
  final String teamLeader;
  final List<String> members;
  final int requiredHeadcount;
  final String responsibilities;
  final String priority;
  final String status;

  const EventTeamModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.department,
    required this.teamLeader,
    this.members = const [],
    this.requiredHeadcount = 5,
    this.responsibilities = 'Coordination & Task Execution',
    this.priority = 'Medium',
    this.status = 'Active',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'name': name,
    'department': department,
    'teamLeader': teamLeader,
    'members': members,
    'requiredHeadcount': requiredHeadcount,
    'responsibilities': responsibilities,
    'priority': priority,
    'status': status,
  };

  factory EventTeamModel.fromJson(Map<String, dynamic> json) {
    return EventTeamModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      name: json['name'] as String? ?? 'Team',
      department: json['department'] as String? ?? 'General',
      teamLeader: json['teamLeader'] as String? ?? 'Unassigned',
      members: (json['members'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      requiredHeadcount: json['requiredHeadcount'] as int? ?? 5,
      responsibilities: json['responsibilities'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Active',
    );
  }

  EventTeamModel copyWith({
    String? name,
    String? department,
    String? teamLeader,
    List<String>? members,
    int? requiredHeadcount,
    String? responsibilities,
    String? priority,
    String? status,
  }) {
    return EventTeamModel(
      id: id,
      eventId: eventId,
      name: name ?? this.name,
      department: department ?? this.department,
      teamLeader: teamLeader ?? this.teamLeader,
      members: members ?? this.members,
      requiredHeadcount: requiredHeadcount ?? this.requiredHeadcount,
      responsibilities: responsibilities ?? this.responsibilities,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }
}

// =============================================================================
// ACTIVITY / AUDIT LOG MODEL
// =============================================================================

@immutable
class ActivityLogModel {
  final String id;
  final String eventId;
  final String action;
  final String details;
  final String userEmail;
  final DateTime timestamp;

  const ActivityLogModel({
    required this.id,
    required this.eventId,
    required this.action,
    required this.details,
    required this.userEmail,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'action': action,
    'details': details,
    'userEmail': userEmail,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      action: json['action'] as String? ?? 'Event Updated',
      details: json['details'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? 'System',
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

// =============================================================================
// MILESTONE 2: AUTOMATED TASKS & WORKFLOW MODELS
// =============================================================================

enum TaskStatus {
  assigned,
  inProgress,
  completed,
  blocked;

  String get displayName {
    switch (this) {
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.blocked:
        return 'Blocked';
    }
  }

  static TaskStatus fromString(String val) {
    return TaskStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TaskStatus.assigned,
    );
  }
}

@immutable
class EventTaskModel {
  final String id;
  final String eventId;
  final String title;
  final String category;
  final String department;
  final String assignedUser;
  final DateTime? dueDate;
  final String priority;
  final TaskStatus status;
  final int progressPercentage;
  final List<String> checklist;

  const EventTaskModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.category,
    required this.department,
    this.assignedUser = 'Unassigned',
    this.dueDate,
    this.priority = 'Medium',
    this.status = TaskStatus.assigned,
    this.progressPercentage = 0,
    this.checklist = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'title': title,
    'category': category,
    'department': department,
    'assignedUser': assignedUser,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority,
    'status': status.name,
    'progressPercentage': progressPercentage,
    'checklist': checklist,
  };

  factory EventTaskModel.fromJson(Map<String, dynamic> json) {
    return EventTaskModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Task',
      category: json['category'] as String? ?? 'General',
      department: json['department'] as String? ?? 'Operations',
      assignedUser: json['assignedUser'] as String? ?? 'Unassigned',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
      priority: json['priority'] as String? ?? 'Medium',
      status: TaskStatus.fromString(json['status'] as String? ?? 'assigned'),
      progressPercentage: json['progressPercentage'] as int? ?? 0,
      checklist: (json['checklist'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  EventTaskModel copyWith({
    TaskStatus? status,
    int? progressPercentage,
    String? assignedUser,
    List<String>? checklist,
  }) {
    return EventTaskModel(
      id: id,
      eventId: eventId,
      title: title,
      category: category,
      department: department,
      assignedUser: assignedUser ?? this.assignedUser,
      dueDate: dueDate,
      priority: priority,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      checklist: checklist ?? this.checklist,
    );
  }
}

// =============================================================================
// MILESTONE 2: MULTI-TIER APPROVAL WORKFLOW MODELS
// =============================================================================

enum ApprovalDecision {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case ApprovalDecision.pending:
        return 'Pending Review';
      case ApprovalDecision.approved:
        return 'Approved';
      case ApprovalDecision.rejected:
        return 'Rejected';
    }
  }

  static ApprovalDecision fromString(String val) {
    return ApprovalDecision.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ApprovalDecision.pending,
    );
  }
}

@immutable
class EventApprovalModel {
  final String id;
  final String eventId;
  final String stageName;
  final String approverRole;
  final String approverEmail;
  final ApprovalDecision status;
  final String comments;
  final DateTime? decidedAt;
  final DateTime requestedAt;

  const EventApprovalModel({
    required this.id,
    required this.eventId,
    required this.stageName,
    required this.approverRole,
    required this.approverEmail,
    this.status = ApprovalDecision.pending,
    this.comments = '',
    this.decidedAt,
    required this.requestedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'stageName': stageName,
    'approverRole': approverRole,
    'approverEmail': approverEmail,
    'status': status.name,
    'comments': comments,
    'decidedAt': decidedAt?.toIso8601String(),
    'requestedAt': requestedAt.toIso8601String(),
  };

  factory EventApprovalModel.fromJson(Map<String, dynamic> json) {
    return EventApprovalModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      stageName: json['stageName'] as String? ?? 'General Sign-off',
      approverRole: json['approverRole'] as String? ?? 'Department Head',
      approverEmail: json['approverEmail'] as String? ?? '',
      status: ApprovalDecision.fromString(json['status'] as String? ?? 'pending'),
      comments: json['comments'] as String? ?? '',
      decidedAt: json['decidedAt'] != null ? DateTime.tryParse(json['decidedAt'] as String) : null,
      requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

// =============================================================================
// MILESTONE 2: RESOURCE ALLOCATION & CONFLICT DETECTION MODELS
// =============================================================================

@immutable
class EventResourceModel {
  final String id;
  final String eventId;
  final String resourceName;
  final String resourceType; // Venue, AudioVisual, Seating, Power, Network, Transport
  final int quantity;
  final bool isLocked;
  final String location;
  final String notes;

  const EventResourceModel({
    required this.id,
    required this.eventId,
    required this.resourceName,
    required this.resourceType,
    this.quantity = 1,
    this.isLocked = true,
    this.location = 'Main Stage',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'resourceName': resourceName,
    'resourceType': resourceType,
    'quantity': quantity,
    'isLocked': isLocked,
    'location': location,
    'notes': notes,
  };

  factory EventResourceModel.fromJson(Map<String, dynamic> json) {
    return EventResourceModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      resourceName: json['resourceName'] as String? ?? 'Resource',
      resourceType: json['resourceType'] as String? ?? 'General',
      quantity: json['quantity'] as int? ?? 1,
      isLocked: json['isLocked'] as bool? ?? true,
      location: json['location'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}

@immutable
class ResourceConflictResult {
  final bool hasConflict;
  final String resourceName;
  final String conflictingEventCode;
  final String conflictingEventTitle;
  final String conflictDetails;

  const ResourceConflictResult({
    this.hasConflict = false,
    this.resourceName = '',
    this.conflictingEventCode = '',
    this.conflictingEventTitle = '',
    this.conflictDetails = '',
  });
}

// =============================================================================
// MILESTONE 2: BUDGET & FINANCIAL EXPENSE MODELS
// =============================================================================

@immutable
class EventExpenseModel {
  final String id;
  final String eventId;
  final String title;
  final String category; // Logistics, Catering, Venue, Tech, Marketing, Honorarium, Misc
  final String department;
  final String vendor;
  final double amount;
  final String paymentStatus; // Planned, Incurred, Paid
  final DateTime date;
  final String receiptRef;

  const EventExpenseModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.category,
    required this.department,
    this.vendor = 'Internal',
    required this.amount,
    this.paymentStatus = 'Planned',
    required this.date,
    this.receiptRef = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'title': title,
    'category': category,
    'department': department,
    'vendor': vendor,
    'amount': amount,
    'paymentStatus': paymentStatus,
    'date': date.toIso8601String(),
    'receiptRef': receiptRef,
  };

  factory EventExpenseModel.fromJson(Map<String, dynamic> json) {
    return EventExpenseModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      title: json['title'] as String? ?? 'Expense',
      category: json['category'] as String? ?? 'Misc',
      department: json['department'] as String? ?? 'Operations',
      vendor: json['vendor'] as String? ?? 'Internal',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] as String? ?? 'Planned',
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) ?? DateTime.now() : DateTime.now(),
      receiptRef: json['receiptRef'] as String? ?? '',
    );
  }
}

// =============================================================================
// MILESTONE 3: LIVE INCIDENT ESCALATION & AUDIT REPORT MODELS
// =============================================================================

enum IncidentSeverity {
  critical,
  high,
  medium,
  low;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static IncidentSeverity fromString(String val) {
    return IncidentSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => IncidentSeverity.medium,
    );
  }
}

enum IncidentStatus {
  open,
  triaged,
  escalated,
  resolved;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static IncidentStatus fromString(String val) {
    return IncidentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => IncidentStatus.open,
    );
  }
}

@immutable
class EventIncidentModel {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String department;
  final String reportedBy;
  final String assignedTo;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String resolutionNotes;

  const EventIncidentModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    this.severity = IncidentSeverity.medium,
    this.status = IncidentStatus.open,
    required this.department,
    required this.reportedBy,
    this.assignedTo = 'Unassigned',
    required this.reportedAt,
    this.resolvedAt,
    this.resolutionNotes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'title': title,
    'description': description,
    'severity': severity.name,
    'status': status.name,
    'department': department,
    'reportedBy': reportedBy,
    'assignedTo': assignedTo,
    'reportedAt': reportedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolutionNotes': resolutionNotes,
  };

  factory EventIncidentModel.fromJson(Map<String, dynamic> json) {
    return EventIncidentModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      title: json['title'] as String? ?? 'Incident',
      description: json['description'] as String? ?? '',
      severity: IncidentSeverity.fromString(json['severity'] as String? ?? 'medium'),
      status: IncidentStatus.fromString(json['status'] as String? ?? 'open'),
      department: json['department'] as String? ?? 'Operations',
      reportedBy: json['reportedBy'] as String? ?? 'Staff',
      assignedTo: json['assignedTo'] as String? ?? 'Unassigned',
      reportedAt: json['reportedAt'] != null ? DateTime.tryParse(json['reportedAt'] as String) ?? DateTime.now() : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'] as String) : null,
      resolutionNotes: json['resolutionNotes'] as String? ?? '',
    );
  }
}

@immutable
class PostEventReportModel {
  final String eventId;
  final String eventTitle;
  final DateTime generatedAt;
  final int totalExpected;
  final int totalRegistered;
  final int totalCheckedIn;
  final double attendanceRate;
  final double allocatedBudget;
  final double totalSpend;
  final double budgetVariance;
  final int totalTasks;
  final int completedTasks;
  final double taskCompletionRate;
  final int totalIncidents;
  final int resolvedIncidents;
  final String generatedSummaryText;

  const PostEventReportModel({
    required this.eventId,
    required this.eventTitle,
    required this.generatedAt,
    required this.totalExpected,
    required this.totalRegistered,
    required this.totalCheckedIn,
    required this.attendanceRate,
    required this.allocatedBudget,
    required this.totalSpend,
    required this.budgetVariance,
    required this.totalTasks,
    required this.completedTasks,
    required this.taskCompletionRate,
    required this.totalIncidents,
    required this.resolvedIncidents,
    required this.generatedSummaryText,
  });
}

// =============================================================================
// MILESTONE 5: MULTI-DAY SESSIONS & REAL-TIME BROADCAST MODELS
// =============================================================================

@immutable
class EventSessionModel {
  final String id;
  final String eventId;
  final int dayNumber;
  final String title;
  final String speaker;
  final String startTime;
  final String endTime;
  final String room;
  final String track;
  final String description;
  final bool isLiveNow;

  const EventSessionModel({
    required this.id,
    required this.eventId,
    this.dayNumber = 1,
    required this.title,
    this.speaker = 'TBD',
    required this.startTime,
    required this.endTime,
    this.room = 'Main Hall',
    this.track = 'General',
    this.description = '',
    this.isLiveNow = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'dayNumber': dayNumber,
    'title': title,
    'speaker': speaker,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'track': track,
    'description': description,
    'isLiveNow': isLiveNow,
  };

  factory EventSessionModel.fromJson(Map<String, dynamic> json) {
    return EventSessionModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      dayNumber: json['dayNumber'] as int? ?? 1,
      title: json['title'] as String? ?? 'Session',
      speaker: json['speaker'] as String? ?? 'TBD',
      startTime: json['startTime'] as String? ?? '10:00 AM',
      endTime: json['endTime'] as String? ?? '11:00 AM',
      room: json['room'] as String? ?? 'Main Hall',
      track: json['track'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      isLiveNow: json['isLiveNow'] as bool? ?? false,
    );
  }

  EventSessionModel copyWith({
    bool? isLiveNow,
    String? title,
    String? speaker,
    String? startTime,
    String? endTime,
    String? room,
  }) {
    return EventSessionModel(
      id: id,
      eventId: eventId,
      dayNumber: dayNumber,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      track: track,
      description: description,
      isLiveNow: isLiveNow ?? this.isLiveNow,
    );
  }
}

enum AnnouncementUrgency {
  info,
  high,
  emergency;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static AnnouncementUrgency fromString(String val) {
    return AnnouncementUrgency.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AnnouncementUrgency.info,
    );
  }
}

enum AnnouncementAudience {
  all,
  attendees,
  volunteers,
  vips,
  department;

  String get displayName {
    switch (this) {
      case AnnouncementAudience.all:
        return 'All (Public & Squads)';
      case AnnouncementAudience.attendees:
        return 'Attendees Only';
      case AnnouncementAudience.volunteers:
        return 'Volunteers & Crew';
      case AnnouncementAudience.vips:
        return 'VIP Delegation';
      case AnnouncementAudience.department:
        return 'Specific Department';
    }
  }

  static AnnouncementAudience fromString(String val) {
    return AnnouncementAudience.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AnnouncementAudience.all,
    );
  }
}

@immutable
class EventAnnouncementModel {
  final String id;
  final String eventId;
  final String title;
  final String message;
  final AnnouncementUrgency urgency;
  final AnnouncementAudience audience;
  final String targetDepartment;
  final String sentBy;
  final DateTime sentAt;

  const EventAnnouncementModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.message,
    this.urgency = AnnouncementUrgency.info,
    this.audience = AnnouncementAudience.all,
    this.targetDepartment = '',
    required this.sentBy,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'title': title,
    'message': message,
    'urgency': urgency.name,
    'audience': audience.name,
    'targetDepartment': targetDepartment,
    'sentBy': sentBy,
    'sentAt': sentAt.toIso8601String(),
  };

  factory EventAnnouncementModel.fromJson(Map<String, dynamic> json) {
    return EventAnnouncementModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      title: json['title'] as String? ?? 'Announcement',
      message: json['message'] as String? ?? '',
      urgency: AnnouncementUrgency.fromString(json['urgency'] as String? ?? 'info'),
      audience: AnnouncementAudience.fromString(json['audience'] as String? ?? 'all'),
      targetDepartment: json['targetDepartment'] as String? ?? '',
      sentBy: json['sentBy'] as String? ?? 'Organizer',
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Safely extracts venue name regardless of whether venue is stored as a String or a Map
String extractEventVenue(dynamic rawVenue, {String fallback = 'Campus Venue'}) {
  if (rawVenue == null) return fallback;
  if (rawVenue is String) {
    final clean = rawVenue.trim();
    return clean.isNotEmpty ? clean : fallback;
  }
  if (rawVenue is Map) {
    final name = rawVenue['venueName'] ?? rawVenue['name'] ?? rawVenue['title'] ?? rawVenue['location'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }
  }
  return rawVenue.toString();
}
