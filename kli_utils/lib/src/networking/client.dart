import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'networking.dart';

class KLIClient {
  static Socket? _socket;

  static String? get address => _socket?.address.address;
  static Socket? get socket => _socket;
  static bool get started => _socket != null;

  static Future<void> init(String ip, String clientID, [int port = 8080]) async {
    debugPrint('Trying to connect to: $ip');

    _socket = await Socket.connect(ip, port).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw TimeoutException('Timeout when trying to connect to $ip');
      },
    );

    _socket!.write(KLISocketMessage(clientID, clientID, KLIMessageType.sendID));
  }

  static void sendMessage(KLISocketMessage message) {
    if (!started) return;
    _socket!.write(message);
  }
}
