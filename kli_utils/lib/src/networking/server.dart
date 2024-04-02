import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'networking.dart';

class KLIServer {
  static const int _maxConnectionCount = 7;

  static ServerSocket? _serverSocket;
  static ServerSocket? get serverSocket => _serverSocket;
  static String? get address => _serverSocket?.address.address;
  static bool get started => _serverSocket != null;

  // 0-3: player, 4-5: viewer, 6: mc
  static List<Socket?> _clientList = List.generate(_maxConnectionCount, (_) => null);
  static Socket? clientAt(int index) => _clientList[index];
  static int get totalClientCount => _clientList.length;
  static int get connectedClientCount => _clientList.where((element) => element != null).length;

  static final _onClientConnectivityChangedController = StreamController<bool>.broadcast();
  static Stream<bool> get onClientConnectivityChanged => _onClientConnectivityChangedController.stream;

  static Future<void> start([int port = 8080]) async {
    String ip = await getLocalIP();

    _serverSocket = await ServerSocket.bind(InternetAddress(ip, type: InternetAddressType.IPv4), port);

    _serverSocket!.listen((Socket clientSocket) {
      clientSocket.listen(
        (data) {
          KLISocketMessage socMsg = KLISocketMessage.fromJson(jsonDecode(String.fromCharCodes(data)));
          debugPrint(
            '[${clientSocket.address.address}:${clientSocket.port}] ${socMsg.type}: ${socMsg.msg}',
          );

          if (socMsg.type == KLIMessageType.sendID) {
            handleClientConnection(clientSocket, socMsg);
          }
        },
        onDone: () {
          final idx = _clientList.indexOf(clientSocket);
          _clientList[idx] = null;

          String cID;
          if (idx < 4) {
            cID = 'player${idx + 1}';
          } else if (idx < 6) {
            cID = 'viewer${idx - 3}';
          } else {
            cID = 'mc';
          }

          _onClientConnectivityChangedController.add(true);
          debugPrint('Client $cID disconnected');
        },
        onError: (error) {
          debugPrint(error.toString());
        },
      );
    });
  }

  static void handleClientConnection(Socket clientSocket, KLISocketMessage socMsg) {
    final msg = socMsg.msg;
    int idx = -1;

    if (msg.contains('mc')) {
      idx = 6;
    } else {
      idx = int.parse(msg.substring(msg.length - 1)) - 1;

      if (msg.contains('viewer')) {
        idx += 4;
      }
    }
    // print error if idx is < 0
    if (idx < 0) {
      debugPrint('Trying to assign to index -1, aborting');
      return;
    }

    _clientList[idx] = clientSocket;
    debugPrint('Client $msg connected');

    clientSocket.write('Welcome, $msg');
    _onClientConnectivityChangedController.add(true);
  }

  static Future<void> stop() async {
    for (final client in _clientList) {
      client?.destroy();
    }
    _clientList = List.generate(_maxConnectionCount, (_) => null);
    await _serverSocket?.close();
    _serverSocket = null;
  }
}
