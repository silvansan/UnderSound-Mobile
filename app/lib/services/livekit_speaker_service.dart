import 'dart:async';
import 'dart:developer' as developer;

import 'package:audio_session/audio_session.dart';
import 'package:livekit_client/livekit_client.dart';

import '../models/listener_link.dart';
import '../models/public_channel.dart';
import 'ablaut_api_client.dart';
import 'microphone_permission.dart';
import 'stream_connection_service.dart';

class LiveKitSpeakerSnapshot {
  const LiveKitSpeakerSnapshot({
    required this.phase,
    required this.connected,
    required this.publishing,
    this.message,
    this.lastErrorDetail,
    this.muted = false,
  });

  final StreamConnectionPhase phase;
  final bool connected;
  final bool publishing;
  final String? message;
  final String? lastErrorDetail;
  final bool muted;

  LiveKitSpeakerSnapshot copyWith({
    StreamConnectionPhase? phase,
    bool? connected,
    bool? publishing,
    String? message,
    String? lastErrorDetail,
    bool clearErrorDetail = false,
    bool clearMessage = false,
    bool? muted,
  }) {
    return LiveKitSpeakerSnapshot(
      phase: phase ?? this.phase,
      connected: connected ?? this.connected,
      publishing: publishing ?? this.publishing,
      message: clearMessage ? null : (message ?? this.message),
      lastErrorDetail:
          clearErrorDetail ? null : (lastErrorDetail ?? this.lastErrorDetail),
      muted: muted ?? this.muted,
    );
  }
}

class LiveKitSpeakerService {
  LiveKitSpeakerService({AblautApiClient api = const AblautApiClient()})
      : _api = api;

  final AblautApiClient _api;

  StreamController<LiveKitSpeakerSnapshot>? _snapshotController;
  LiveKitSpeakerSnapshot _snapshot = const LiveKitSpeakerSnapshot(
    phase: StreamConnectionPhase.idle,
    connected: false,
    publishing: false,
    message: 'Tap publish to start speaking.',
  );

  Room? _room;
  CancelListenFunc? _cancelListen;
  bool _intentToDisconnect = false;
  bool _muted = false;
  Completer<void>? _connectCompleter;

  Stream<LiveKitSpeakerSnapshot> get snapshots {
    final controller = _snapshotController ??=
        StreamController<LiveKitSpeakerSnapshot>.broadcast();
    return controller.stream;
  }

  LiveKitSpeakerSnapshot get snapshot => _snapshot;

  Future<void> connect({
    required ListenerLink link,
    required PublicChannelContext channelContext,
    String? sessionCookieHeader,
  }) async {
    if (_connectCompleter != null) {
      await _connectCompleter!.future;
    }

    await disconnect();

    final completer = Completer<void>();
    _connectCompleter = completer;

    try {
      _emit(
        _snapshot.copyWith(
          phase: StreamConnectionPhase.connecting,
          connected: false,
          publishing: false,
          message: 'Checking microphone permission...',
          clearErrorDetail: true,
        ),
      );

      await ensureMicrophonePermission();

      _emit(
        _snapshot.copyWith(
          phase: StreamConnectionPhase.connecting,
          connected: false,
          publishing: false,
          message: 'Connecting speaker session...',
          clearErrorDetail: true,
        ),
      );

      await _ensureAudioSession();
      _muted = false;
      final cred = await _api.fetchSpeakerToken(
        link: link,
        sessionCookieHeader: sessionCookieHeader,
      );
      await _openRoom(link, channelContext, cred.url, cred.token);
    } on MicrophonePermissionDeniedException catch (error) {
      _emitFailed(error.message);
      rethrow;
    } on ApiException catch (error) {
      _emitFailed(error.message);
      rethrow;
    } catch (error, stack) {
      developer.log(
        'Speaker LiveKit connection failed.',
        name: 'ablaut.Speaker',
        error: error,
        stackTrace: stack,
      );
      _emitFailed(error.toString());
      rethrow;
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _connectCompleter = null;
    }
  }

