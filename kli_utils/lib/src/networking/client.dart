import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class KLIClient {
  final Socket _socket;

  KLIClient.fromSocket(Socket socket) : _socket = socket;

  String get address => _socket.address.address;
  Socket get socket => _socket;

  static Future<KLIClient> initClient(String ip, [int port = 8080]) async {
    debugPrint('Trying to connect to: $ip');
    Socket socket = await Socket.connect(ip, port).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw TimeoutException('Timeout when trying to connect to $ip');
      },
    );
    return KLIClient.fromSocket(socket);
  }

  void sendMessage(String msg) {
    _socket.write(msg);
  }
}
