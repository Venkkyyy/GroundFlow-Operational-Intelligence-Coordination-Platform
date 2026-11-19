// lib/core/models/models.dart
// All GroundFlow data models — plain Dart classes (no code generation).
// All models implement copyWith, toJson, and fromJson manually.

// ignore_for_file: prefer_const_constructors_in_immutables

// ══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ══════════════════════════════════════════════════════════════════════════════

/// Role of a user within the platform.
enum UserRole {
  superAdmin,
  departmentHead,
  teamLead,
  member;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:     return 'Super Admin';
      case UserRole.departmentHead: return 'Department Head';
      case UserRole.teamLead:       return 'Team Lead';
      case UserRole.member:         return 'Member';
    }
  }

  static UserRole fromString(String s) =>
      UserRole.values.firstWhere((e) => e.name == s, orElse: () => UserRole.member);
}

/// Real-time status of an event member.
enum MemberStatus {
  notArrived,
  present,
  onShoot,
  onBreak,
  needsHelp,
  missedCheckIn;

  String get displayName {
    switch (this) {
      case MemberStatus.notArrived:    return 'Not Arrived';
      case MemberStatus.present:       return 'Present';
      case MemberStatus.onShoot:       return 'On Shoot';
      case MemberStatus.onBreak:       return 'On Break';
      case MemberStatus.needsHelp:     return 'Needs Help';
      case MemberStatus.missedCheckIn: return 'Missed Check-in';
    }
  }

  static MemberStatus fromString(String s) =>
      MemberStatus.values.firstWhere((e) => e.name == s, orElse: () => MemberStatus.notArrived);
}

/// Status of a shoot slot.
enum ShootStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case ShootStatus.pending:    return 'Pending';
      case ShootStatus.inProgress: return 'In Progress';
      case ShootStatus.completed:  return 'Completed';
      case ShootStatus.cancelled:  return 'Cancelled';
    }
  }

  static ShootStatus fromString(String s) =>
      ShootStatus.values.firstWhere((e) => e.name == s, orElse: () => ShootStatus.pending);
}

/// Status of a gear/asset item.
enum GearStatus {
  available,
  checkedOut,
  overdue,
  missing,
  damaged,
  charging;

  String get displayName {
    switch (this) {
      case GearStatus.available:   return 'Available';
      case GearStatus.checkedOut:  return 'Checked Out';
      case GearStatus.overdue:     return 'Overdue';
      case GearStatus.missing:     return 'Missing';
      case GearStatus.damaged:     return 'Damaged';
      case GearStatus.charging:    return 'Charging';
    }
  }

  static GearStatus fromString(String s) =>
      GearStatus.values.firstWhere((e) => e.name == s, orElse: () => GearStatus.available);
}

/// Stage of the data/media pipeline.
enum PipelineStage {
  shot,
  cardHandedIn,
  ingested,
  verified,
  backedUp,
  editing,
  delivered;

  String get displayName {
    switch (this) {
      case PipelineStage.shot:         return 'Shot';
      case PipelineStage.cardHandedIn: return 'Card Handed In';
      case PipelineStage.ingested:     return 'Ingested';
      case PipelineStage.verified:     return 'Verified';
      case PipelineStage.backedUp:     return 'Backed Up';
      case PipelineStage.editing:      return 'Editing';
      case PipelineStage.delivered:    return 'Delivered';
    }
  }

  int get stepIndex => PipelineStage.values.indexOf(this);

  static PipelineStage fromString(String s) =>
      PipelineStage.values.firstWhere((e) => e.name == s, orElse: () => PipelineStage.shot);
}

/// Status of an issue report.
enum IssueStatus {
  open,
  inProgress,
  resolved,
  escalated;

  String get displayName {
    switch (this) {
      case IssueStatus.open:       return 'Open';
      case IssueStatus.inProgress: return 'In Progress';
      case IssueStatus.resolved:   return 'Resolved';
      case IssueStatus.escalated:  return 'Escalated';
    }
  }

  static IssueStatus fromString(String s) =>
      IssueStatus.values.firstWhere((e) => e.name == s, orElse: () => IssueStatus.open);
}

/// Category of an issue report.
enum IssueCategory {
  gear,
  crewShortage,
  access,
  safety,
  other;

  String get displayName {
    switch (this) {
      case IssueCategory.gear:         return 'Gear';
      case IssueCategory.crewShortage: return 'Crew Shortage';
      case IssueCategory.access:       return 'Access';
      case IssueCategory.safety:       return 'Safety';
      case IssueCategory.other:        return 'Other';
    }
  }

