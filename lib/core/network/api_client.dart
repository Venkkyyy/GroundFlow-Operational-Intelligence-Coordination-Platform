import 'dart:io';
import 'package:dio/dio.dart';

// ---------------------------------------------------------------------------
// Exception types
// ---------------------------------------------------------------------------

/// Strongly-typed API exception surface for callers.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  final String message;
  final int? statusCode;
  final dynamic data;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ---------------------------------------------------------------------------
// Interceptors
// ---------------------------------------------------------------------------

/// Attaches the Bearer token from [_tokenProvider] to every outbound request.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenProvider);

  final String? Function() _tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Converts [DioException] into friendlier [ApiException]s.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final msg = _extractMessage(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException(message: msg, statusCode: status, data: err.response?.data),
        type: err.type,
        response: err.response,
      ),
    );
  }

  String _extractMessage(DioException err) {
    try {
      final data = err.response?.data;
      if (data is Map && data.containsKey('detail')) return data['detail'].toString();
      if (data is Map && data.containsKey('message')) return data['message'].toString();
    } catch (_) {}
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your network.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Are you online?';
      default:
        return err.message ?? 'An unexpected error occurred.';
    }
  }
}

/// Lightweight console logger for debug builds.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] → ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ← ${response.statusCode} ${response.requestOptions.uri}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ✖ ${err.requestOptions.uri} — ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

// ---------------------------------------------------------------------------
// Offline queue entry
// ---------------------------------------------------------------------------

/// A request that failed while offline and should be replayed on reconnect.
class OfflineQueueEntry {
  const OfflineQueueEntry({
    required this.method,
    required this.path,
    this.data,
    this.queryParameters,
    this.headers,
  });

  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headers;

  Map<String, dynamic> toJson() => {
        'method': method,
        'path': path,
        'data': data,
        'queryParameters': queryParameters,
        'headers': headers,
      };

  factory OfflineQueueEntry.fromJson(Map<String, dynamic> json) =>
      OfflineQueueEntry(
        method: json['method'] as String,
        path: json['path'] as String,
        data: (json['data'] as Map?)?.cast<String, dynamic>(),
        queryParameters:
            (json['queryParameters'] as Map?)?.cast<String, dynamic>(),
        headers: (json['headers'] as Map?)?.cast<String, String>(),
      );
}

// ---------------------------------------------------------------------------
// ApiClient
// ---------------------------------------------------------------------------

/// Centralised Dio-based HTTP client for GroundFlow.
///
/// Usage:
/// ```dart
/// final client = ApiClient(tokenProvider: () => myStorage.getAuthToken());
/// final data = await client.get('/events');
/// ```
class ApiClient {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  late final Dio _dio;

  /// Callback that returns the current auth token (or null when unauthenticated).
  final String? Function() tokenProvider;

  /// Called when the server returns 401 so the app can navigate to login.
  final Future<bool> Function()? onTokenRefresh;

  /// Callback to persist a request that fails while offline.
  final Future<void> Function(OfflineQueueEntry entry)? onQueueOfflineRequest;

  ApiClient({
    required this.tokenProvider,
    this.onTokenRefresh,
    this.onQueueOfflineRequest,
    String? overrideBaseUrl,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: overrideBaseUrl ?? baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(tokenProvider),
      _buildRefreshInterceptor(),
      _ErrorInterceptor(),
      _LoggingInterceptor(),
    ]);
  }

  // -------------------------------------------------------------------------
  // Token refresh interceptor
  // -------------------------------------------------------------------------

  /// When a 401 is received, attempts to refresh the token and retries once.
  QueuedInterceptorsWrapper _buildRefreshInterceptor() {
    return QueuedInterceptorsWrapper(
      onError: (err, handler) async {
        if (err.response?.statusCode == 401 && onTokenRefresh != null) {
          final refreshed = await onTokenRefresh!();
          if (refreshed) {
            // Retry the original request with the new token.
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${tokenProvider()}';
            try {
              final response = await _dio.fetch(opts);
              handler.resolve(response);
              return;
            } catch (_) {}
          }
        }
        handler.next(err);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Generic HTTP methods
  // -------------------------------------------------------------------------

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return res.data as T;
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueOnOffline = false,
  }) async {
    try {
      final res = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return res.data as T;
    } on DioException catch (e) {
      if (_isOfflineError(e) && queueOnOffline && onQueueOfflineRequest != null) {
        await onQueueOfflineRequest!(
          OfflineQueueEntry(
            method: 'POST',
            path: path,
            data: data is Map ? data.cast<String, dynamic>() : null,
            queryParameters: queryParameters,
          ),
        );
        rethrow;
      }
      rethrow;
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueOnOffline = false,
  }) async {
    try {
      final res = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return res.data as T;
    } on DioException catch (e) {
      if (_isOfflineError(e) && queueOnOffline && onQueueOfflineRequest != null) {
        await onQueueOfflineRequest!(
          OfflineQueueEntry(
            method: 'PUT',
            path: path,
            data: data is Map ? data.cast<String, dynamic>() : null,
            queryParameters: queryParameters,
          ),
        );
        rethrow;
      }
      rethrow;
    }
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return res.data as T;
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueOnOffline = false,
  }) async {
    try {
      final res = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return res.data as T;
    } on DioException catch (e) {
      if (_isOfflineError(e) && queueOnOffline && onQueueOfflineRequest != null) {
        await onQueueOfflineRequest!(
          OfflineQueueEntry(
            method: 'PATCH',
            path: path,
            data: data is Map ? data.cast<String, dynamic>() : null,
            queryParameters: queryParameters,
          ),
        );
        rethrow;
      }
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Offline helpers
  // -------------------------------------------------------------------------

  bool _isOfflineError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout;

  /// Replays all queued offline requests in order. Supply the queue entries
  /// and a callback to clear them on success.
  Future<void> replayOfflineQueue(
    List<OfflineQueueEntry> queue, {
    required Future<void> Function() onSuccess,
  }) async {
    for (final entry in queue) {
      try {
        switch (entry.method) {
          case 'POST':
            await post(entry.path, data: entry.data, queryParameters: entry.queryParameters);
            break;
          case 'PUT':
            await put(entry.path, data: entry.data, queryParameters: entry.queryParameters);
            break;
          case 'PATCH':
            await patch(entry.path, data: entry.data, queryParameters: entry.queryParameters);
            break;
          case 'DELETE':
            await delete(entry.path, data: entry.data, queryParameters: entry.queryParameters);
            break;
        }
      } catch (e) {
        // Stop replaying on first failure — stay offline.
        return;
      }
    }
    await onSuccess();
  }

  void close() => _dio.close(force: true);
}
