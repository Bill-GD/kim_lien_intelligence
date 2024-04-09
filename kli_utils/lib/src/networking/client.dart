import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../global.dart';
import '../global_export.dart';
import 'networking.dart';

class KLIClient {
  final Socket? _socket;

  /// Use [KLIClient.init] to create an instance
  KLIClient(this._socket);

  String? get address => _socket?.address.address;
  Socket? get socket => _socket;
  bool get started => _socket != null;

  // stream for server message
  final _onMessageReceivedController = StreamController<KLISocketMessage>.broadcast();
  Stream<KLISocketMessage> get onMessageReceived => _onMessageReceivedController.stream;

  static Future<KLIClient> init(String ip, String clientID, [int port = 8080]) async {
    logMessageController.add((LogType.info, 'Trying to connect to: $ip'));

    final s = KLIClient(await Socket.connect(ip, port).timeout(
      3.seconds,
      onTimeout: () {
        throw TimeoutException('Timeout when trying to connect to $ip');
      },
    ));

    logMessageController.add((LogType.info, 'Connected to $ip as $clientID'));

    s._socket!.write(KLISocketMessage(clientID, clientID, KLIMessageType.sendID));
    logMessageController.add((LogType.info, 'Sent ID ($clientID) to server'));

    s._socket!.listen(s.handleIncomingMessage);

    return s;
  }

  void handleIncomingMessage(Uint8List data) {
    final serverMessage = KLISocketMessage.fromJson(jsonDecode(String.fromCharCodes(data).trim()));
    logMessageController.add((LogType.info, '[Server, ${serverMessage.type}] ${serverMessage.msg}'));
    _onMessageReceivedController.add(serverMessage);
  }

  void sendMessage(KLISocketMessage message) {
    if (!started) return;
    _socket!.write(message);
  }
}
