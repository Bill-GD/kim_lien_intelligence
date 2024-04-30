import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../global.dart';
import '../global_export.dart';
import 'networking.dart';

class KLIServer {
  static const _maxConnectionCount = 7;

  static const mapIDToIndex = {
    'player1': 0,
    'player2': 1,
    'player3': 2,
    'player4': 3,
    'viewer1': 4,
    'viewer2': 5,
    'mc': 6
  };

  static ServerSocket? _serverSocket;
  static ServerSocket? get serverSocket => _serverSocket;
  static String? get address => _serverSocket?.address.address;
  static bool get started => _serverSocket != null;

  // 0-3: player, 4-5: viewer, 6: mc
  static List<Socket?> _clientList = List.generate(_maxConnectionCount, (_) => null);
  static List<Socket?> get clientList => _clientList;
  static Socket? clientAt(int index) => _clientList[index];
  static int get totalClientCount => _clientList.length;
  static int get connectedClientCount => _clientList.where((element) => element != null).length;

  static StreamController<bool> _onClientConnectivityChangedController = StreamController<bool>.broadcast();
  static Stream<bool> get onClientConnectivityChanged => _onClientConnectivityChangedController.stream;

  // stream for client message
  static StreamController<KLISocketMessage> _onClientMessageController =
      StreamController<KLISocketMessage>.broadcast();
  static Stream<KLISocketMessage> get onClientMessage => _onClientMessageController.stream;

  static Future<void> start([int port = 8080]) async {
    String ip = await Networking.getLocalIP();

    _serverSocket = await ServerSocket.bind(InternetAddress(ip, type: InternetAddressType.IPv4), port);
    logMessageController.add((LogType.info, 'Server started on ${_serverSocket?.address}'));

    _onClientConnectivityChangedController = StreamController<bool>.broadcast();
    _onClientMessageController = StreamController<KLISocketMessage>.broadcast();

    _serverSocket!.listen((Socket clientSocket) {
      clientSocket.listen(
        (data) {
          KLISocketMessage socMsg = KLISocketMessage.fromJson(jsonDecode(String.fromCharCodes(data).trim()));

          if (socMsg.type == KLIMessageType.sendID) {
            handleClientConnection(clientSocket, socMsg);
          } else {
            handleClientMessage(clientSocket, socMsg);
          }
        },
        onDone: () {
          final idx = _clientList.indexOf(clientSocket);
          _clientList[idx] = null;

          String cID = mapIDToIndex.keys.firstWhere((e) => mapIDToIndex[e] == idx);

          _onClientConnectivityChangedController.add(true);
          logMessageController.add((LogType.info, 'Client $cID disconnected'));
        },
        onError: (error) {
          logMessageController.add((LogType.error, error.toString()));
        },
      );
    });
  }

  static void sendMessage(String clientID, KLISocketMessage message) {
    Socket? client = getClient(clientID);
    if (client == null) {
      logMessageController.add((LogType.info, 'Client $clientID not connected, aborting'));
      return;
    }

    client.write(message);
  }

  static void handleClientConnection(Socket clientSocket, KLISocketMessage socMsg) {
    final clientID = socMsg.msg;
    int idx = getClientIndex(clientID);

    if (idx < 0) {
      logMessageController.add(const (LogType.warn, 'Trying to assign to index -1, aborting'));
      return;
    }

    _clientList[idx] = clientSocket;
    logMessageController.add((LogType.info, 'Client $clientID connected, saved to index $idx'));

    _onClientConnectivityChangedController.add(true);
  }

  static void handleClientMessage(Socket clientSocket, KLISocketMessage socMsg) {
    logMessageController.add((
      LogType.info,
      '[${clientSocket.address.address}, ${socMsg.senderID}, ${socMsg.type}] ${socMsg.msg}',
    ));
    _onClientMessageController.add(socMsg);
  }

  static int getClientIndex(String clientID) {
    return mapIDToIndex[clientID] ?? -1;
  }

  static Socket? getClient(String clientID) {
    int idx = getClientIndex(clientID);
    if (idx < 0) {
      logMessageController.add(const (LogType.warn, 'Trying to assign to index -1, aborting'));
      return null;
    }
    return clientAt(idx);
  }

  static Future<void> stop() async {
    if (!started) return;

    logMessageController.add(const (LogType.info, 'Disconnecting all clients'));

    int idx = 0;
    for (final client in _clientList) {
      sendMessage(mapIDToIndex.keys.elementAt(idx), KLISocketMessage('host', '', KLIMessageType.disconnect));
      client?.destroy();
    }
    _clientList = List.generate(_maxConnectionCount, (_) => null);

    logMessageController.add(const (LogType.info, 'Closing server socket'));
    _onClientConnectivityChangedController.close();
    _onClientMessageController.close();
    await _serverSocket?.close();
    _serverSocket = null;
  }
}
