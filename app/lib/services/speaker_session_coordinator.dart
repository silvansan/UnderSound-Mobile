import 'package:flutter/material.dart';

import '../models/listener_link.dart';
import '../models/public_channel.dart';
import '../widgets/listener_password_dialog.dart';
import 'ablaut_api_client.dart';
import 'listener_session_coordinator.dart';

class SpeakerSessionCoordinator {
  const SpeakerSessionCoordinator({AblautApiClient? api})
      : _api = api ?? const AblautApiClient();

  final AblautApiClient _api;

  void ensureSpeakerAccessible(PublicChannelContext channelContext) {
    if (!channelContext.speakerPageAvailable) {
      throw const ListenerAccessException(
        'Speaker publishing is not enabled for this channel.',
      );
    }
    if (!channelContext.channel.webrtcEnabled) {
      throw const ListenerAccessException(
        'WebRTC publishing is disabled for this channel.',
      );
    }
  }

  Future<String?> resolveSessionCookies({
    required BuildContext context,
    required ListenerLink link,
    required PublicChannelContext channelContext,
  }) async {
    ensureSpeakerAccessible(channelContext);

    if (!channelContext.speakerPasswordRequired) {
      return null;
    }

    if (!context.mounted) {
      return null;
    }

    final initialPassword = await showListenerPasswordDialog(
      context,
      title: 'Speaker password',
      description: 'Enter the speaker password for this channel.',
    );
    if (!context.mounted) {
      return null;
    }
    if (initialPassword == null) {
      throw const ListenerAccessException('Speaker password is required.');
    }

    var password = initialPassword;

    while (true) {
      try {
        return await _api.verifySpeakerPassword(
          link: link,
          password: password,
        );
      } on ApiException catch (error) {
        if (error.statusCode != 401 || !context.mounted) {
          rethrow;
        }
        final retryPassword = await showListenerPasswordDialog(
          context,
          title: 'Speaker password',
          description: 'Enter the speaker password for this channel.',
          errorText: 'Wrong speaker password.',
        );
        if (!context.mounted) {
          return null;
        }
        if (retryPassword == null) {
          throw const ListenerAccessException('Speaker password is required.');
        }
        password = retryPassword;
      }
    }
  }
}
