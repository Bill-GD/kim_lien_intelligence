import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../global.dart';
import '../global_export.dart';
import 'networking.dart';

class KLIClient {
  static Socket? _socket;
  static ClientID? clientID;

  /// Use [KLIClient.init] to create an instance
  // KLIClient(this._socket, this.clientID);

  static String? get address => _socket?.address.address;
  static Socket? get socket => _socket;
  static bool get started => _socket != null;

  // stream for server message
  static final _onMessageReceivedController = StreamController<KLISocketMessage>.broadcast();
  static Stream<KLISocketMessage> get onMessageReceived => _onMessageReceivedController.stream;

  static Future<void> init(String ip, ClientID clientID, [int port = 8080]) async {
    logMessageController.add((LogType.info, 'Trying to connect to: $ip'));

    // final s = KLIClient(
    //   await Socket.connect(ip, port).timeout(
    //     3.seconds,
    //     onTimeout: () {
    //       throw TimeoutException('Timeout when trying to connect to $ip');
    //     },
    //   ),
    //   clientID,
    // );

    _socket = await Socket.connect(ip, port).timeout(
      3.seconds,
      onTimeout: () {
        throw TimeoutException('Timeout when trying to connect to $ip');
      },
    );
    KLIClient.clientID = clientID;

    logMessageController.add((LogType.info, 'Connected to $ip as: $clientID'));

    _socket!.write(KLISocketMessage(
      senderID: clientID,
      message: clientID.name,
      type: KLIMessageType.sendID,
    ));
    logMessageController.add((LogType.info, 'Sent ID ($clientID) to server'));

    _socket!.listen(handleIncomingMessage);

    // return s;
  }

  static void handleIncomingMessage(Uint8List data) {
    final serverMessage = KLISocketMessage.fromJson(jsonDecode(String.fromCharCodes(data).trim()));
    logMessageController.add((
      LogType.info,
      '[${serverMessage.senderID}, ${serverMessage.type}] ${serverMessage.msg}',
    ));
    _onMessageReceivedController.add(serverMessage);
  }

  static void sendMessage(KLISocketMessage message) {
    if (!started) return;
    logMessageController.add((LogType.info, 'Sending message: $message'));
    _socket!.write(message);
  }

  static Future<void> disconnect() async {
    if (!started) return;
    clientID = null;
    await _socket!.close();
  }
}
