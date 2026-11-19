import 'dart:async';
import 'package:flutter/foundation.dart';

/// Lightweight in-memory cached entry with TTL
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required Duration ttl})
      : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Firebase Rate Limiter & Cloud Read Optimizer
///
/// Features:
/// 1. In-memory TTL caching for repeated reads (getEvent, getUserProfile, etc.)
/// 2. Request deduplication (single-flight) to prevent concurrent identical reads
/// 3. Debounced notification scheduling to eliminate UI rebuild storms
/// 4. Stream re-binding cooldown to prevent redundant Firestore collection downloads
class FirebaseRateLimiter {
  static final FirebaseRateLimiter _instance = FirebaseRateLimiter._internal();
  factory FirebaseRateLimiter() => _instance;
  FirebaseRateLimiter._internal();

  final Map<String, _CacheEntry<dynamic>> _readCache = {};
  final Map<String, Future<dynamic>> _inFlightRequests = {};
  final Map<String, DateTime> _streamBindCooldowns = {};

  // Read Statistics
  int _readsSavedByCache = 0;
  int _readsSavedByDeduplication = 0;
  int _totalCloudReads = 0;

  int get readsSavedByCache => _readsSavedByCache;
  int get readsSavedByDeduplication => _readsSavedByDeduplication;
  int get totalCloudReads => _totalCloudReads;

  /// Execute a cloud read with single-flight deduplication and TTL caching.
  /// If the same read key is requested while in-flight or within [ttl], the cached/ongoing
  /// result is returned immediately without hitting Firestore network quota.
  Future<T?> executeCachedRead<T>({
    required String cacheKey,
    required Future<T?> Function() fetcher,
    Duration ttl = const Duration(seconds: 30),
    bool bypassCache = false,
  }) async {
    // 1. Check in-memory cache
    if (!bypassCache && _readCache.containsKey(cacheKey)) {
      final entry = _readCache[cacheKey]!;
      if (!entry.isExpired) {
        _readsSavedByCache++;
        return entry.data as T?;
      } else {
        _readCache.remove(cacheKey);
      }
    }

    // 2. Check in-flight requests (request deduplication)
    if (_inFlightRequests.containsKey(cacheKey)) {
      _readsSavedByDeduplication++;
      final ongoing = _inFlightRequests[cacheKey]!;
      return await ongoing as T?;
    }

    // 3. Perform fresh read
    final future = fetcher();
    _inFlightRequests[cacheKey] = future;

    try {
      _totalCloudReads++;
      final result = await future;
      if (result != null) {
        _readCache[cacheKey] = _CacheEntry(data: result, ttl: ttl);
      }
      return result;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  /// Invalidate cache for a specific key or matching prefix
  void invalidateCache(String keyOrPrefix) {
    _readCache.removeWhere((key, _) => key.startsWith(keyOrPrefix));
  }

  /// Check if a subcollection stream re-bind is permitted under cooldown.
  /// Prevents spamming Firestore with cancel/re-subscribe calls.
  bool shouldBindStreams(String eventCode, {Duration cooldown = const Duration(seconds: 4)}) {
    final clean = eventCode.trim().toUpperCase();
    if (clean.isEmpty) return false;

    final now = DateTime.now();
    final lastTime = _streamBindCooldowns[clean];
    if (lastTime != null && now.difference(lastTime) < cooldown) {
      debugPrint('⚡ [RateLimiter] Skipping stream re-bind for $clean (cooldown active: ${now.difference(lastTime).inMilliseconds}ms ago)');
      return false;
    }

    _streamBindCooldowns[clean] = now;
    return true;
  }

  /// Clear all cached data
  void clearAll() {
    _readCache.clear();
    _inFlightRequests.clear();
    _streamBindCooldowns.clear();
  }
}
