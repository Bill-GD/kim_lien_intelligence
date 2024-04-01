import 'dart:io';

import 'package:flutter/foundation.dart';

import 'client.dart';
import 'networking.dart';

enum ServerIPType { local, public }

class KLIServer {
  final ServerSocket _serverSocket;
  final List<KLIClient> _clients = [];

  KLIServer(this._serverSocket);

  String get address => _serverSocket.address.address;
  ServerSocket get socket => _serverSocket;

  static Future<KLIServer> startServer([ServerIPType type = ServerIPType.local, int port = 8080]) async {
    String ip = type == ServerIPType.local ? await getLocalIP() : await getPublicIP();

    ServerSocket serverSocket = await ServerSocket.bind(
      InternetAddress(ip, type: InternetAddressType.IPv4),
      port,
    );

    final s = KLIServer(serverSocket);
    s._serverSocket.listen(s.handleClientConnection);

    return s;
  }

  void handleClientConnection(Socket clientSocket) {
    if (_clients.length >= 4) return;
    _clients.add(KLIClient.fromSocket(clientSocket));
    debugPrint('Client connected: ${clientSocket.address.address}');
  }

  void sendMessage(KLIClient client, String msg) {
    client.sendMessage(msg);
  }
}
