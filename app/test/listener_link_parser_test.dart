import 'package:flutter_test/flutter_test.dart';
import 'package:ablaut_app/models/ablaut_link_role.dart';
import 'package:ablaut_app/services/listener_link_parser.dart';

void main() {
  test('parses event-only listener URLs', () {
    final link = ListenerLinkParser.parse(
      'https://voice.example.com/listen/default-event',
    );

    expect(link.serverUrl.toString(), 'https://voice.example.com');
    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, isNull);
    expect(link.isEventDirectory, isTrue);
    expect(link.role, AblautLinkRole.listener);
  });

  test('parses legacy event-only listener URLs', () {
    final link = ListenerLinkParser.parse(
      'https://voice.example.com/e/default-event/listen',
    );

    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, isNull);
    expect(link.isEventDirectory, isTrue);
  });

  test('parses Studio v2 listener URLs', () {
    final link = ListenerLinkParser.parse(
      'https://voice.example.com/listen/default-event/en',
    );

    expect(link.serverUrl.toString(), 'https://voice.example.com');
    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, 'en');
    expect(link.originalUrl.toString(),
        'https://voice.example.com/listen/default-event/en');
  });

  test('parses Studio v2 speaker URLs', () {
    final link = ListenerLinkParser.parse(
      'https://voice.example.com/speak/default-event/en',
    );

    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, 'en');
    expect(link.isSpeaker, isTrue);
  });

  test('parses speaker compatibility URLs', () {
    final link = ListenerLinkParser.parse(
      'https://voice.example.com/speaker/default-event/fr',
    );

    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, 'fr');
    expect(link.isSpeaker, isTrue);
  });

  test('parses Studio v2 compatibility listener URLs', () {
    final link = ListenerLinkParser.parse(
      'https://voice.example.com/listener/default-event/fr',
    );

    expect(link.serverUrl.toString(), 'https://voice.example.com');
    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, 'fr');
  });

  test('parses legacy undersound:// listener URLs without requiring token data',
      () {
    final link = ListenerLinkParser.parse(
      'https://voice.example.com/e/default-event/English/listen?token=abc123',
    );

    expect(link.serverUrl.toString(), 'https://voice.example.com');
    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, 'English');
  });

  test('parses legacy speaker URLs', () {
    final link = ListenerLinkParser.parse(
      'https://voice.example.com/e/default-event/English/speaker?token=abc123',
    );

    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, 'English');
    expect(link.isSpeaker, isTrue);
  });

  test('parses custom app scheme URLs', () {
    final link = ListenerLinkParser.parse(
      'undersound://listen?server=https://voice.example.com&event=default-event&channel=FR',
    );

    expect(link.serverUrl.toString(), 'https://voice.example.com');
    expect(link.eventSlug, 'default-event');
    expect(link.channelSlug, 'FR');
  });

  test('parses custom app scheme speaker URLs', () {
    final link = ListenerLinkParser.parse(
      'undersound://listen?server=https://voice.example.com&event=default-event&channel=FR&mode=speak',
    );

    expect(link.isSpeaker, isTrue);
  });
}
