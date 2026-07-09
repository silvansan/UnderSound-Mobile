import '../models/ablaut_link_role.dart';
import '../models/listener_link.dart';

class AblautLinkParser {
  static ListenerLink parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Enter an ablaut link.');
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      throw const FormatException('Enter a complete link, including https://.');
    }

    if (uri.scheme == 'undersound') {
      return _parseCustomScheme(uri);
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('Unsupported link type.');
    }

    final segments = uri.pathSegments;
    final firstSegment = segments.isEmpty ? '' : segments[0].toLowerCase();
    if (segments.length >= 3 &&
        (firstSegment == 'speak' || firstSegment == 'speaker')) {
      return ListenerLink(
        serverUrl: _origin(uri),
        eventSlug: segments[1],
        channelSlug: segments[2],
        originalUrl: uri,
        role: AblautLinkRole.speaker,
      );
    }

    if (segments.length >= 2 &&
        (firstSegment == 'listen' || firstSegment == 'listener')) {
      if (segments.length == 2) {
        return ListenerLink(
          serverUrl: _origin(uri),
          eventSlug: segments[1],
          originalUrl: uri,
        );
      }

      return ListenerLink(
        serverUrl: _origin(uri),
        eventSlug: segments[1],
        channelSlug: segments[2],
        originalUrl: uri,
      );
    }

    final eventIndex = segments.indexOf('e');
    if (eventIndex != -1 && segments.length > eventIndex + 2) {
      final page = segments[eventIndex + 2].toLowerCase();
      if (page == 'listen') {
        return ListenerLink(
          serverUrl: _origin(uri),
          eventSlug: segments[eventIndex + 1],
          originalUrl: uri,
        );
      }

      if (page == 'speak' || page == 'speaker') {
        if (segments.length <= eventIndex + 3) {
          throw const FormatException('Speaker links must include a channel.');
        }

        return ListenerLink(
          serverUrl: _origin(uri),
          eventSlug: segments[eventIndex + 1],
          channelSlug: segments[eventIndex + 2],
          originalUrl: uri,
          role: AblautLinkRole.speaker,
        );
      }

      if (segments.length > eventIndex + 3) {
        final legacyPage = segments[eventIndex + 3].toLowerCase();
        if (legacyPage == 'listen') {
          return ListenerLink(
            serverUrl: _origin(uri),
            eventSlug: segments[eventIndex + 1],
            channelSlug: segments[eventIndex + 2],
            originalUrl: uri,
          );
        }

        if (legacyPage == 'speaker') {
          return ListenerLink(
            serverUrl: _origin(uri),
            eventSlug: segments[eventIndex + 1],
            channelSlug: segments[eventIndex + 2],
            originalUrl: uri,
            role: AblautLinkRole.speaker,
          );
        }
      }
    }

    throw const FormatException(
      'This does not look like an ablaut listener or speaker link.',
    );
  }

  static ListenerLink _parseCustomScheme(Uri uri) {
    final server = uri.queryParameters['server'] ?? '';
    final event = uri.queryParameters['event'] ?? '';
    final channel = uri.queryParameters['channel'] ?? '';
    final mode = uri.queryParameters['mode']?.toLowerCase() ?? 'listen';
    final serverUri = Uri.tryParse(server);

    if (serverUri == null || !serverUri.hasScheme || serverUri.host.isEmpty) {
      throw const FormatException('The app link is missing a valid server.');
    }
    if (event.isEmpty) {
      throw const FormatException('The app link is missing event data.');
    }

    return ListenerLink(
      serverUrl: _origin(serverUri),
      eventSlug: event,
      channelSlug: channel.isEmpty ? null : channel,
      originalUrl: uri,
      role: mode == 'speak' || mode == 'speaker'
          ? AblautLinkRole.speaker
          : AblautLinkRole.listener,
    );
  }

  static Uri _origin(Uri uri) {
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    );
  }
}

/// Backward-compatible alias used across the app.
typedef ListenerLinkParser = AblautLinkParser;
