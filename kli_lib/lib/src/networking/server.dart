import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../global.dart';
import '../global_export.dart';
import 'networking.dart';

class KLIServer {
  static const _maxConnectionCount = 7;

  static const mapIDToIndex = {
    ClientID.player1: 0,
    ClientID.player2: 1,
    ClientID.player3: 2,
    ClientID.player4: 3,
    ClientID.viewer1: 4,
    ClientID.viewer2: 5,
    ClientID.mc: 6
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

  static bool get allPlayerConnected => _clientList.take(4).every((element) => element != null);

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

          String cID = mapIDToIndex.keys.firstWhere((e) => mapIDToIndex[e] == idx).name;

          _onClientConnectivityChangedController.add(true);
          logMessageController.add((LogType.info, 'Client $cID disconnected'));
        },
        onError: (error) {
          logMessageController.add((LogType.error, error.toString()));
        },
      );
    });
  }

  static void sendMessage(ClientID clientID, KLISocketMessage message) {
    logMessageController.add((LogType.info, 'Attempting to send message to $clientID'));
    Socket? client = getClient(clientID);
    if (client == null) {
      logMessageController.add((LogType.info, 'Client $clientID not connected, aborting'));
      return;
    }

    client.write(message);
  }

  static void handleClientConnection(Socket clientSocket, KLISocketMessage socMsg) {
    final clientID = socMsg.senderID;
    int idx = getClientIndex(clientID);

    if (idx < 0) {
      logMessageController.add((LogType.warn, 'Can\'t find client $clientID, aborting'));
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

  static Socket? getClient(ClientID clientID) {
    int idx = getClientIndex(clientID);
    if (idx < 0) {
      logMessageController.add((LogType.warn, 'Can\'t find client $clientID, aborting'));
      return null;
    }
    return clientAt(idx);
  }

  static int getClientIndex(ClientID clientID) {
    return mapIDToIndex[clientID] ?? -1;
  }

  static Future<void> stop() async {
    if (!started) return;

    logMessageController.add(const (LogType.info, 'Disconnecting all clients'));

    for (int i = 0; i < _clientList.length; i++) {
      if (_clientList[i] == null) continue;
      sendMessage(
        ClientID.values[i + 1],
        KLISocketMessage(senderID: ClientID.host, message: '', type: KLIMessageType.disconnect),
      );
    }
    for (final client in _clientList) {
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