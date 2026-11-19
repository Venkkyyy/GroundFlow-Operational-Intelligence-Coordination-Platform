import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Keys
// ---------------------------------------------------------------------------

class _Keys {
  static const authToken = 'gf_auth_token';
  static const refreshToken = 'gf_refresh_token';
  static const userProfile = 'gf_user_profile';
  static const tasks = 'gf_tasks_cache';
  static const messages = 'gf_messages_cache';
  static const offlineQueue = 'gf_offline_queue';
  static const lastSyncAt = 'gf_last_sync_at';
}

// ---------------------------------------------------------------------------
// LocalStorage
// ---------------------------------------------------------------------------

/// Persistent local storage backed by [SharedPreferences].
///
/// Stores auth tokens, cached JSON collections (tasks, messages), and an
/// offline request queue — all as JSON-encoded strings.
///
/// Obtain a ready instance via [LocalStorage.init()]:
/// ```dart
/// final storage = await LocalStorage.init();
/// ```
class LocalStorage {
  LocalStorage._(this._prefs);

  final SharedPreferences _prefs;

  /// Factory that initialises [SharedPreferences] and returns a ready instance.
  static Future<LocalStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage._(prefs);
  }

  // -------------------------------------------------------------------------
  // Auth
  // -------------------------------------------------------------------------

  Future<void> saveAuthToken(String token) =>
      _prefs.setString(_Keys.authToken, token);

  String? getAuthToken() => _prefs.getString(_Keys.authToken);

  Future<void> saveRefreshToken(String token) =>
      _prefs.setString(_Keys.refreshToken, token);

  String? getRefreshToken() => _prefs.getString(_Keys.refreshToken);

  Future<void> clearAuth() async {
    await _prefs.remove(_Keys.authToken);
    await _prefs.remove(_Keys.refreshToken);
  }

  // -------------------------------------------------------------------------
  // User profile
  // -------------------------------------------------------------------------

  Future<void> saveUserProfile(Map<String, dynamic> profile) =>
      _prefs.setString(_Keys.userProfile, jsonEncode(profile));

  Map<String, dynamic>? getUserProfile() {
    final raw = _prefs.getString(_Keys.userProfile);
    if (raw == null) return null;
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> clearUserProfile() => _prefs.remove(_Keys.userProfile);

  // -------------------------------------------------------------------------
  // Tasks cache
  // -------------------------------------------------------------------------

  /// Persist a list of task JSON maps.
  Future<void> cacheTasks(List<Map<String, dynamic>> tasks) =>
      _prefs.setString(_Keys.tasks, jsonEncode(tasks));

  /// Retrieve the cached task list (empty list if nothing cached).
  List<Map<String, dynamic>> getCachedTasks() {
    final raw = _prefs.getString(_Keys.tasks);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> clearCachedTasks() => _prefs.remove(_Keys.tasks);

  // -------------------------------------------------------------------------
  // Messages cache
  // -------------------------------------------------------------------------

  Future<void> cacheMessages(List<Map<String, dynamic>> messages) =>
      _prefs.setString(_Keys.messages, jsonEncode(messages));

  List<Map<String, dynamic>> getCachedMessages() {
    final raw = _prefs.getString(_Keys.messages);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> clearCachedMessages() => _prefs.remove(_Keys.messages);

  // -------------------------------------------------------------------------
  // Offline queue
  // -------------------------------------------------------------------------

  /// Append one entry to the persistent offline request queue.
  Future<void> addToOfflineQueue(Map<String, dynamic> entry) async {
    final queue = getOfflineQueue();
    queue.add(entry);
    await _prefs.setString(_Keys.offlineQueue, jsonEncode(queue));
  }

  /// Retrieve all queued offline request entries.
  List<Map<String, dynamic>> getOfflineQueue() {
    final raw = _prefs.getString(_Keys.offlineQueue);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Remove all entries from the offline queue (call after successful replay).
  Future<void> clearOfflineQueue() => _prefs.remove(_Keys.offlineQueue);

  // -------------------------------------------------------------------------
  // Sync metadata
  // -------------------------------------------------------------------------

  Future<void> saveLastSyncAt(DateTime time) =>
      _prefs.setString(_Keys.lastSyncAt, time.toIso8601String());

  DateTime? getLastSyncAt() {
    final raw = _prefs.getString(_Keys.lastSyncAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // -------------------------------------------------------------------------
  // Generic helpers
  // -------------------------------------------------------------------------

  /// Store any JSON-encodable value under a custom [key].
  Future<void> set(String key, dynamic value) =>
      _prefs.setString(key, jsonEncode(value));

  /// Retrieve a previously stored value by [key].
  dynamic get(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<void> remove(String key) => _prefs.remove(key);

  /// Wipe all GroundFlow keys from storage. ⚠️ Use with caution.
  Future<void> clearAll() async {
    for (final key in [
      _Keys.authToken,
      _Keys.refreshToken,
      _Keys.userProfile,
      _Keys.tasks,
      _Keys.messages,
      _Keys.offlineQueue,
      _Keys.lastSyncAt,
    ]) {
      await _prefs.remove(key);
    }
  }
}
