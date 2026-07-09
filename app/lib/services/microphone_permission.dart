import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class MicrophonePermissionDeniedException implements Exception {
  const MicrophonePermissionDeniedException([
    this.message =
        'Microphone permission is required to publish speaker audio.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Ensures the OS microphone permission is granted before LiveKit publish.
///
/// Returns `true` when the mic may be used. Throws
/// [MicrophonePermissionDeniedException] when the user denies access.
Future<bool> ensureMicrophonePermission() async {
  if (kIsWeb) {
    // Browsers prompt when getUserMedia runs inside LiveKit/WebRTC.
    return true;
  }

  if (!(Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS)) {
    return true;
  }

  var status = await Permission.microphone.status;
  if (status.isGranted || status.isLimited) {
    return true;
  }

  status = await Permission.microphone.request();
  if (status.isGranted || status.isLimited) {
    return true;
  }

  if (status.isPermanentlyDenied) {
    throw const MicrophonePermissionDeniedException(
      'Microphone permission is blocked. Open app settings and allow the microphone, then try again.',
    );
  }

  throw const MicrophonePermissionDeniedException();
}
