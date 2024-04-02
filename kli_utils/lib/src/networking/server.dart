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

    if (type == ServerIPType.public && ip == 'None') {
      throw Exception('Internet access not available, please create local server instead.');
    }

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
    
    final newClient = KLIClient.fromSocket(clientSocket);
    newClient.socket.listen((data) {
      debugPrint(
        '[${clientSocket.address.address}:${clientSocket.port}, id=${_clients.length}] ${String.fromCharCodes(data).trim()}',
      );
    });
    _clients.add(newClient);

    debugPrint('Client connected: ${clientSocket.address.address}:${clientSocket.port}');
  }

  void sendMessage(KLIClient client, String msg) {
    client.sendMessage(msg);
  }

  Future<void> closeServer() async {
    await _serverSocket.close();
  }
}
