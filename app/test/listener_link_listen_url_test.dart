import 'package:flutter_test/flutter_test.dart';

import 'package:ablaut_app/models/ablaut_link_role.dart';
import 'package:ablaut_app/models/listener_link.dart';

void main() {
  group('ListenerLink.listenUrl', () {
    test('builds channel listen URL from server origin', () {
      final link = ListenerLink(
        serverUrl: Uri.parse('https://studio.example.com'),
        eventSlug: 'sunday',
        channelSlug: 'english',
        originalUrl: Uri.parse('https://studio.example.com/speak/sunday/english'),
        role: AblautLinkRole.speaker,
      );

      expect(link.listenUrl, 'https://studio.example.com/listen/sunday/english');
    });

    test('builds event directory listen URL when channel is missing', () {
      final link = ListenerLink(
        serverUrl: Uri.parse('https://studio.example.com'),
        eventSlug: 'sunday',
        originalUrl: Uri.parse('https://studio.example.com/listen/sunday'),
      );

      expect(link.listenUrl, 'https://studio.example.com/listen/sunday');
    });
  });
}
