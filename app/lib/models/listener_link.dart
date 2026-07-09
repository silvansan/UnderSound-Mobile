import 'ablaut_link_role.dart';

class ListenerLink {
  const ListenerLink({
    required this.serverUrl,
    required this.eventSlug,
    required this.originalUrl,
    this.channelSlug,
    this.role = AblautLinkRole.listener,
  });

  final Uri serverUrl;
  final String eventSlug;
  final String? channelSlug;
  final Uri originalUrl;
  final AblautLinkRole role;

  bool get isEventDirectory => channelSlug == null || channelSlug!.isEmpty;
  bool get isSpeaker => role == AblautLinkRole.speaker;

  /// Canonical HTTPS listen URL other phones can scan or open.
  String get listenUrl {
    final slug = channelSlug;
    if (slug == null || slug.isEmpty) {
      return serverUrl.replace(pathSegments: ['listen', eventSlug]).toString();
    }

    return serverUrl
        .replace(pathSegments: ['listen', eventSlug, slug])
        .toString();
  }

  ListenerLink withChannelSlug(String channelSlug) {
    return ListenerLink(
      serverUrl: serverUrl,
      eventSlug: eventSlug,
      channelSlug: channelSlug,
      originalUrl: originalUrl,
      role: role,
    );
  }
}
