import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ablaut_app/services/microphone_permission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MicrophonePermissionDeniedException exposes message', () {
    const error = MicrophonePermissionDeniedException('blocked');
    expect(error.message, 'blocked');
    expect(error.toString(), 'blocked');
  });

  test('Permission.microphone is the expected permission group', () {
    expect(Permission.microphone.value, isNonZero);
  });
}
