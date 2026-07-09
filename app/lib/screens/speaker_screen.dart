import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/listener_link.dart';
import '../models/public_channel.dart';
import '../services/livekit_speaker_service.dart';
import '../services/microphone_permission.dart';
import '../services/stream_connection_service.dart';
import '../widgets/share_channel_qr_sheet.dart';

class SpeakerScreen extends StatefulWidget {
  const SpeakerScreen({
    super.key,
    required this.link,
    required this.channelContext,
    this.sessionCookieHeader,
  });

  final ListenerLink link;
  final PublicChannelContext channelContext;
  final String? sessionCookieHeader;

  @override
  State<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends State<SpeakerScreen> {
  final _speakerService = LiveKitSpeakerService();
  StreamSubscription<LiveKitSpeakerSnapshot>? _snapshotSubscription;

  bool _busy = false;
  late LiveKitSpeakerSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _speakerService.snapshot;
    _snapshotSubscription = _speakerService.snapshots.listen((snapshot) {
      if (!mounted) {
        return;
      }
      setState(() => _snapshot = snapshot);
    });
  }

  @override
  void dispose() {
    _snapshotSubscription?.cancel();
    _speakerService.dispose();
    super.dispose();
  }

  Future<void> _togglePublishing() async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);
    try {
      if (_snapshot.connected) {
        await _speakerService.disconnect();
      } else {
        await _speakerService.connect(
          link: widget.link,
          channelContext: widget.channelContext,
          sessionCookieHeader: widget.sessionCookieHeader,
        );
      }
    } on MicrophonePermissionDeniedException catch (error) {
      if (!mounted) {
        return;
      }
      final openSettings = error.message.contains('app settings');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: openSettings
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: () {
                    unawaited(openAppSettings());
                  },
                )
              : null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _toggleMute() async {
    await _speakerService.toggleMuted();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.channelContext.event;
    final channel = widget.channelContext.channel;
    final connected = _snapshot.connected;
    final failed = _snapshot.phase == StreamConnectionPhase.failed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaker'),
        actions: [
          IconButton(
            tooltip: 'Share listener QR',
            onPressed: () {
              unawaited(
                showShareChannelQrSheet(
                  context: context,
                  link: widget.link,
                  eventName: event.name,
                  channelName: channel.name,
                ),
              );
            },
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                event.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                channel.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Publish live translation audio to listeners on this channel.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(
                    showShareChannelQrSheet(
                      context: context,
                      link: widget.link,
                      eventName: event.name,
                      channelName: channel.name,
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Share listener QR'),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _snapshot.message ?? 'Ready',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_snapshot.lastErrorDetail != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _snapshot.lastErrorDetail!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _togglePublishing,
                icon: Icon(connected ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(
                  connected ? 'Stop publishing' : 'Start publishing',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: !connected || _busy ? null : _toggleMute,
                icon: Icon(_snapshot.muted ? Icons.mic_off_rounded : Icons.mic_rounded),
                label: Text(_snapshot.muted ? 'Unmute microphone' : 'Mute microphone'),
              ),
              if (failed) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _togglePublishing,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