  Future<void> disconnect({String? message}) async {
    _intentToDisconnect = true;
    try {
      await _shutdownRoomOnly();
      _snapshot = LiveKitSpeakerSnapshot(
        phase: StreamConnectionPhase.idle,
        connected: false,
        publishing: false,
        message: message ?? 'Tap publish to start speaking.',
        muted: _muted,
      );
      _broadcast();
    } finally {
      _intentToDisconnect = false;
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _snapshotController?.close();
    _snapshotController = null;
  }

  Future<void> setMuted(bool muted) async {
    if (_muted == muted) {
      return;
    }
    _muted = muted;
    await _applyLocalMuteState();
    _emit(
      _snapshot.copyWith(
        muted: muted,
        message: muted ? 'Microphone muted' : 'Publishing live audio',
      ),
    );
  }

  Future<void> toggleMuted() => setMuted(!_muted);

  Future<void> _openRoom(
    ListenerLink link,
    PublicChannelContext ctx,
    String url,
    String token,
  ) async {
    final room = Room();
    _room = room;
    await room.prepareConnection(url, token);

    final listener = room.createListener();
    _cancelListen = listener.listen(_handleLiveKitRoomEvent);

    await room.connect(
      url,
      token,
      connectOptions: const ConnectOptions(autoSubscribe: false),
      fastConnectOptions: FastConnectOptions(
        microphone: const TrackOption(enabled: true),
        camera: const TrackOption(enabled: false),
      ),
    );

    await room.localParticipant?.setMicrophoneEnabled(true);
    await _applyLocalMuteState();

    final roomLabel = '${ctx.event.name} · ${ctx.channel.name}';
    final hostSuffix =
        link.serverUrl.hasAuthority ? ' · ${link.serverUrl.host}' : '';

    _emit(
      LiveKitSpeakerSnapshot(
        phase: StreamConnectionPhase.connected,
        connected: true,
        publishing: true,
        message: 'Publishing live audio — $roomLabel$hostSuffix',
        muted: _muted,
      ),
    );
  }

  Future<void> _ensureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth,
      avAudioSessionMode: AVAudioSessionMode.voiceChat,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
  }

  Future<void> _applyLocalMuteState() async {
    final participant = _room?.localParticipant;
    if (participant == null) {
      return;
    }
    await participant.setMicrophoneEnabled(!_muted);
  }

  Future<void> _handleLiveKitRoomEvent(LiveKitEvent event) async {
    if (_room == null || _intentToDisconnect) {
      return;
    }

    if (event is RoomReconnectingEvent) {
      _emit(
        _snapshot.copyWith(
          phase: StreamConnectionPhase.reconnecting,
          connected: false,
          publishing: false,
          message: 'Reconnecting speaker session...',
        ),
      );
      return;
    }

    if (event is RoomReconnectedEvent) {
      _emit(
        _snapshot.copyWith(
          phase: StreamConnectionPhase.connected,
          connected: true,
          publishing: !_muted,
          message: _muted ? 'Microphone muted' : 'Publishing live audio',
        ),
      );
      return;
    }

    if (event is RoomDisconnectedEvent) {
      if (!_intentToDisconnect) {
        final reasonDetail = event.reason?.toString();
        final human = reasonDetail == null || reasonDetail.isEmpty
            ? 'Speaker session disconnected unexpectedly.'
            : 'Speaker session disconnected: $reasonDetail.';
        await _shutdownRoomOnly();
        _emitFailed(human);
      } else {
        await _shutdownRoomOnly();
      }
    }
  }

  Future<void> _shutdownRoomOnly() async {
    await _cancelListen?.call();
    _cancelListen = null;
    final room = _room;
    if (room == null) {
      return;
    }
    try {
      await room.disconnect();
      await room.dispose();
    } catch (_) {
      //
    }
    _room = null;
  }

  void _emitFailed(String detail) {
    _snapshot = LiveKitSpeakerSnapshot(
      phase: StreamConnectionPhase.failed,
      connected: false,
      publishing: false,
      message: 'Speaker connection failed.',
      lastErrorDetail: detail,
      muted: _muted,
    );
    _broadcast();
  }

  void _broadcast() {
    _snapshotController?.add(_snapshot);
  }

  void _emit(LiveKitSpeakerSnapshot next) {
    _snapshot = next;
    _broadcast();
  }
}
