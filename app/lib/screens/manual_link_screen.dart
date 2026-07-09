import 'package:flutter/material.dart';

import '../services/listener_channel_launcher.dart';
import '../services/listener_link_parser.dart';
import '../services/listener_session_coordinator.dart';

class ManualLinkScreen extends StatefulWidget {
  const ManualLinkScreen({
    super.key,
    this.addConnectedChannelToFavorites = false,
  });

  final bool addConnectedChannelToFavorites;

  @override
  State<ManualLinkScreen> createState() => _ManualLinkScreenState();
}

class _ManualLinkScreenState extends State<ManualLinkScreen> {
  final _controller = TextEditingController();
  final _launcher = const ListenerChannelLauncher();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final link = ListenerLinkParser.parse(_controller.text);
      await _launcher.openLink(
        context: context,
        link: link,
        addToFavorites: widget.addConnectedChannelToFavorites,
        replaceCurrentRoute: true,
      );
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    } on ListenerAccessException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter ablaut link')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Listener or speaker URL',
              hintText: 'https://your-server/listen/event/en or /speak/event/en',
            ),
            onSubmitted: (_) => _connect(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _connect,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: Text(_loading ? 'Connecting...' : 'Connect'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
