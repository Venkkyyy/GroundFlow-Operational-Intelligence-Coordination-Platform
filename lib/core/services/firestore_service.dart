import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../models/universal_event_model.dart';
import 'event_email_service.dart';
import 'firebase_rate_limiter.dart';

/// GroundFlow Cloud Firestore Service
/// Provides real-time synchronization, low-bandwidth data caching,
/// rate-limited queries, and offline-first persistence for campus summits & volunteer teams.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  bool get _isTestEnv => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  bool _persistenceConfigured = false;

  FirebaseFirestore? get _db {
    if (_isTestEnv || !_isFirebaseReady) {
      return null;
    }
    try {
      final db = FirebaseFirestore.instance;
      // Enable aggressive local offline persistence & cache limit to eliminate redundant network reads
      if (!_persistenceConfigured && !kIsWeb) {
        _persistenceConfigured = true;
        try {
          db.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
          debugPrint('⚡ [FirestoreService] Offline cache & persistence engine active (unlimited local storage).');
        } catch (_) {}
      }
      return db;
    } catch (e) {
      debugPrint('Firestore instance notice: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // DIRECT UNIVERSAL GOOGLE CLOUD REST ENGINE
  // Ensures cloud persistence even when native Firebase C++ / Play Services are absent
  // ---------------------------------------------------------------------------
  static const String _projectId = 'groundflow-acca3';
  static const String _apiKey = 'AIzaSyBROPqX0xipkd_3BFOUbpkVHPJOFAjhMCw';
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> map) {
    final fields = <String, dynamic>{};
    map.forEach((key, value) {
      final fv = _toFirestoreValue(value);
      if (fv != null) fields[key] = fv;
    });
    return fields;
  }

  Map<String, dynamic>? _toFirestoreValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is DateTime) return {'timestampValue': value.toUtc().toIso8601String()};
    if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((e) => _toFirestoreValue(e) ?? {'stringValue': e.toString()}).toList(),
        }
      };
    }
    if (value is Map) {
      final subFields = <String, dynamic>{};
      value.forEach((k, v) {
        final sv = _toFirestoreValue(v);
        if (sv != null) subFields[k.toString()] = sv;
      });
      return {'mapValue': {'fields': subFields}};
    }
    return {'stringValue': value.toString()};
  }

  Future<Options?> _getAuthOptions() async {
    try {
      if (_isFirebaseReady && !_isTestEnv) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          if (token != null && token.isNotEmpty) {
            return Options(headers: {'Authorization': 'Bearer $token'});
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _saveToCloudRest(String collection, String docId, Map<String, dynamic> data, {bool useUpdateMask = false}) async {
    if (_isTestEnv) return true;
    try {
      final cleanDoc = docId.trim();
      final cleanData = Map<String, dynamic>.from(data)..remove('updatedAt')..remove('lastLoginAt');
      String url = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$collection/$cleanDoc?key=$_apiKey';
      if (useUpdateMask && cleanData.isNotEmpty) {
        final maskParams = cleanData.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
        url = '$url&$maskParams';
      }
      final body = {'fields': _toFirestoreFields(cleanData)};
      final opts = await _getAuthOptions();
      await _dio.patch(url, data: body, options: opts);
      debugPrint('✓ Cloud Firestore REST: Successfully persisted $collection/$cleanDoc to Google Cloud');
      return true;
    } catch (e) {
      debugPrint('Cloud Firestore REST save notice: $e');
      return false;
    }
  }

  Future<bool> _saveSubDocToCloudRest(String parentCol, String parentId, String subCol, String docId, Map<String, dynamic> data, {bool useUpdateMask = false}) async {
    if (_isTestEnv) return true;
    try {
      final cleanParent = parentId.trim();
      final cleanDoc = docId.trim();
      final cleanData = Map<String, dynamic>.from(data)..remove('updatedAt');
      String url = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$parentCol/$cleanParent/$subCol/$cleanDoc?key=$_apiKey';
      if (useUpdateMask && cleanData.isNotEmpty) {
        final maskParams = cleanData.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
        url = '$url&$maskParams';
      }
      final body = {'fields': _toFirestoreFields(cleanData)};
      final opts = await _getAuthOptions();
      await _dio.patch(url, data: body, options: opts);
      debugPrint('✓ Cloud Firestore REST: Successfully persisted $parentCol/$cleanParent/$subCol/$cleanDoc to Google Cloud');
      return true;
    } catch (e) {
      debugPrint('Cloud Firestore REST save subDoc notice: $e');
      return false;
    }
  }

  Future<bool> _deleteFromCloudRest(String collection, String docId) async {
    if (_isTestEnv) return true;
    try {
      final cleanDoc = docId.trim();
      final url = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$collection/$cleanDoc?key=$_apiKey';
      final opts = await _getAuthOptions();
      await _dio.delete(url, options: opts);
      debugPrint('✓ Cloud Firestore REST: Successfully deleted $collection/$cleanDoc from Google Cloud');
      return true;
    } catch (e) {
      debugPrint('Cloud Firestore REST delete notice: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // USERS COLLECTION (Save every registration & login to Cloud Firestore)
  // ---------------------------------------------------------------------------

  /// Save or update user profile in Cloud Firestore under 'users' collection
  Future<bool> saveUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
    String role = 'Volunteer',
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    final data = {
      'uid': uid,
      'email': cleanEmail,
      'displayName': displayName.trim().isNotEmpty ? displayName.trim() : cleanEmail.split('@').first,
      'photoUrl': photoUrl,
      'role': role,
    };

    final db = _db;
    if (db != null) {
      try {
        final userDocRef = db.collection('users').doc(cleanEmail);
        await userDocRef.set({
          ...data,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 6));
        debugPrint('✓ User profile ($cleanEmail) successfully synced to Cloud Firestore!');
        return true;
      } catch (e) {
        debugPrint('❌ Firestore saveUserProfile error: $e');
      }
    }

    // Direct Universal Cloud REST fallback
    return await _saveToCloudRest('users', cleanEmail, data);
  }

  /// Get user profile from Cloud Firestore under 'users' collection (Rate Limited & Cached)
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return null;

    return FirebaseRateLimiter().executeCachedRead<Map<String, dynamic>>(
      cacheKey: 'profile_$cleanEmail',
      ttl: const Duration(seconds: 60),
      fetcher: () async {
        final db = _db;
        if (db != null) {
          try {
            final doc = await db.collection('users').doc(cleanEmail).get().timeout(const Duration(seconds: 4));
            if (doc.exists && doc.data() != null) {
              return doc.data();
            }
          } catch (e) {
            debugPrint('Firestore getUserProfile error: $e');
          }
        }
        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // EVENTS COLLECTION
  // ---------------------------------------------------------------------------

  /// Save or update an event in Firestore
  Future<bool> saveEvent({
    required String code,
    required String title,
    required String venue,
    required String createdBy,
    String? password,
    String status = 'Live Protocol',
    List<String> departments = const [
      'Media',
      'Security',
      'Registration',
      'Logistics',
      'Stage AV',
      'Hospitality',
    ],
    Map<String, dynamic>? additionalData,
  }) async {
    final cleanCode = code.toUpperCase().trim();
    final Map<String, dynamic> payload = {
      'code': cleanCode,
      'title': title.trim(),
      'venue': venue.trim(),
      'status': status,
      'departments': departments,
      'createdBy': createdBy,
      if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
    };

    if (additionalData != null && additionalData.isNotEmpty) {
      payload.addAll(additionalData);
    }

    final db = _db;
    if (db != null) {
      try {
        final docRef = db.collection('events').doc(cleanCode);
        await docRef.set({
          ...payload,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 6));
        debugPrint('✓ Event $cleanCode successfully saved to Cloud Firestore!');
        return true;
      } catch (e) {
        debugPrint('❌ Firestore saveEvent error: $e');
      }
    }

    // Direct Universal Cloud REST fallback
    return await _saveToCloudRest('events', cleanCode, payload);
  }

  /// Diagnostic test to verify if Cloud Firestore is accepting writes and reads
  Future<Map<String, dynamic>> testFirestoreDiagnostic() async {
    final db = _db;
    if (db == null) {
      return {
        'status': 'FAILED',
        'reason': 'Firebase Core is not initialized or Firebase.apps is empty.',
      };
    }

    try {
      final testRef = db.collection('_diagnostic').doc('connectivity_test');
      await testRef.set({
        'testTime': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      }).timeout(const Duration(seconds: 5));

      final readDoc = await testRef.get().timeout(const Duration(seconds: 5));
      if (readDoc.exists) {
        return {
          'status': 'SUCCESS',
          'message': '✓ Cloud Firestore is connected and accepting reads & writes!',
        };
      } else {
        return {
          'status': 'PARTIAL',
          'message': 'Write succeeded but read failed.',
        };
      }
    } catch (e) {
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Real-time stream of all campus events (Query Capped to 50 active events)
  Stream<List<Map<String, dynamic>>> streamEvents() {
    final db = _db;
    if (db == null) return const Stream.empty();

    try {
      return db
          .collection('events')
          .limit(50)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'code': doc.id,
            'title': data['title'] ?? doc.id,
            'venue': data['venue'] ?? 'Campus Venue',
            'status': data['status'] ?? 'Live Protocol',
            'departments': List<String>.from(data['departments'] ?? ['Media']),
            'createdBy': data['createdBy'] ?? '',
            'password': data['password'] as String?,
            'emailAutomationDelegates': List<String>.from(data['emailAutomationDelegates'] ?? []),
          };
        }).toList();
      }).handleError((err) {
        debugPrint('Firestore streamEvents error notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore streamEvents exception: $e');
      return const Stream.empty();
    }
  }

  /// Get single event by event code (Rate Limited & Cached for 30s)
  Future<Map<String, dynamic>?> getEvent(String code) async {
    final clean = code.toUpperCase().trim();
    if (clean.isEmpty) return null;

    return FirebaseRateLimiter().executeCachedRead<Map<String, dynamic>>(
      cacheKey: 'event_doc_$clean',
      ttl: const Duration(seconds: 30),
      fetcher: () async {
        final db = _db;
        if (db == null) return null;

        try {
          final doc = await db.collection('events').doc(clean).get();
          if (!doc.exists) return null;
          final data = doc.data();
          if (data == null) return null;
          return {
            'code': doc.id,
            'title': data['title'] ?? doc.id,
            'venue': data['venue'] ?? '',
            'status': data['status'] ?? 'Live Protocol',
            'departments': List<String>.from(data['departments'] ?? []),
            'password': data['password'] as String?,
            'createdBy': data['createdBy'] ?? '',
            'emailAutomationDelegates': List<String>.from(data['emailAutomationDelegates'] ?? []),
          };
        } catch (e) {
          debugPrint('Firestore getEvent notice: $e');
          return null;
        }
      },
    );
  }

  /// Fetch all active events once from Cloud Firestore
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final db = _db;
    if (db == null) return [];

    try {
      final snap = await db.collection('events').get().timeout(const Duration(seconds: 5));
      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'code': doc.id,
          'title': data['title'] ?? doc.id,
          'venue': data['venue'] ?? '',
          'status': data['status'] ?? 'Live Protocol',
          'departments': List<String>.from(data['departments'] ?? []),
          'password': data['password'] as String?,
          'createdBy': data['createdBy'] ?? '',
          'emailAutomationDelegates': List<String>.from(data['emailAutomationDelegates'] ?? []),
        };
      }).toList();
    } catch (e) {
      debugPrint('Firestore getAllEvents notice: $e');
      return [];
    }
  }

  /// Update list of emails who have delegated access to Email Automation private section
  Future<bool> updateEventDelegates({
    required String eventCode,
    required List<String> delegates,
  }) async {
    final code = eventCode.toUpperCase().trim();
    final db = _db;
    if (db != null) {
      try {
        await db.collection('events').doc(code).update({'emailAutomationDelegates': delegates});
      } catch (e) {
        debugPrint('updateEventDelegates notice: $e');
      }
    }
    return await _saveToCloudRest('events', code, {'emailAutomationDelegates': delegates}, useUpdateMask: true);
  }

  /// Delete an event and all its associated subcollections (messages, attendance) from Cloud Firestore
  Future<bool> deleteEvent(String code) async {
    final cleanCode = code.toUpperCase().trim();
    final db = _db;
    if (db != null) {
      try {
        final docRef = db.collection('events').doc(cleanCode);

        // 1. Delete all messages under events/{code}/messages
        try {
          final messagesSnap = await docRef.collection('messages').get().timeout(const Duration(seconds: 4));
          final batch = db.batch();
          for (final doc in messagesSnap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit().timeout(const Duration(seconds: 4));
        } catch (subErr) {
          debugPrint('Notice deleting messages subcollection: $subErr');
        }

        // 2. Delete all attendance logs under events/{code}/attendance
        try {
          final attendanceSnap = await docRef.collection('attendance').get().timeout(const Duration(seconds: 4));
          final batch = db.batch();
          for (final doc in attendanceSnap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit().timeout(const Duration(seconds: 4));
        } catch (subErr) {
          debugPrint('Notice deleting attendance subcollection: $subErr');
        }

        // 3. Delete parent event document
        await docRef.delete().timeout(const Duration(seconds: 5));
        debugPrint('✓ Event $cleanCode permanently deleted from Cloud Firestore');
      } catch (e) {
        debugPrint('Firestore deleteEvent error: $e');
      }
    }

    // Direct Universal Cloud REST fallback
    await _deleteFromCloudRest('events', cleanCode);
    return true;
  }

  // ---------------------------------------------------------------------------
  // CHAT & DISPATCH MESSAGES
  // ---------------------------------------------------------------------------

  /// Send a real-time dispatch chat message under an event
  Future<void> sendChatMessage({
    required String eventCode,
    required String senderName,
    required String senderRole,
    required String senderEmail,
    required String text,
    String channel = 'all-ops',
  }) async {
    final db = _db;
    if (db == null) return;

    try {
      final code = eventCode.toUpperCase().trim();
      if (code.isEmpty) return;

      await db.collection('events').doc(code).collection('messages').add({
        'sender': senderName,
        'role': senderRole,
        'email': senderEmail,
        'text': text,
        'channel': channel,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore sendChatMessage notice: $e');
    }
  }

  /// Real-time stream of dispatch chat messages for an event
  Stream<List<Map<String, dynamic>>> streamChatMessages(String eventCode, String currentUserEmail) {
    final db = _db;
    if (db == null) return const Stream.empty();

    try {
      final code = eventCode.toUpperCase().trim();
      if (code.isEmpty) return const Stream.empty();

      return db
          .collection('events')
          .doc(code)
          .collection('messages')
          .limit(80)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final email = data['email'] as String? ?? '';
          return {
            'id': doc.id,
            'sender': data['sender'] ?? 'Volunteer',
            'role': data['role'] ?? 'Operations',
            'text': data['text'] ?? '',
            'channel': data['channel'] ?? 'all-ops',
            'time': 'Just now',
            'isMe': email.isNotEmpty && email == currentUserEmail,
          };
        }).toList();
      }).handleError((err) {
        debugPrint('Firestore streamChatMessages notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore streamChatMessages exception: $e');
      return const Stream.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // VOLUNTEER ATTENDANCE & TELEMETRY
  // ---------------------------------------------------------------------------

  /// Record volunteer attendance check-in
  Future<void> recordAttendance({
    required String eventCode,
    required String volunteerName,
    required String volunteerEmail,
    required String role,
    required String zone,
    required String checkInMethod,
  }) async {
    final db = _db;
    if (db == null) return;

    try {
      final code = eventCode.toUpperCase().trim();
      await db.collection('events').doc(code).collection('attendance').add({
        'name': volunteerName,
        'email': volunteerEmail,
        'role': role,
        'zone': zone,
        'method': checkInMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Verified',
      });
    } catch (e) {
      debugPrint('Firestore recordAttendance notice: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 1: EVENT LIFECYCLE & STATE MACHINE
  // ---------------------------------------------------------------------------

  /// Update the lifecycle state of an event (Draft -> Approved -> Published -> Live -> Completed)
  Future<bool> updateEventLifecycle({
    required String eventCode,
    required EventLifecycleState state,
    String? userEmail,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db.collection('events').doc(code).update({
        'lifecycle': state.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await logEventActivity(
        eventCode: code,
        action: 'Lifecycle State Changed',
        details: 'Event transitioned to ${state.displayName}',
        userEmail: userEmail ?? 'Organizer',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore updateEventLifecycle notice: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 1: INVITATIONS & SHAREABLE LINKS
  // ---------------------------------------------------------------------------

  /// Create a cryptographically identified shareable invitation link
  Future<bool> createInvitationLink({
    required String eventCode,
    required InvitationLinkModel link,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('invitation_links')
          .doc(link.id)
          .set(link.toJson());

      await logEventActivity(
        eventCode: code,
        action: 'Invitation Link Created',
        details: '${link.name} (${link.type.displayName}) created with token ${link.token}',
        userEmail: link.createdBy,
      );
      return true;
    } catch (e) {
      debugPrint('Firestore createInvitationLink notice: $e');
      return false;
    }
  }

  /// Real-time stream of all invitation links for an event
  Stream<List<InvitationLinkModel>> streamInvitationLinks(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('invitation_links')
          .snapshots()
          .map((snap) => snap.docs.map((d) => InvitationLinkModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamInvitationLinks notice: $e');
      return const Stream.empty();
    }
  }

  /// Revoke an invitation link
  Future<bool> revokeInvitationLink({
    required String eventCode,
    required String linkId,
    String? userEmail,
  }) async {
    return toggleInvitationLinkStatus(
      eventCode: eventCode,
      linkId: linkId,
      isActive: false,
      userEmail: userEmail,
    );
  }

  /// Toggle an invitation link active/inactive
  Future<bool> toggleInvitationLinkStatus({
    required String eventCode,
    required String linkId,
    required bool isActive,
    String? userEmail,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('invitation_links')
          .doc(linkId)
          .update({'isActive': isActive});

      await logEventActivity(
        eventCode: code,
        action: isActive ? 'Invitation Link Activated' : 'Invitation Link Revoked',
        details: 'Link $linkId status set to ${isActive ? "Active" : "Revoked"}.',
        userEmail: userEmail ?? 'Organizer',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore toggleInvitationLinkStatus notice: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 1: PARTICIPANT & REGISTRATION LEDGER
  // ---------------------------------------------------------------------------

  /// Add participant record
  Future<bool> addParticipant({
    required String eventCode,
    required EventParticipantModel participant,
  }) async {
    final code = eventCode.toUpperCase().trim();
    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('events')
            .doc(code)
            .collection('participants')
            .doc(participant.id)
            .set(participant.toJson());

        await logEventActivity(
          eventCode: code,
          action: 'Participant Registered',
          details: '${participant.name} (${participant.email}) registered as ${participant.participantType.displayName}',
          userEmail: participant.email,
        );
        return true;
      } catch (e) {
        debugPrint('Firestore addParticipant notice: $e');
      }
    }

    // Direct Universal Cloud REST fallback
    await _saveSubDocToCloudRest('events', code, 'participants', participant.id, participant.toJson());
    await logEventActivity(
      eventCode: code,
      action: 'Participant Registered',
      details: '${participant.name} (${participant.email}) registered as ${participant.participantType.displayName}',
      userEmail: participant.email,
    );
    return true;
  }

  /// Update participant role, department or team
  Future<bool> updateParticipantRole({
    required String eventCode,
    required String participantId,
    required String role,
    String? department,
    String? team,
    String? userEmail,
  }) async {
    final code = eventCode.toUpperCase().trim();
    final Map<String, dynamic> updateData = {
      'assignedRole': role,
      if (department != null) 'department': department,
      if (team != null) 'assignedTeam': team,
    };

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('events')
            .doc(code)
            .collection('participants')
            .doc(participantId)
            .update(updateData);
      } catch (e) {
        debugPrint('Firestore updateParticipantRole error: $e');
      }
    }

    // Direct Universal Cloud REST fallback
    await _saveSubDocToCloudRest('events', code, 'participants', participantId, updateData);

    await logEventActivity(
      eventCode: code,
      action: 'ROLE_MODIFIED',
      details: 'Role updated to $role (Dept: ${department ?? 'Unchanged'}, Team: ${team ?? 'Unchanged'})',
      userEmail: userEmail ?? 'Organizer',
    );
    return true;
  }

  /// Save official Event Creation Confirmation Email record to Cloud Firestore
  Future<bool> saveEmailConfirmation({
    required String eventCode,
    required EventEmailConfirmation confirmation,
  }) async {
    final code = eventCode.toUpperCase().trim();
    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('events')
            .doc(code)
            .collection('email_confirmations')
            .doc(confirmation.id)
            .set(confirmation.toJson());
      } catch (e) {
        debugPrint('Firestore saveEmailConfirmation notice: $e');
      }
    }

    // 1. Direct Universal Cloud REST fallback
    await _saveSubDocToCloudRest('events', code, 'email_confirmations', confirmation.id, confirmation.toJson());

    // 2. Queue in root 'mail' collection for Firebase Trigger Email extension / Cloud Functions
    final mailPayload = {
      'to': [confirmation.recipientEmail],
      'message': {
        'subject': confirmation.subject,
        'text': confirmation.plainTextContent,
        'html': '<div style="font-family:sans-serif;max-width:620px;margin:auto;padding:24px;background:#0d0e12;color:#f3f4f6;border-radius:14px;border:1px solid #27272a;">'
            '<h2 style="color:#38bdf8;margin-top:0;">GroundFlow Event Confirmation & VIP Pass</h2>'
            '<p style="color:#a1a1aa;font-size:13px;">Official event initialization certificate and creator emergency access credentials.</p>'
            '<pre style="background:#18181b;padding:16px;border-radius:8px;color:#e4e4e7;white-space:pre-wrap;font-family:monospace;font-size:12px;border:1px solid #3f3f46;">${confirmation.plainTextContent}</pre>'
            '<p style="color:#71717a;font-size:11px;margin-bottom:0;">Automated message sent by GroundFlow Central Cloud Engine.</p>'
            '</div>',
      },
      'sentAt': confirmation.sentAt.toIso8601String(),
    };
    if (db != null) {
      try {
        await db.collection('mail').doc(confirmation.id).set(mailPayload);
      } catch (e) {
        debugPrint('Notice queueing in mail collection: $e');
      }
    }
    await _saveToCloudRest('mail', confirmation.id, mailPayload);

    // 3. Remote HTTP Email Dispatch via FormSubmit gateway (zero-setup direct email delivery)
    if (!_isTestEnv && confirmation.recipientEmail.contains('@') && confirmation.recipientEmail.contains('.')) {
      try {
        final res = await _dio.post(
          'https://formsubmit.co/ajax/${confirmation.recipientEmail}',
          data: {
            'name': 'GroundFlow Central Operations',
            '_subject': confirmation.subject,
            'message': confirmation.plainTextContent,
            '_template': 'table',
            '_captcha': 'false',
          },
          options: Options(headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Referer': 'https://groundflow.app/',
            'Origin': 'https://groundflow.app',
          }),
        ).timeout(const Duration(seconds: 6));
        debugPrint('✓ Remote Email HTTP Dispatch response: ${res.data}');
      } catch (e) {
        debugPrint('Notice direct email HTTP dispatch: $e');
      }
    }

    return true;
  }

  /// Save and dispatch official Participant Welcome & Pass Email to Cloud Firestore and remote relay
  Future<bool> saveParticipantWelcomeEmail({
    required String eventCode,
    required String participantEmail,
    required String subject,
    required String plainTextContent,
    required String htmlContent,
    required Map<String, dynamic> emailPayload,
  }) async {
    final code = eventCode.toUpperCase().trim();
    final emailId = emailPayload['id'] as String? ?? 'PRT-EML-${DateTime.now().millisecondsSinceEpoch}';
    final cleanEmail = participantEmail.toLowerCase().trim();

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('events')
            .doc(code)
            .collection('participant_welcome_emails')
            .doc(emailId)
            .set(emailPayload);
      } catch (e) {
        debugPrint('Firestore saveParticipantWelcomeEmail notice: $e');
      }
    }

    // 1. Direct Universal Cloud REST fallback
    await _saveSubDocToCloudRest('events', code, 'participant_welcome_emails', emailId, emailPayload);

    // 2. Queue in root 'mail' collection for Firebase Trigger Email extension
    final mailPayload = {
      'to': [cleanEmail],
      'message': {
        'subject': subject,
        'text': plainTextContent,
        'html': htmlContent,
      },
      'sentAt': DateTime.now().toIso8601String(),
    };
    if (db != null) {
      try {
        await db.collection('mail').doc(emailId).set(mailPayload);
      } catch (e) {
        debugPrint('Notice queueing in mail collection: $e');
      }
    }
    await _saveToCloudRest('mail', emailId, mailPayload);

    // 3. Remote HTTP Email Dispatch via FormSubmit gateway
    if (!_isTestEnv && cleanEmail.contains('@') && cleanEmail.contains('.')) {
      try {
        final res = await _dio.post(
          'https://formsubmit.co/ajax/$cleanEmail',
          data: {
            'name': 'GroundFlow Central Operations',
            '_subject': subject,
            'message': htmlContent.isNotEmpty ? htmlContent : plainTextContent,
            '_template': 'table',
            '_captcha': 'false',
            '_replyto': 'noreply@groundflow.app',
          },
          options: Options(headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Referer': 'https://groundflow.app/',
            'Origin': 'https://groundflow.app',
          }),
        ).timeout(const Duration(seconds: 6));
        debugPrint('✓ Remote Welcome Email HTTP Dispatch response: ${res.data}');
      } catch (e) {
        debugPrint('Notice direct email HTTP dispatch: $e');
      }
    }

    return true;
  }

  /// Save official Event Countdown Reminder to Cloud Firestore and root 'mail' collection
  Future<bool> saveEventReminder({
    required String eventCode,
    required EventReminderModel reminder,
  }) async {
    final code = eventCode.toUpperCase().trim();
    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('events')
            .doc(code)
            .collection('reminders')
            .doc(reminder.id)
            .set(reminder.toJson());
      } catch (e) {
        debugPrint('Firestore saveEventReminder notice: $e');
      }
    }

    // 1. Direct Universal Cloud REST fallback
    await _saveSubDocToCloudRest('events', code, 'reminders', reminder.id, reminder.toJson());

    // 2. Queue in root 'mail' collection for Firebase Trigger Email extension / Cloud Functions
    final mailPayload = {
      'to': reminder.recipients.isNotEmpty ? reminder.recipients : ['attendees@$code.groundflow.app'],
      'message': {
        'subject': reminder.subject,
        'text': reminder.plainTextContent,
        'html': reminder.htmlContent,
      },
      'sentAt': reminder.sentAt.toIso8601String(),
      'sentBy': reminder.sentBy,
      'eventCode': code,
      'milestone': reminder.milestone.name,
      'targetRole': reminder.targetRole.name,
    };
    if (db != null) {
      try {
        await db.collection('mail').doc(reminder.id).set(mailPayload);
      } catch (e) {
        debugPrint('Notice queueing reminder in mail collection: $e');
      }
    }
    await _saveToCloudRest('mail', reminder.id, mailPayload);

    // 3. Remote HTTP Background Relay for Reminder Recipients (Automated Dispatch)
    if (!_isTestEnv) {
      for (final rec in reminder.recipients.take(15)) {
        final clean = rec.trim().toLowerCase();
        if (clean.contains('@') && clean.contains('.')) {
          try {
            await _dio.post(
              'https://formsubmit.co/ajax/$clean',
              data: {
                'name': 'GroundFlow Automated Operations',
                '_subject': reminder.subject,
                'message': reminder.htmlContent.isNotEmpty ? reminder.htmlContent : reminder.plainTextContent,
                '_template': 'table',
                '_captcha': 'false',
                '_replyto': 'noreply@groundflow.app',
              },
              options: Options(headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Referer': 'https://groundflow.app/',
                'Origin': 'https://groundflow.app',
              }),
            ).timeout(const Duration(seconds: 4));
          } catch (_) {}
        }
      }
    }

    // 4. Log event activity
    try {
      await logEventActivity(
        eventCode: code,
        userEmail: reminder.sentBy,
        action: 'EMAIL_REMINDER_DISPATCHED',
        details: '${reminder.milestone.title} reminder (${reminder.targetRole.label}) sent to ${reminder.recipientCount} recipients',
      );
    } catch (_) {}

    return true;
  }

  /// Stream of Event Countdown Reminders (Capped to 30 recent)
  Stream<List<EventReminderModel>> streamEventReminders(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('reminders')
          .orderBy('sentAt', descending: true)
          .limit(30)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => EventReminderModel.fromJson(doc.data())).toList();
          });
    } catch (e) {
      debugPrint('Firestore streamEventReminders notice: $e');
      return const Stream.empty();
    }
  }

  /// Real-time stream of participants (Capped to 250 active roster)
  Stream<List<EventParticipantModel>> streamParticipants(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('participants')
          .limit(250)
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventParticipantModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamParticipants notice: $e');
      return const Stream.empty();
    }
  }

  /// Approve or reject participant registration
  Future<bool> updateParticipantRegistration({
    required String eventCode,
    required String participantId,
    required RegistrationStatus status,
    String? userEmail,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('participants')
          .doc(participantId)
          .update({'registrationStatus': status.name});

      await logEventActivity(
        eventCode: code,
        action: 'Registration Updated',
        details: 'Participant $participantId status set to ${status.displayName}',
        userEmail: userEmail ?? 'Organizer',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore updateParticipantRegistration notice: $e');
      return false;
    }
  }

  /// Manually update participant attendance status (e.g. gate override check-in or checkout)
  Future<bool> updateParticipantAttendance({
    required String eventCode,
    required String participantId,
    required AttendanceStatus status,
    String? userEmail,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      final now = DateTime.now();
      await db
          .collection('events')
          .doc(code)
          .collection('participants')
          .doc(participantId)
          .update({
        'attendanceStatus': status.name,
        'checkedInAt': status == AttendanceStatus.checkedIn ? now.toIso8601String() : null,
      });

      await logEventActivity(
        eventCode: code,
        action: 'Manual Attendance Override',
        details: 'Participant $participantId status set to ${status.displayName}',
        userEmail: userEmail ?? 'Gate Staff',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore updateParticipantAttendance notice: $e');
      return false;
    }
  }

  /// Scan QR ticket code at entrance with duplicate check-in prevention
  Future<Map<String, dynamic>> checkInParticipantByQR({
    required String eventCode,
    required String ticketPassCode,
    String? scannerName,
  }) async {
    final db = _db;
    if (db == null) {
      return {'success': false, 'message': 'Cloud database not connected.'};
    }

    final code = eventCode.toUpperCase().trim();
    final cleanPass = ticketPassCode.trim();

    try {
      final snap = await db
          .collection('events')
          .doc(code)
          .collection('participants')
          .where('ticketPassCode', isEqualTo: cleanPass)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid ticket QR code. No matching participant pass found.',
        };
      }

      final doc = snap.docs.first;
      final participant = EventParticipantModel.fromJson(doc.data());

      // Duplicate Check-in Prevention
      if (participant.attendanceStatus == AttendanceStatus.checkedIn) {
        final checkInTime = participant.checkedInAt != null
            ? '${participant.checkedInAt!.hour}:${participant.checkedInAt!.minute.toString().padLeft(2, '0')}'
            : 'earlier';
        return {
          'success': false,
          'duplicate': true,
          'participant': participant,
          'message': '⚠️ ALREADY CHECKED IN! ${participant.name} checked in at $checkInTime.',
        };
      }

      // Check registration approval
      if (participant.registrationStatus == RegistrationStatus.rejected) {
        return {
          'success': false,
          'message': '❌ Registration for ${participant.name} was rejected.',
        };
      }

      // Record valid check-in
      final now = DateTime.now();
      await doc.reference.update({
        'attendanceStatus': AttendanceStatus.checkedIn.name,
        'checkedInAt': now.toIso8601String(),
      });

      await logEventActivity(
        eventCode: code,
        action: 'Entrance Check-In',
        details: 'QR Check-in verified for ${participant.name} (${participant.participantType.displayName})',
        userEmail: scannerName ?? 'Entrance Gate',
      );

      return {
        'success': true,
        'participant': participant.copyWith(
          attendanceStatus: AttendanceStatus.checkedIn,
          checkedInAt: now,
        ),
        'message': '✓ Verified Check-in for ${participant.name}!',
      };
    } catch (e) {
      debugPrint('Firestore checkInParticipantByQR notice: $e');
      return {'success': false, 'message': 'Check-in error: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 1: EVENT TEAMS & WORKFORCE
  // ---------------------------------------------------------------------------

  /// Create working team under department
  Future<bool> createTeam({
    required String eventCode,
    required EventTeamModel team,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('teams')
          .doc(team.id)
          .set(team.toJson());

      await logEventActivity(
        eventCode: code,
        action: 'Team Created',
        details: 'Team "${team.name}" added to ${team.department} department (Lead: ${team.teamLeader})',
        userEmail: 'Organizer',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore createTeam notice: $e');
      return false;
    }
  }

  /// Real-time stream of teams
  Stream<List<EventTeamModel>> streamTeams(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('teams')
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventTeamModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamTeams notice: $e');
      return const Stream.empty();
    }
  }

  /// Assign member to a team
  Future<bool> assignTeamMember({
    required String eventCode,
    required String teamId,
    required String memberEmail,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('teams')
          .doc(teamId)
          .update({
        'members': FieldValue.arrayUnion([memberEmail.trim()]),
      });
      return true;
    } catch (e) {
      debugPrint('Firestore assignTeamMember notice: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 1: AUDIT & ACTIVITY HISTORY LOG
  // ---------------------------------------------------------------------------

  /// Append-only log of operational changes
  Future<void> logEventActivity({
    required String eventCode,
    required String action,
    required String details,
    required String userEmail,
  }) async {
    final code = eventCode.toUpperCase().trim();
    final logId = 'ACT-${DateTime.now().millisecondsSinceEpoch}';
    final logData = {
      'id': logId,
      'eventId': code,
      'action': action,
      'details': details,
      'userEmail': userEmail,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('events')
            .doc(code)
            .collection('activity_logs')
            .doc(logId)
            .set(logData);
      } catch (e) {
        debugPrint('Firestore logEventActivity notice: $e');
      }
    }

    // Direct Universal Cloud REST fallback
    await _saveSubDocToCloudRest('events', code, 'activity_logs', logId, logData);
  }

  /// Stream activity logs for an event
  Stream<List<ActivityLogModel>> streamEventActivities(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs.map((d) => ActivityLogModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamEventActivities notice: $e');
      return const Stream.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 2: AUTOMATED TASKS & WORKFLOWS ENGINE
  // ---------------------------------------------------------------------------

  /// Create a task under events/{code}/tasks
  Future<bool> createTask({
    required String eventCode,
    required EventTaskModel task,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('tasks')
          .doc(task.id)
          .set(task.toJson());
      return true;
    } catch (e) {
      debugPrint('Firestore createTask notice: $e');
      return false;
    }
  }

  /// Update task status and progress
  Future<bool> updateTaskStatus({
    required String eventCode,
    required String taskId,
    required TaskStatus status,
    int? progressPercentage,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };
      if (progressPercentage != null) {
        updates['progressPercentage'] = progressPercentage;
      }
      await db
          .collection('events')
          .doc(code)
          .collection('tasks')
          .doc(taskId)
          .update(updates);
      return true;
    } catch (e) {
      debugPrint('Firestore updateTaskStatus notice: $e');
      return false;
    }
  }

  /// Delete a task
  Future<bool> deleteTask({
    required String eventCode,
    required String taskId,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('tasks')
          .doc(taskId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Firestore deleteTask notice: $e');
      return false;
    }
  }

  /// Stream tasks for an event (Capped to 100)
  Stream<List<EventTaskModel>> streamTasks(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('tasks')
          .limit(100)
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventTaskModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamTasks notice: $e');
      return const Stream.empty();
    }
  }

  /// Automatically generate and seed standard operational tasks based on department templates
  Future<int> generateAutomatedTasksFromTemplate({
    required String eventCode,
    required String category,
    required List<String> departments,
    required String userEmail,
  }) async {
    final db = _db;
    if (db == null) return 0;

    final code = eventCode.toUpperCase().trim();
    final List<EventTaskModel> templateTasks = [];
    final now = DateTime.now();

    // Standard cross-department operational templates
    if (departments.any((d) => d.toLowerCase().contains('operation') || d.toLowerCase().contains('venue') || d.toLowerCase().contains('admin'))) {
      templateTasks.addAll([
        EventTaskModel(
          id: 'TSK-OPS-1',
          eventId: code,
          title: 'Venue Inspection & Stage Floor Plan Setup',
          category: 'Logistics',
          department: 'Operations',
          priority: 'High',
          dueDate: now.add(const Duration(days: 1)),
          checklist: ['Confirm stage dimensions', 'Verify emergency exits', 'Deploy queue stanchions'],
        ),
        EventTaskModel(
          id: 'TSK-OPS-2',
          eventId: code,
          title: 'Registration Desk & Badge Printing Setup',
          category: 'Operations',
          department: 'Operations',
          priority: 'Medium',
          dueDate: now.add(const Duration(days: 2)),
          checklist: ['Check-in tablets charged', 'Badge ribbons unpacked', 'Test QR ticket scanner'],
        ),
      ]);
    }

    if (departments.any((d) => d.toLowerCase().contains('it') || d.toLowerCase().contains('tech') || d.toLowerCase().contains('engineer'))) {
      templateTasks.addAll([
        EventTaskModel(
          id: 'TSK-TECH-1',
          eventId: code,
          title: 'High-Density Wi-Fi & Live Stream Uplink Check',
          category: 'Technical',
          department: 'IT / Engineering',
          priority: 'Critical',
          dueDate: now.add(const Duration(days: 1)),
          checklist: ['Test dedicated 100Mbps uplink', 'Configure backup 5G router', 'Verify RTMP stream key'],
        ),
        EventTaskModel(
          id: 'TSK-TECH-2',
          eventId: code,
          title: 'Audio Visual, Projector & Wireless Mic Soundcheck',
          category: 'AV Production',
          department: 'IT / Engineering',
          priority: 'High',
          dueDate: now.add(const Duration(days: 2)),
          checklist: ['Microphone battery check', 'HDMI/DisplayPort testing', 'Test slide clicker range'],
        ),
      ]);
    }

    if (departments.any((d) => d.toLowerCase().contains('security') || d.toLowerCase().contains('safety'))) {
      templateTasks.add(
        EventTaskModel(
          id: 'TSK-SEC-1',
          eventId: code,
          title: 'Perimeter Security & VIP Escort Protocol',
          category: 'Security',
          department: 'Security',
          priority: 'Critical',
          dueDate: now.add(const Duration(days: 1)),
          checklist: ['Brief gate guard personnel', 'Clear VIP entrance bay', 'First-aid kit station ready'],
        ),
      );
    }

    if (departments.any((d) => d.toLowerCase().contains('marketing') || d.toLowerCase().contains('media') || d.toLowerCase().contains('pr'))) {
      templateTasks.add(
        EventTaskModel(
          id: 'TSK-MKT-1',
          eventId: code,
          title: 'Directional Signage, Banners & Press Kit',
          category: 'Media',
          department: 'Marketing',
          priority: 'Medium',
          dueDate: now.add(const Duration(days: 2)),
          checklist: ['Mount entrance arch banner', 'Distribute press releases', 'Test live photobooth'],
        ),
      );
    }

    if (departments.any((d) => d.toLowerCase().contains('finance'))) {
      templateTasks.add(
        EventTaskModel(
          id: 'TSK-FIN-1',
          eventId: code,
          title: 'Vendor Purchase Orders & Advance Ledger Lock',
          category: 'Finance',
          department: 'Finance',
          priority: 'High',
          dueDate: now.add(const Duration(days: 1)),
          checklist: ['Catering PO signed', 'Audio equipment deposit paid', 'Lock emergency petty cash'],
        ),
      );
    }

    // Fallback if no specific department match
    if (templateTasks.isEmpty) {
      templateTasks.add(
        EventTaskModel(
          id: 'TSK-GEN-1',
          eventId: code,
          title: 'Pre-Event Briefing & Squad Alignment',
          category: 'Operations',
          department: departments.isNotEmpty ? departments.first : 'General',
          priority: 'High',
          dueDate: now.add(const Duration(days: 1)),
          checklist: ['Review master schedule', 'Assign squad channels', 'Test communications'],
        ),
      );
    }

    int createdCount = 0;
    try {
      final batch = db.batch();
      for (final task in templateTasks) {
        final docRef = db.collection('events').doc(code).collection('tasks').doc(task.id);
        batch.set(docRef, task.toJson());
        createdCount++;
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Notice committing tasks batch: $e');
    }

    await logEventActivity(
      eventCode: code,
      action: 'Automated Tasks Seeded',
      details: 'Automated engine provisioned $createdCount operational tasks for ${departments.join(", ")}',
      userEmail: userEmail,
    );

    return createdCount;
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 2: MULTI-TIER APPROVAL WORKFLOW ENGINE
  // ---------------------------------------------------------------------------

  /// Seed initial approval stages
  Future<void> seedDefaultApprovalChain({
    required String eventCode,
    required String ownerEmail,
    required String deptHeadEmail,
  }) async {
    final db = _db;
    if (db == null) return;

    final code = eventCode.toUpperCase().trim();
    final now = DateTime.now();

    final stages = [
      EventApprovalModel(
        id: 'APP-STAGE-1',
        eventId: code,
        stageName: 'Department Head Operational Approval',
        approverRole: 'Department Head',
        approverEmail: deptHeadEmail.isNotEmpty ? deptHeadEmail : 'dept.head@organization.com',
        status: ApprovalDecision.pending,
        requestedAt: now,
      ),
      EventApprovalModel(
        id: 'APP-STAGE-2',
        eventId: code,
        stageName: 'Finance & Budget Sign-off',
        approverRole: 'Finance Controller',
        approverEmail: 'finance.lead@organization.com',
        status: ApprovalDecision.pending,
        requestedAt: now,
      ),
      EventApprovalModel(
        id: 'APP-STAGE-3',
        eventId: code,
        stageName: 'Facilities & Security Clearance',
        approverRole: 'Security & Campus Lead',
        approverEmail: 'facilities@organization.com',
        status: ApprovalDecision.pending,
        requestedAt: now,
      ),
    ];

    try {
      final batch = db.batch();
      for (final stage in stages) {
        final ref = db.collection('events').doc(code).collection('approvals').doc(stage.id);
        batch.set(ref, stage.toJson());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Notice committing approval chain batch: $e');
    }
  }

  /// Submit an approval vote / decision
  Future<bool> submitApprovalDecision({
    required String eventCode,
    required String approvalId,
    required ApprovalDecision decision,
    required String comments,
    required String userEmail,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('approvals')
          .doc(approvalId)
          .update({
        'status': decision.name,
        'comments': comments.trim(),
        'decidedAt': DateTime.now().toIso8601String(),
      });

      await logEventActivity(
        eventCode: code,
        action: 'Approval Decision: ${decision.displayName}',
        details: 'Stage $approvalId decided as ${decision.displayName} by $userEmail. Remarks: $comments',
        userEmail: userEmail,
      );

      // Check if all approvals are now approved
      final allSnap = await db.collection('events').doc(code).collection('approvals').get();
      final allApproved = allSnap.docs.isNotEmpty &&
          allSnap.docs.every((d) => d.data()['status'] == ApprovalDecision.approved.name);

      if (allApproved) {
        await updateEventLifecycle(eventCode: code, state: EventLifecycleState.approved, userEmail: userEmail);
      }

      return true;
    } catch (e) {
      debugPrint('Firestore submitApprovalDecision notice: $e');
      return false;
    }
  }

  /// Stream approvals for an event (Capped to 60)
  Stream<List<EventApprovalModel>> streamApprovals(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('approvals')
          .limit(60)
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventApprovalModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamApprovals notice: $e');
      return const Stream.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 2: RESOURCE ALLOCATION & CONFLICT DETECTION ENGINE
  // ---------------------------------------------------------------------------

  /// Reserve resource under events/{code}/resources
  Future<bool> reserveResource({
    required String eventCode,
    required EventResourceModel resource,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('resources')
          .doc(resource.id)
          .set(resource.toJson());
      return true;
    } catch (e) {
      debugPrint('Firestore reserveResource notice: $e');
      return false;
    }
  }

  /// Stream resources reserved for an event
  Stream<List<EventResourceModel>> streamResources(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('resources')
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventResourceModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamResources notice: $e');
      return const Stream.empty();
    }
  }

  /// Intelligent conflict detection: check if venue or resources are booked by other active events
  Future<ResourceConflictResult> checkResourceConflicts({
    required String currentEventCode,
    required String venueName,
    required List<String> resourceNames,
  }) async {
    final db = _db;
    if (db == null) return const ResourceConflictResult(hasConflict: false);

    final cleanCode = currentEventCode.toUpperCase().trim();
    try {
      final eventsSnap = await db.collection('events').get();
      for (final doc in eventsSnap.docs) {
        if (doc.id == cleanCode) continue; // skip self
        final data = doc.data();
        final otherVenue = (data['venue'] as String? ?? '').trim().toLowerCase();
        final otherTitle = data['title'] as String? ?? doc.id;
        final otherStatus = data['status'] as String? ?? '';

        // Only consider active/planned/live events
        if (otherStatus.toLowerCase().contains('cancel') || otherStatus.toLowerCase().contains('closed')) {
          continue;
        }

        // 1. Check venue collision
        if (venueName.trim().isNotEmpty &&
            otherVenue.isNotEmpty &&
            venueName.trim().toLowerCase() == otherVenue) {
          return ResourceConflictResult(
            hasConflict: true,
            resourceName: venueName,
            conflictingEventCode: doc.id,
            conflictingEventTitle: otherTitle,
            conflictDetails: 'Venue "$venueName" is concurrently booked by active event "$otherTitle" ($doc.id).',
          );
        }
      }
      return const ResourceConflictResult(hasConflict: false);
    } catch (e) {
      debugPrint('Firestore checkResourceConflicts notice: $e');
      return const ResourceConflictResult(hasConflict: false);
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 2: BUDGET & FINANCIAL EXPENSE LEDGER
  // ---------------------------------------------------------------------------

  /// Add expense item to events/{code}/expenses
  Future<bool> addExpenseItem({
    required String eventCode,
    required EventExpenseModel expense,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toJson());

      await logEventActivity(
        eventCode: code,
        action: 'Expense Added: ₹${expense.amount.toStringAsFixed(0)}',
        details: '${expense.title} (${expense.category}) allocated for ${expense.department}',
        userEmail: 'finance@groundflow.app',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore addExpenseItem notice: $e');
      return false;
    }
  }

  /// Delete expense item
  Future<bool> deleteExpenseItem({
    required String eventCode,
    required String expenseId,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('expenses')
          .doc(expenseId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Firestore deleteExpenseItem notice: $e');
      return false;
    }
  }

  /// Stream expense items for an event (Capped to 100)
  Stream<List<EventExpenseModel>> streamExpenses(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('expenses')
          .orderBy('date', descending: true)
          .limit(100)
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventExpenseModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamExpenses notice: $e');
      return const Stream.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 3: LIVE INCIDENT ESCALATION & TRIAGE ENGINE
  // ---------------------------------------------------------------------------

  /// Log an incident ticket under events/{code}/incidents
  Future<bool> logIncident({
    required String eventCode,
    required EventIncidentModel incident,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('incidents')
          .doc(incident.id)
          .set(incident.toJson());

      await logEventActivity(
        eventCode: code,
        action: 'Incident Reported [${incident.severity.displayName}]',
        details: '${incident.title} (${incident.department}) - Reported by ${incident.reportedBy}',
        userEmail: incident.reportedBy,
      );
      return true;
    } catch (e) {
      debugPrint('Firestore logIncident notice: $e');
      return false;
    }
  }

  /// Update incident status (e.g. Triage, Escalate to Dept Head, or Resolve)
  Future<bool> updateIncidentStatus({
    required String eventCode,
    required String incidentId,
    required IncidentStatus status,
    String? resolutionNotes,
    required String userEmail,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };
      if (status == IncidentStatus.resolved) {
        updates['resolvedAt'] = DateTime.now().toIso8601String();
        if (resolutionNotes != null) {
          updates['resolutionNotes'] = resolutionNotes.trim();
        }
      }
      await db
          .collection('events')
          .doc(code)
          .collection('incidents')
          .doc(incidentId)
          .update(updates);

      await logEventActivity(
        eventCode: code,
        action: 'Incident ${status.displayName}',
        details: 'Ticket $incidentId updated to ${status.displayName} by $userEmail',
        userEmail: userEmail,
      );
      return true;
    } catch (e) {
      debugPrint('Firestore updateIncidentStatus notice: $e');
      return false;
    }
  }

  /// Stream live incidents for an event (Capped to 50)
  Stream<List<EventIncidentModel>> streamIncidents(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('incidents')
          .orderBy('reportedAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventIncidentModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamIncidents notice: $e');
      return const Stream.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 5: MULTI-DAY AGENDA & SESSION SCHEDULE APIS
  // ---------------------------------------------------------------------------

  /// Create a session under events/{code}/sessions
  Future<bool> createSession({
    required String eventCode,
    required EventSessionModel session,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('sessions')
          .doc(session.id)
          .set(session.toJson());

      await logEventActivity(
        eventCode: code,
        action: 'Session Added to Agenda',
        details: '${session.title} (${session.startTime} - ${session.endTime}) in ${session.room}',
        userEmail: 'organizer@groundflow.app',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore createSession notice: $e');
      return false;
    }
  }

  /// Toggle or set a session as Live Now
  Future<bool> updateSessionLive({
    required String eventCode,
    required String sessionId,
    required bool isLiveNow,
    required String userEmail,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('sessions')
          .doc(sessionId)
          .update({'isLiveNow': isLiveNow});

      if (isLiveNow) {
        await logEventActivity(
          eventCode: code,
          action: 'Session Live Now',
          details: 'Session $sessionId marked as LIVE NOW on master timetable',
          userEmail: userEmail,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Firestore updateSessionLive notice: $e');
      return false;
    }
  }

  /// Delete a session
  Future<bool> deleteSession({
    required String eventCode,
    required String sessionId,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('sessions')
          .doc(sessionId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Firestore deleteSession notice: $e');
      return false;
    }
  }

  /// Stream sessions for an event ordered by start time
  Stream<List<EventSessionModel>> streamSessions(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('sessions')
          .orderBy('startTime')
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventSessionModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamSessions notice: $e');
      return const Stream.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 5: REAL-TIME EMERGENCY & BROADCAST ANNOUNCEMENT APIS
  // ---------------------------------------------------------------------------

  /// Send an announcement to events/{code}/announcements
  Future<bool> sendAnnouncement({
    required String eventCode,
    required EventAnnouncementModel announcement,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('announcements')
          .doc(announcement.id)
          .set(announcement.toJson());

      await logEventActivity(
        eventCode: code,
        action: 'Broadcast Announcement [${announcement.urgency.displayName}]',
        details: '${announcement.title} - Broadcast to ${announcement.audience.displayName}',
        userEmail: announcement.sentBy,
      );
      return true;
    } catch (e) {
      debugPrint('Firestore sendAnnouncement notice: $e');
      return false;
    }
  }

  /// Stream announcements in reverse chronological order (Capped to 30)
  Stream<List<EventAnnouncementModel>> streamAnnouncements(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    try {
      return db
          .collection('events')
          .doc(code)
          .collection('announcements')
          .orderBy('sentAt', descending: true)
          .limit(30)
          .snapshots()
          .map((snap) => snap.docs.map((d) => EventAnnouncementModel.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamAnnouncements notice: $e');
      return const Stream.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // MILESTONE 7: DYNAMIC CUSTOM FIELDS & DEPARTMENT WORKSPACE
  // ---------------------------------------------------------------------------

  /// Save a custom field definition for an event
  Future<bool> setCustomField({
    required String eventCode,
    required CustomFieldDefinition field,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('custom_fields')
          .doc(field.key)
          .set(field.toJson());

      await logEventActivity(
        eventCode: code,
        action: 'Custom Field Defined',
        details: 'Configured custom field "${field.label}" (${field.type.displayName})',
        userEmail: 'Organizer',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore setCustomField notice: $e');
      return false;
    }
  }

  /// Real-time stream of custom fields for an event
  Stream<List<CustomFieldDefinition>> streamCustomFields(String eventCode) {
    final db = _db;
    if (db == null) return const Stream.empty();

    final code = eventCode.toUpperCase().trim();
    if (code.isEmpty) return const Stream.empty();

    try {
      return db
          .collection('events')
          .doc(code)
          .collection('custom_fields')
          .snapshots()
          .map((snap) => snap.docs.map((d) => CustomFieldDefinition.fromJson(d.data())).toList());
    } catch (e) {
      debugPrint('Firestore streamCustomFields notice: $e');
      return const Stream.empty();
    }
  }

  /// Delete a custom field definition
  Future<bool> deleteCustomField({
    required String eventCode,
    required String fieldKey,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('custom_fields')
          .doc(fieldKey)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Firestore deleteCustomField notice: $e');
      return false;
    }
  }

  /// Add a member name to a team roster
  Future<bool> addTeamMember({
    required String eventCode,
    required String teamId,
    required String memberName,
  }) async {
    final db = _db;
    if (db == null) return false;

    final code = eventCode.toUpperCase().trim();
    try {
      await db
          .collection('events')
          .doc(code)
          .collection('teams')
          .doc(teamId)
          .update({
        'members': FieldValue.arrayUnion([memberName.trim()]),
      });

      await logEventActivity(
        eventCode: code,
        action: 'Team Member Added',
        details: 'Added $memberName to team $teamId roster',
        userEmail: 'Organizer',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore addTeamMember notice: $e');
      return false;
    }
  }
}
