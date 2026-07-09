import 'package:flutter/material.dart';

Future<String?> showListenerPasswordDialog(
  BuildContext context, {
  String title = 'Listener password',
  String description =
      'This channel requires a listener password from the organizer.',
  String? errorText,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _ListenerPasswordDialog(
        title: title,
        description: description,
        initialError: errorText,
      );
    },
  );
}

class _ListenerPasswordDialog extends StatefulWidget {
  const _ListenerPasswordDialog({
    required this.title,
    required this.description,
    this.initialError,
  });

  final String title;
  final String description;
  final String? initialError;

  @override
  State<_ListenerPasswordDialog> createState() => _ListenerPasswordDialogState();
}

class _ListenerPasswordDialogState extends State<_ListenerPasswordDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _errorText = widget.initialError;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.description),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the listener password.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
