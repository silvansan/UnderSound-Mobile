import 'package:flutter_test/flutter_test.dart';
import 'package:ablaut_app/services/http_cookie_utils.dart';

void main() {
  test('builds cookie header from set-cookie response headers', () {
    final header = cookieHeaderFromResponse({
      'set-cookie':
          'ablaut_speaker_abc123=token-value; Path=/; HttpOnly; SameSite=Lax',
    });

    expect(header, 'ablaut_speaker_abc123=token-value');
  });
}