  static IssueCategory fromString(String s) =>
      IssueCategory.values.firstWhere((e) => e.name == s, orElse: () => IssueCategory.other);
}

/// Status of a dump/ingest station.
enum DumpStationStatus {
  open,
  busy,
  closed;

  String get displayName {
    switch (this) {
      case DumpStationStatus.open:   return 'Open';
      case DumpStationStatus.busy:   return 'Busy';
      case DumpStationStatus.closed: return 'Closed';
    }
  }

  static DumpStationStatus fromString(String s) =>
      DumpStationStatus.values.firstWhere((e) => e.name == s, orElse: () => DumpStationStatus.closed);
}

/// Safety of a pipeline card (data redundancy).
enum DataSafetyLevel { safe, atRisk, stalled }

// ══════════════════════════════════════════════════════════════════════════════
// USER
// ══════════════════════════════════════════════════════════════════════════════

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phone,
    required this.createdAt,
  });

  /// Initials for avatar fallback (e.g. "John Doe" → "JD").
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  AppUser copyWith({
    String? id, String? name, String? email,
    UserRole? role, String? avatarUrl, String? phone,
    DateTime? createdAt,
  }) {
    return AppUser(
      id:        id        ?? this.id,
      name:      name      ?? this.name,
      email:     email     ?? this.email,
      role:      role      ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone:     phone     ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'name':      name,
    'email':     email,
    'role':      role.name,
    'avatarUrl': avatarUrl,
    'phone':     phone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id:        j['id'] as String,
    name:      j['name'] as String,
    email:     j['email'] as String,
    role:      UserRole.fromString(j['role'] as String),
    avatarUrl: j['avatarUrl'] as String?,
    phone:     j['phone'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// LOCATION
// ══════════════════════════════════════════════════════════════════════════════

class Room {
  final String id;
  final String name;
  final String? mapUrl;
  final int capacity;

  const Room({
    required this.id,
    required this.name,
    this.mapUrl,
    this.capacity = 0,
  });

  Room copyWith({String? id, String? name, String? mapUrl, int? capacity}) =>
      Room(
        id: id ?? this.id,
        name: name ?? this.name,
        mapUrl: mapUrl ?? this.mapUrl,
        capacity: capacity ?? this.capacity,
      );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'mapUrl': mapUrl, 'capacity': capacity,
  };

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'] as String,
    name: j['name'] as String,
    mapUrl: j['mapUrl'] as String?,
    capacity: (j['capacity'] as int?) ?? 0,
  );
}

class Building {
  final String id;
  final String name;
  final List<Room> rooms;

  const Building({required this.id, required this.name, this.rooms = const []});

  Building copyWith({String? id, String? name, List<Room>? rooms}) =>
      Building(id: id ?? this.id, name: name ?? this.name, rooms: rooms ?? this.rooms);

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'rooms': rooms.map((r) => r.toJson()).toList(),
  };

  factory Building.fromJson(Map<String, dynamic> j) => Building(
    id: j['id'] as String,
    name: j['name'] as String,
    rooms: (j['rooms'] as List<dynamic>? ?? [])
        .map((r) => Room.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// EVENT
// ══════════════════════════════════════════════════════════════════════════════

class Event {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String venue;
  final List<Building> buildings;
  final int expectedVolunteers;
  final bool isActive;
  final String createdByUserId;

  const Event({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.venue,
    this.buildings = const [],
    this.expectedVolunteers = 0,
    this.isActive = false,
    required this.createdByUserId,
  });

  Event copyWith({
    String? id, String? name, String? description,
    DateTime? startDate, DateTime? endDate,
    String? venue, List<Building>? buildings,
    int? expectedVolunteers, bool? isActive,
    String? createdByUserId,
  }) {
    return Event(
      id:                 id                 ?? this.id,
      name:               name               ?? this.name,
      description:        description        ?? this.description,
      startDate:          startDate          ?? this.startDate,
      endDate:            endDate            ?? this.endDate,
      venue:              venue              ?? this.venue,
      buildings:          buildings          ?? this.buildings,
      expectedVolunteers: expectedVolunteers ?? this.expectedVolunteers,
      isActive:           isActive           ?? this.isActive,
      createdByUserId:    createdByUserId    ?? this.createdByUserId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'venue': venue,
    'buildings': buildings.map((b) => b.toJson()).toList(),
    'expectedVolunteers': expectedVolunteers,
    'isActive': isActive,
    'createdByUserId': createdByUserId,
  };

  factory Event.fromJson(Map<String, dynamic> j) => Event(
    id:          j['id'] as String,
    name:        j['name'] as String,
    description: j['description'] as String,
    startDate:   DateTime.parse(j['startDate'] as String),
    endDate:     DateTime.parse(j['endDate'] as String),
    venue:       j['venue'] as String,
    buildings:   (j['buildings'] as List<dynamic>? ?? [])
        .map((b) => Building.fromJson(b as Map<String, dynamic>)).toList(),
    expectedVolunteers: (j['expectedVolunteers'] as int?) ?? 0,
    isActive:    (j['isActive'] as bool?) ?? false,
    createdByUserId: j['createdByUserId'] as String,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// DEPARTMENT & TEAM
// ══════════════════════════════════════════════════════════════════════════════

class Department {
  final String id;
  final String name;
  final String eventId;
  final String headUserId;
  final List<String> teamIds;
  final String? colorHex; // Dept color for UI chips

  const Department({
    required this.id,
    required this.name,
    required this.eventId,
    required this.headUserId,
    this.teamIds = const [],
    this.colorHex,
  });

  Department copyWith({
    String? id, String? name, String? eventId,
    String? headUserId, List<String>? teamIds, String? colorHex,
  }) => Department(
    id: id ?? this.id, name: name ?? this.name,
    eventId: eventId ?? this.eventId,
    headUserId: headUserId ?? this.headUserId,
    teamIds: teamIds ?? this.teamIds,
    colorHex: colorHex ?? this.colorHex,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'eventId': eventId,
    'headUserId': headUserId, 'teamIds': teamIds, 'colorHex': colorHex,
  };

  factory Department.fromJson(Map<String, dynamic> j) => Department(
    id: j['id'] as String, name: j['name'] as String,
    eventId: j['eventId'] as String,
    headUserId: j['headUserId'] as String,
    teamIds: List<String>.from(j['teamIds'] as List? ?? []),
    colorHex: j['colorHex'] as String?,
  );
}

class TeamMember {
  final String userId;
  final String name;
  final String? avatarUrl;
  final MemberStatus status;
  final DateTime? lastSeen;
  final String? currentLocation;

  const TeamMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.status = MemberStatus.notArrived,
    this.lastSeen,
    this.currentLocation,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  TeamMember copyWith({
    String? userId, String? name, String? avatarUrl,
    MemberStatus? status, DateTime? lastSeen, String? currentLocation,
  }) => TeamMember(
    userId: userId ?? this.userId, name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    status: status ?? this.status,
    lastSeen: lastSeen ?? this.lastSeen,
    currentLocation: currentLocation ?? this.currentLocation,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId, 'name': name, 'avatarUrl': avatarUrl,
    'status': status.name,
    'lastSeen': lastSeen?.toIso8601String(),
    'currentLocation': currentLocation,
  };

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    userId: j['userId'] as String, name: j['name'] as String,
    avatarUrl: j['avatarUrl'] as String?,
    status: MemberStatus.fromString(j['status'] as String? ?? ''),
    lastSeen: j['lastSeen'] != null ? DateTime.parse(j['lastSeen'] as String) : null,
    currentLocation: j['currentLocation'] as String?,
  );
}

class Team {
  final String id;
  final String name;
  final String departmentId;
  final String eventId;
  final String leadUserId;
  final List<TeamMember> members;

  const Team({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.eventId,
    required this.leadUserId,
    this.members = const [],
  });

  Team copyWith({
    String? id, String? name, String? departmentId,
    String? eventId, String? leadUserId, List<TeamMember>? members,
  }) => Team(
    id: id ?? this.id, name: name ?? this.name,
    departmentId: departmentId ?? this.departmentId,
    eventId: eventId ?? this.eventId,
    leadUserId: leadUserId ?? this.leadUserId,
    members: members ?? this.members,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'departmentId': departmentId,
    'eventId': eventId, 'leadUserId': leadUserId,
    'members': members.map((m) => m.toJson()).toList(),
  };

  factory Team.fromJson(Map<String, dynamic> j) => Team(
    id: j['id'] as String, name: j['name'] as String,
    departmentId: j['departmentId'] as String,
    eventId: j['eventId'] as String,
    leadUserId: j['leadUserId'] as String,
    members: (j['members'] as List<dynamic>? ?? [])
        .map((m) => TeamMember.fromJson(m as Map<String, dynamic>)).toList(),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SHOOT SLOT / TASK
// ══════════════════════════════════════════════════════════════════════════════

class ShootSlot {
  final String id;
  final String eventId;
  final String title;
  final String locationId;      // Room.id
  final String buildingId;      // Building.id
  final DateTime startTime;
  final DateTime endTime;
  final ShootStatus status;
  final List<String> assignedUserIds;
  final List<String> assignedGearIds;
  final PipelineStage pipelineStage;
  final String? notes;

  const ShootSlot({
    required this.id,
    required this.eventId,
    required this.title,
    required this.locationId,
    required this.buildingId,
    required this.startTime,
    required this.endTime,
    this.status = ShootStatus.pending,
    this.assignedUserIds = const [],
    this.assignedGearIds = const [],
    this.pipelineStage = PipelineStage.shot,
    this.notes,
  });

  ShootSlot copyWith({
    String? id, String? eventId, String? title,
    String? locationId, String? buildingId,
    DateTime? startTime, DateTime? endTime,
    ShootStatus? status,
    List<String>? assignedUserIds, List<String>? assignedGearIds,
    PipelineStage? pipelineStage, String? notes,
  }) => ShootSlot(
    id: id ?? this.id, eventId: eventId ?? this.eventId,
    title: title ?? this.title,
    locationId: locationId ?? this.locationId,
    buildingId: buildingId ?? this.buildingId,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    status: status ?? this.status,
    assignedUserIds: assignedUserIds ?? this.assignedUserIds,
    assignedGearIds: assignedGearIds ?? this.assignedGearIds,
    pipelineStage: pipelineStage ?? this.pipelineStage,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'title': title,
    'locationId': locationId, 'buildingId': buildingId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'status': status.name,
    'assignedUserIds': assignedUserIds,
    'assignedGearIds': assignedGearIds,
    'pipelineStage': pipelineStage.name,
    'notes': notes,
  };

  factory ShootSlot.fromJson(Map<String, dynamic> j) => ShootSlot(
    id: j['id'] as String, eventId: j['eventId'] as String,
    title: j['title'] as String,
    locationId: j['locationId'] as String,
    buildingId: j['buildingId'] as String,
    startTime: DateTime.parse(j['startTime'] as String),
    endTime: DateTime.parse(j['endTime'] as String),
    status: ShootStatus.fromString(j['status'] as String? ?? ''),
    assignedUserIds: List<String>.from(j['assignedUserIds'] as List? ?? []),
    assignedGearIds: List<String>.from(j['assignedGearIds'] as List? ?? []),
    pipelineStage: PipelineStage.fromString(j['pipelineStage'] as String? ?? ''),
    notes: j['notes'] as String?,
  );
}

class Task {
  final String id;
  final String eventId;
  final String title;
  final String? description;
  final String assignedUserId;
  final String? teamId;
  final DateTime dueTime;
  final ShootStatus status; // reuse shoot status
  final String? relatedShootId;
  final List<String> gearIds;

  const Task({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    required this.assignedUserId,
    this.teamId,
    required this.dueTime,
    this.status = ShootStatus.pending,
    this.relatedShootId,
    this.gearIds = const [],
  });

  Task copyWith({
    String? id, String? eventId, String? title,
    String? description, String? assignedUserId, String? teamId,
    DateTime? dueTime, ShootStatus? status,
    String? relatedShootId, List<String>? gearIds,
  }) => Task(
    id: id ?? this.id, eventId: eventId ?? this.eventId,
    title: title ?? this.title,
    description: description ?? this.description,
    assignedUserId: assignedUserId ?? this.assignedUserId,
    teamId: teamId ?? this.teamId,
    dueTime: dueTime ?? this.dueTime,
    status: status ?? this.status,
    relatedShootId: relatedShootId ?? this.relatedShootId,
    gearIds: gearIds ?? this.gearIds,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'title': title,
    'description': description, 'assignedUserId': assignedUserId,
    'teamId': teamId, 'dueTime': dueTime.toIso8601String(),
    'status': status.name, 'relatedShootId': relatedShootId,
    'gearIds': gearIds,
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String, eventId: j['eventId'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    assignedUserId: j['assignedUserId'] as String,
    teamId: j['teamId'] as String?,
    dueTime: DateTime.parse(j['dueTime'] as String),
    status: ShootStatus.fromString(j['status'] as String? ?? ''),
    relatedShootId: j['relatedShootId'] as String?,
    gearIds: List<String>.from(j['gearIds'] as List? ?? []),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ASSETS / GEAR
// ══════════════════════════════════════════════════════════════════════════════

class Asset {
  final String id;
  final String eventId;
  final String name;
  final String serialNumber;
  final String qrCode;
  final GearStatus status;
  final String? checkedOutByUserId;
  final DateTime? checkedOutAt;
  final DateTime? dueBackAt;
  final String? kitId;
  final String? notes;
  /// Battery level 0–100, null if not applicable.
  final int? batteryLevel;

  const Asset({
    required this.id,
    required this.eventId,
    required this.name,
    required this.serialNumber,
    required this.qrCode,
    this.status = GearStatus.available,
    this.checkedOutByUserId,
    this.checkedOutAt,
    this.dueBackAt,
    this.kitId,
    this.notes,
    this.batteryLevel,
  });

  Asset copyWith({
    String? id, String? eventId, String? name,
    String? serialNumber, String? qrCode,
    GearStatus? status,
    String? checkedOutByUserId, DateTime? checkedOutAt,
    DateTime? dueBackAt, String? kitId, String? notes,
    int? batteryLevel,
  }) => Asset(
    id: id ?? this.id, eventId: eventId ?? this.eventId,
    name: name ?? this.name, serialNumber: serialNumber ?? this.serialNumber,
    qrCode: qrCode ?? this.qrCode, status: status ?? this.status,
    checkedOutByUserId: checkedOutByUserId ?? this.checkedOutByUserId,
    checkedOutAt: checkedOutAt ?? this.checkedOutAt,
    dueBackAt: dueBackAt ?? this.dueBackAt,
    kitId: kitId ?? this.kitId, notes: notes ?? this.notes,
    batteryLevel: batteryLevel ?? this.batteryLevel,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'name': name,
    'serialNumber': serialNumber, 'qrCode': qrCode,
    'status': status.name,
    'checkedOutByUserId': checkedOutByUserId,
    'checkedOutAt': checkedOutAt?.toIso8601String(),
    'dueBackAt': dueBackAt?.toIso8601String(),
    'kitId': kitId, 'notes': notes, 'batteryLevel': batteryLevel,
  };

  factory Asset.fromJson(Map<String, dynamic> j) => Asset(
    id: j['id'] as String, eventId: j['eventId'] as String,
    name: j['name'] as String, serialNumber: j['serialNumber'] as String,
    qrCode: j['qrCode'] as String,
    status: GearStatus.fromString(j['status'] as String? ?? ''),
    checkedOutByUserId: j['checkedOutByUserId'] as String?,
    checkedOutAt: j['checkedOutAt'] != null ? DateTime.parse(j['checkedOutAt'] as String) : null,
    dueBackAt: j['dueBackAt'] != null ? DateTime.parse(j['dueBackAt'] as String) : null,
    kitId: j['kitId'] as String?,
    notes: j['notes'] as String?,
    batteryLevel: j['batteryLevel'] as int?,
  );
}

class AssetKit {
  final String id;
  final String eventId;
  final String name;
  final List<String> assetIds;
  final GearStatus status;
  final String? checkedOutByUserId;

  const AssetKit({
    required this.id,
    required this.eventId,
    required this.name,
    this.assetIds = const [],
    this.status = GearStatus.available,
    this.checkedOutByUserId,
  });

  AssetKit copyWith({
    String? id, String? eventId, String? name,
    List<String>? assetIds, GearStatus? status,
    String? checkedOutByUserId,
  }) => AssetKit(
    id: id ?? this.id, eventId: eventId ?? this.eventId,
    name: name ?? this.name, assetIds: assetIds ?? this.assetIds,
    status: status ?? this.status,
    checkedOutByUserId: checkedOutByUserId ?? this.checkedOutByUserId,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'name': name,
    'assetIds': assetIds, 'status': status.name,
    'checkedOutByUserId': checkedOutByUserId,
  };

  factory AssetKit.fromJson(Map<String, dynamic> j) => AssetKit(
    id: j['id'] as String, eventId: j['eventId'] as String,
    name: j['name'] as String,
    assetIds: List<String>.from(j['assetIds'] as List? ?? []),
    status: GearStatus.fromString(j['status'] as String? ?? ''),
    checkedOutByUserId: j['checkedOutByUserId'] as String?,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ATTENDANCE
// ══════════════════════════════════════════════════════════════════════════════

class AttendanceRound {
  final String id;
  final String eventId;
  final int roundNumber;
  final DateTime openedAt;
  final DateTime? closedAt;
  final Duration windowDuration;
  final String? qrPayload; // rotating QR code content

  const AttendanceRound({
    required this.id,
    required this.eventId,
    required this.roundNumber,
    required this.openedAt,
    this.closedAt,
    this.windowDuration = const Duration(minutes: 10),
    this.qrPayload,
  });

  bool get isActive => closedAt == null && DateTime.now().isBefore(openedAt.add(windowDuration));

  AttendanceRound copyWith({
    String? id, String? eventId, int? roundNumber,
    DateTime? openedAt, DateTime? closedAt,
    Duration? windowDuration, String? qrPayload,
  }) => AttendanceRound(
    id: id ?? this.id, eventId: eventId ?? this.eventId,
    roundNumber: roundNumber ?? this.roundNumber,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt ?? this.closedAt,
    windowDuration: windowDuration ?? this.windowDuration,
    qrPayload: qrPayload ?? this.qrPayload,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'roundNumber': roundNumber,
    'openedAt': openedAt.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'windowDurationSeconds': windowDuration.inSeconds,
    'qrPayload': qrPayload,
  };

  factory AttendanceRound.fromJson(Map<String, dynamic> j) => AttendanceRound(
    id: j['id'] as String, eventId: j['eventId'] as String,
    roundNumber: j['roundNumber'] as int,
    openedAt: DateTime.parse(j['openedAt'] as String),
    closedAt: j['closedAt'] != null ? DateTime.parse(j['closedAt'] as String) : null,
    windowDuration: Duration(seconds: (j['windowDurationSeconds'] as int?) ?? 600),
    qrPayload: j['qrPayload'] as String?,
  );
}

class AttendanceResponse {
  final String id;
  final String roundId;
  final String userId;
  final DateTime markedAt;
  final bool isPresent;

  const AttendanceResponse({
    required this.id,
    required this.roundId,
    required this.userId,
    required this.markedAt,
    this.isPresent = true,
  });

  AttendanceResponse copyWith({
    String? id, String? roundId, String? userId,
    DateTime? markedAt, bool? isPresent,
  }) => AttendanceResponse(
    id: id ?? this.id, roundId: roundId ?? this.roundId,
    userId: userId ?? this.userId,
    markedAt: markedAt ?? this.markedAt,
    isPresent: isPresent ?? this.isPresent,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'roundId': roundId, 'userId': userId,
    'markedAt': markedAt.toIso8601String(), 'isPresent': isPresent,
  };

  factory AttendanceResponse.fromJson(Map<String, dynamic> j) => AttendanceResponse(
    id: j['id'] as String, roundId: j['roundId'] as String,
    userId: j['userId'] as String,
    markedAt: DateTime.parse(j['markedAt'] as String),
    isPresent: (j['isPresent'] as bool?) ?? true,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// MESSAGING / CHANNELS
// ══════════════════════════════════════════════════════════════════════════════

class Channel {
  final String id;
  final String eventId;
  final String name;         // e.g. "media-all", "squad-3"
  final String? description;
  final bool isAnnouncement; // announcement-only channel
  final List<String> memberIds;
  final int unreadCount;

  const Channel({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    this.isAnnouncement = false,
    this.memberIds = const [],
    this.unreadCount = 0,
  });

  Channel copyWith({
    String? id, String? eventId, String? name,
    String? description, bool? isAnnouncement,
    List<String>? memberIds, int? unreadCount,
  }) => Channel(
    id: id ?? this.id, eventId: eventId ?? this.eventId,
    name: name ?? this.name, description: description ?? this.description,
    isAnnouncement: isAnnouncement ?? this.isAnnouncement,
    memberIds: memberIds ?? this.memberIds,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'name': name,
    'description': description, 'isAnnouncement': isAnnouncement,
    'memberIds': memberIds, 'unreadCount': unreadCount,
  };

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    id: j['id'] as String, eventId: j['eventId'] as String,
    name: j['name'] as String, description: j['description'] as String?,
    isAnnouncement: (j['isAnnouncement'] as bool?) ?? false,
    memberIds: List<String>.from(j['memberIds'] as List? ?? []),
    unreadCount: (j['unreadCount'] as int?) ?? 0,
  );
}

class ChatMessage {
  final String id;
  final String channelId;
  final String senderUserId;
  final String senderName;
  final String? text;
  final String? imageUrl;
  final String? locationLabel;
  final DateTime sentAt;
  final bool isAnnouncement;
  final bool requiresAck;
  final List<String> ackedByUserIds;

  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderUserId,
    required this.senderName,
    this.text,
    this.imageUrl,
    this.locationLabel,
    required this.sentAt,
    this.isAnnouncement = false,
    this.requiresAck = false,
    this.ackedByUserIds = const [],
  });

  ChatMessage copyWith({
    String? id, String? channelId, String? senderUserId,
    String? senderName, String? text, String? imageUrl,
    String? locationLabel, DateTime? sentAt,
    bool? isAnnouncement, bool? requiresAck,
    List<String>? ackedByUserIds,
  }) => ChatMessage(
    id: id ?? this.id, channelId: channelId ?? this.channelId,
    senderUserId: senderUserId ?? this.senderUserId,
    senderName: senderName ?? this.senderName,
    text: text ?? this.text, imageUrl: imageUrl ?? this.imageUrl,
    locationLabel: locationLabel ?? this.locationLabel,
    sentAt: sentAt ?? this.sentAt,
    isAnnouncement: isAnnouncement ?? this.isAnnouncement,
    requiresAck: requiresAck ?? this.requiresAck,
    ackedByUserIds: ackedByUserIds ?? this.ackedByUserIds,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'channelId': channelId,
    'senderUserId': senderUserId, 'senderName': senderName,
    'text': text, 'imageUrl': imageUrl,
    'locationLabel': locationLabel,
    'sentAt': sentAt.toIso8601String(),
    'isAnnouncement': isAnnouncement,
    'requiresAck': requiresAck,
    'ackedByUserIds': ackedByUserIds,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String, channelId: j['channelId'] as String,
    senderUserId: j['senderUserId'] as String,
    senderName: j['senderName'] as String,
    text: j['text'] as String?, imageUrl: j['imageUrl'] as String?,
    locationLabel: j['locationLabel'] as String?,
    sentAt: DateTime.parse(j['sentAt'] as String),
    isAnnouncement: (j['isAnnouncement'] as bool?) ?? false,
    requiresAck: (j['requiresAck'] as bool?) ?? false,
    ackedByUserIds: List<String>.from(j['ackedByUserIds'] as List? ?? []),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ISSUES
// ══════════════════════════════════════════════════════════════════════════════

class Issue {
  final String id;
  final String eventId;
  final String title;
  final String? description;
  final IssueCategory category;
  final IssueStatus status;
  final String reportedByUserId;
  final String? assignedToUserId;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final bool isEscalated;
  final String? photoUrl;
  final String? locationLabel;

  const Issue({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    required this.category,
    this.status = IssueStatus.open,
    required this.reportedByUserId,
    this.assignedToUserId,
    required this.reportedAt,
    this.resolvedAt,
    this.isEscalated = false,
    this.photoUrl,
    this.locationLabel,
  });

  Issue copyWith({
    String? id, String? eventId, String? title,
    String? description, IssueCategory? category, IssueStatus? status,
    String? reportedByUserId, String? assignedToUserId,
    DateTime? reportedAt, DateTime? resolvedAt,
    bool? isEscalated, String? photoUrl, String? locationLabel,
  }) => Issue(
    id: id ?? this.id, eventId: eventId ?? this.eventId,
    title: title ?? this.title, description: description ?? this.description,
    category: category ?? this.category, status: status ?? this.status,
    reportedByUserId: reportedByUserId ?? this.reportedByUserId,
    assignedToUserId: assignedToUserId ?? this.assignedToUserId,
    reportedAt: reportedAt ?? this.reportedAt,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    isEscalated: isEscalated ?? this.isEscalated,
    photoUrl: photoUrl ?? this.photoUrl,
    locationLabel: locationLabel ?? this.locationLabel,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'title': title, 'description': description,
    'category': category.name, 'status': status.name,
    'reportedByUserId': reportedByUserId,
    'assignedToUserId': assignedToUserId,
    'reportedAt': reportedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'isEscalated': isEscalated,
    'photoUrl': photoUrl, 'locationLabel': locationLabel,
  };

  factory Issue.fromJson(Map<String, dynamic> j) => Issue(
    id: j['id'] as String, eventId: j['eventId'] as String,
    title: j['title'] as String, description: j['description'] as String?,
    category: IssueCategory.fromString(j['category'] as String? ?? ''),
    status: IssueStatus.fromString(j['status'] as String? ?? ''),
    reportedByUserId: j['reportedByUserId'] as String,
    assignedToUserId: j['assignedToUserId'] as String?,
    reportedAt: DateTime.parse(j['reportedAt'] as String),
    resolvedAt: j['resolvedAt'] != null ? DateTime.parse(j['resolvedAt'] as String) : null,
    isEscalated: (j['isEscalated'] as bool?) ?? false,
    photoUrl: j['photoUrl'] as String?,
    locationLabel: j['locationLabel'] as String?,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// PIPELINE / DATA MANAGEMENT
// ══════════════════════════════════════════════════════════════════════════════

class DumpStation {
  final String id;
  final String eventId;
  final String name;         // e.g. "Dump Station 1 — Hall A"
  final DumpStationStatus status;
  final String? operatorUserId;
  final String? locationLabel;

  const DumpStation({
    required this.id,
    required this.eventId,
    required this.name,
    this.status = DumpStationStatus.closed,
    this.operatorUserId,
    this.locationLabel,
  });

  DumpStation copyWith({
    String? id, String? eventId, String? name,
    DumpStationStatus? status, String? operatorUserId, String? locationLabel,
  }) => DumpStation(
    id: id ?? this.id, eventId: eventId ?? this.eventId,
    name: name ?? this.name, status: status ?? this.status,
    operatorUserId: operatorUserId ?? this.operatorUserId,
    locationLabel: locationLabel ?? this.locationLabel,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'name': name,
    'status': status.name, 'operatorUserId': operatorUserId,
    'locationLabel': locationLabel,
  };

  factory DumpStation.fromJson(Map<String, dynamic> j) => DumpStation(
    id: j['id'] as String, eventId: j['eventId'] as String,
    name: j['name'] as String,
    status: DumpStationStatus.fromString(j['status'] as String? ?? ''),
    operatorUserId: j['operatorUserId'] as String?,
    locationLabel: j['locationLabel'] as String?,
  );
}

/// Represents a media card's journey through the ingest pipeline.
class DataCard {
  final String id;
  final String shootSlotId;
  final String eventId;
  final String? assignedEditorUserId;
  final PipelineStage stage;
  final DataSafetyLevel safetyLevel;
  final int fileCount;
  final double sizeGb;
  final DateTime lastUpdatedAt;
  final String? dumpStationId;
  final String? notes;

  const DataCard({
    required this.id,
    required this.shootSlotId,
    required this.eventId,
    this.assignedEditorUserId,
    this.stage = PipelineStage.shot,
    this.safetyLevel = DataSafetyLevel.atRisk,
    this.fileCount = 0,
    this.sizeGb = 0,
    required this.lastUpdatedAt,
    this.dumpStationId,
    this.notes,
  });

  bool get isStalled =>
      DateTime.now().difference(lastUpdatedAt) > const Duration(hours: 2);

  DataCard copyWith({
    String? id, String? shootSlotId, String? eventId,
    String? assignedEditorUserId, PipelineStage? stage,
    DataSafetyLevel? safetyLevel, int? fileCount, double? sizeGb,
    DateTime? lastUpdatedAt, String? dumpStationId, String? notes,
  }) => DataCard(
    id: id ?? this.id, shootSlotId: shootSlotId ?? this.shootSlotId,
    eventId: eventId ?? this.eventId,
    assignedEditorUserId: assignedEditorUserId ?? this.assignedEditorUserId,
    stage: stage ?? this.stage, safetyLevel: safetyLevel ?? this.safetyLevel,
    fileCount: fileCount ?? this.fileCount, sizeGb: sizeGb ?? this.sizeGb,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    dumpStationId: dumpStationId ?? this.dumpStationId,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'shootSlotId': shootSlotId, 'eventId': eventId,
    'assignedEditorUserId': assignedEditorUserId,
    'stage': stage.name, 'safetyLevel': safetyLevel.name,
    'fileCount': fileCount, 'sizeGb': sizeGb,
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    'dumpStationId': dumpStationId, 'notes': notes,
  };

  factory DataCard.fromJson(Map<String, dynamic> j) => DataCard(
    id: j['id'] as String, shootSlotId: j['shootSlotId'] as String,
    eventId: j['eventId'] as String,
    assignedEditorUserId: j['assignedEditorUserId'] as String?,
    stage: PipelineStage.fromString(j['stage'] as String? ?? ''),
    safetyLevel: DataSafetyLevel.values.firstWhere(
      (e) => e.name == j['safetyLevel'],
      orElse: () => DataSafetyLevel.atRisk,
    ),
    fileCount: (j['fileCount'] as int?) ?? 0,
    sizeGb: (j['sizeGb'] as num?)?.toDouble() ?? 0,
    lastUpdatedAt: DateTime.parse(j['lastUpdatedAt'] as String),
    dumpStationId: j['dumpStationId'] as String?,
    notes: j['notes'] as String?,
  );
}
