import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'networking.dart';

class KLIClient {
  static Socket? _socket;

  static String? get address => _socket?.address.address;
  static Socket? get socket => _socket;
  static bool get started => _socket != null;

  // stream for server message
  static final _onMessageReceivedController = StreamController<KLISocketMessage>.broadcast();
  static Stream<KLISocketMessage> get onMessageReceived => _onMessageReceivedController.stream;

  static Future<void> init(String ip, String clientID, [int port = 8080]) async {
    debugPrint('Trying to connect to: $ip');

    _socket = await Socket.connect(ip, port).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw TimeoutException('Timeout when trying to connect to $ip');
      },
    );
    debugPrint('Connected to $ip as $clientID');

    _socket!.write(KLISocketMessage(clientID, clientID, KLIMessageType.sendID));
    debugPrint('Sent ID ($clientID) to server');

    _socket?.listen(handleIncomingMessage);
  }

  static void handleIncomingMessage(Uint8List data) {
    final serverMessage = KLISocketMessage.fromJson(jsonDecode(String.fromCharCodes(data).trim()));
    debugPrint('[Server, ${serverMessage.type}] ${serverMessage.msg}');
    _onMessageReceivedController.add(serverMessage);
  }

  static void sendMessage(KLISocketMessage message) {
    if (!started) return;
    _socket!.write(message);
  }
}
