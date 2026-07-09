import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/listener_link.dart';

Future<void> showShareChannelQrSheet({
  required BuildContext context,
  required ListenerLink link,
  required String eventName,
  required String channelName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return ShareChannelQrSheet(
        link: link,
        eventName: eventName,
        channelName: channelName,
      );
    },
  );
}

class ShareChannelQrSheet extends StatefulWidget {
  const ShareChannelQrSheet({
    super.key,
    required this.link,
    required this.eventName,
    required this.channelName,
  });

  final ListenerLink link;
  final String eventName;
  final String channelName;

  @override
  State<ShareChannelQrSheet> createState() => _ShareChannelQrSheetState();
}

class _ShareChannelQrSheetState extends State<ShareChannelQrSheet> {
  bool _copied = false;

  String get _listenUrl => widget.link.listenUrl;

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _listenUrl));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listener link copied')),
    );
  }

  Future<void> _shareLink() async {
    await Share.share(
      'Listen to ${widget.channelName} (${widget.eventName}):\n$_listenUrl',
      subject: '${widget.channelName} — ablaut',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Share this channel',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Others can scan this QR with any camera or the ablaut app to open the listener page.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.eventName} · ${widget.channelName}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: _listenUrl,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF163F35),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF163F35),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(
            _listenUrl,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _shareLink,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Share link'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _copyLink,
            icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded),
            label: Text(_copied ? 'Copied' : 'Copy link'),
          ),
        ],
      ),
    );
  }
}
