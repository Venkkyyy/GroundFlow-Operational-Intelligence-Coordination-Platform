import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

// ---------------------------------------------------------------------------
// Event types
// ---------------------------------------------------------------------------

/// Every event the server can push over the WebSocket connection.
enum WebSocketEventType {
  memberStatusUpdate,
  newMessage,
  attendanceRound,
  issueCreated,
  pipelineUpdate,
  assignmentChange,
  connectionAck,
  error,
  unknown,
}

/// A strongly-typed event received from the WebSocket.
class WebSocketEvent {
  const WebSocketEvent({
    required this.type,
    required this.payload,
    this.version,
  });

  final WebSocketEventType type;
  final Map<String, dynamic> payload;

  /// Server-side monotonic version number for ordering / deduplication.
  final int? version;

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    final type = _parseType(typeStr);
    return WebSocketEvent(
      type: type,
      payload: (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
      version: json['version'] as int?,
    );
  }

  static WebSocketEventType _parseType(String raw) {
    switch (raw) {
      case 'member_status_update':
        return WebSocketEventType.memberStatusUpdate;
      case 'new_message':
        return WebSocketEventType.newMessage;
      case 'attendance_round':
        return WebSocketEventType.attendanceRound;
      case 'issue_created':
        return WebSocketEventType.issueCreated;
      case 'pipeline_update':
        return WebSocketEventType.pipelineUpdate;
      case 'assignment_change':
        return WebSocketEventType.assignmentChange;
      case 'connection_ack':
        return WebSocketEventType.connectionAck;
      case 'error':
        return WebSocketEventType.error;
      default:
        return WebSocketEventType.unknown;
    }
  }
}

// ---------------------------------------------------------------------------
// Connection state
// ---------------------------------------------------------------------------

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

// ---------------------------------------------------------------------------
// WebSocketClient
// ---------------------------------------------------------------------------

/// Realtime WebSocket client for GroundFlow events.
///
/// Connects to `ws://localhost:8000/ws/{eventId}`, auto-reconnects with
/// exponential back-off, and replays missed events via `last_seen_version`.
///
/// Usage:
/// ```dart
/// final ws = WebSocketClient(eventId: 'evt_123', tokenProvider: () => token);
/// ws.events.listen((event) { ... });
/// ws.connect();
/// // On dispose:
/// ws.dispose();
/// ```
class WebSocketClient {
  static const String _baseWsUrl = 'ws://localhost:8000/ws';

  WebSocketClient({
    required this.eventId,
    required this.tokenProvider,
    this.onConnectionStateChange,
  });

  final String eventId;
  final String? Function() tokenProvider;
  final void Function(WebSocketConnectionState)? onConnectionStateChange;

  // -------------------------------------------------------------------------
  // Public streams
  // -------------------------------------------------------------------------

  final _eventController = StreamController<WebSocketEvent>.broadcast();
  Stream<WebSocketEvent> get events => _eventController.stream;

  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();
  Stream<WebSocketConnectionState> get connectionState =>
      _stateController.stream;

  // -------------------------------------------------------------------------
  // Internal state
  // -------------------------------------------------------------------------

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;

  int _lastSeenVersion = 0;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;

  static const int _maxReconnectAttempts = 10;
  static const Duration _baseBackoff = Duration(seconds: 2);
  static const Duration _maxBackoff = Duration(seconds: 60);

  // -------------------------------------------------------------------------
  // Connection lifecycle
  // -------------------------------------------------------------------------

  /// Establish (or re-establish) the WebSocket connection.
  void connect() {
    if (_disposed) return;
    _setState(WebSocketConnectionState.connecting);
    _doConnect();
  }

  void _doConnect() {
    final token = tokenProvider();
    final uri = Uri.parse(
      '$_baseWsUrl/$eventId'
      '?last_seen_version=$_lastSeenVersion'
      '${token != null ? '&token=$token' : ''}',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _setState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    if (_disposed) return;
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = WebSocketEvent.fromJson(json);

      // Track version for replay on next reconnect.
      if (event.version != null && event.version! > _lastSeenVersion) {
        _lastSeenVersion = event.version!;
      }

      _eventController.add(event);
    } catch (e) {
      // Malformed message — log and continue.
      assert(() {
        // ignore: avoid_print
        print('[WS] Failed to parse message: $e');
        return true;
      }());
    }
  }

  void _onError(Object error) {
    assert(() {
      // ignore: avoid_print
      print('[WS] Error: $error');
      return true;
    }());
    _scheduleReconnect();
  }

  void _onDone() {
    if (_disposed) return;
    assert(() {
      // ignore: avoid_print
      print('[WS] Connection closed. Reconnecting…');
      return true;
    }());
    _scheduleReconnect();
  }

  // -------------------------------------------------------------------------
  // Reconnect logic (exponential back-off with jitter)
  // -------------------------------------------------------------------------

  void _scheduleReconnect() {
    if (_disposed) return;
    _subscription?.cancel();
    _subscription = null;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setState(WebSocketConnectionState.disconnected);
      return;
    }

    _setState(WebSocketConnectionState.reconnecting);
    _reconnectAttempts++;

    final exp = math.pow(2, _reconnectAttempts).toInt();
    final baseSec = (_baseBackoff.inSeconds * exp).clamp(
      _baseBackoff.inSeconds,
      _maxBackoff.inSeconds,
    );
    final jitter = math.Random().nextInt((baseSec * 0.3).ceil() + 1);
    final delay = Duration(seconds: baseSec + jitter);

    assert(() {
      // ignore: avoid_print
      print('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
      return true;
    }());

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _doConnect);
  }

  // -------------------------------------------------------------------------
  // Sending messages
  // -------------------------------------------------------------------------

  /// Send an arbitrary JSON payload to the server.
  void send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  // -------------------------------------------------------------------------
  // State helpers
  // -------------------------------------------------------------------------

  void _setState(WebSocketConnectionState next) {
    _state = next;
    _stateController.add(next);
    onConnectionStateChange?.call(next);
  }

  WebSocketConnectionState get currentState => _state;

  // -------------------------------------------------------------------------
  // Dispose
  // -------------------------------------------------------------------------

  /// Close the connection and release all resources.
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(ws_status.goingAway);
    _eventController.close();
    _stateController.close();
  }
}
