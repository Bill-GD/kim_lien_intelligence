import 'dart:async';
import 'dart:convert';

import 'package:network_info_plus/network_info_plus.dart';

class Networking {
  static Future<String> getLocalIP() async => (await NetworkInfo().getWifiIP()).toString();

  static final _idMap = <ClientID, String>{
    ClientID.host: 'Host',
    ClientID.player1: 'Player 1',
    ClientID.player2: 'Player 2',
    ClientID.player3: 'Player 3',
    ClientID.player4: 'Player 4',
    ClientID.viewer1: 'Viewer 1',
    ClientID.viewer2: 'Viewer 2',
    ClientID.mc: 'MC',
  };
  static String getClientDisplayID(ClientID clientID) => _idMap[clientID]!;
}

enum ClientID { host, player1, player2, player3, player4, viewer1, viewer2, mc }

enum KLIMessageType {
  sendID,
  disconnect,
}

class KLISocketMessage {
  ClientID senderID;
  String msg;
  KLIMessageType type;

  KLISocketMessage({required this.senderID, required String message, required this.type}) : msg = message;

  @override
  String toString() {
    return jsonEncode({'senderID': senderID.name, 'message': utf8.encode(msg), 'type': type.name});
  }

  factory KLISocketMessage.fromJson(Map<String, dynamic> json) {
    return KLISocketMessage(
      senderID: ClientID.values.byName(json['senderID']),
      message: utf8.decode(List<int>.from(json['message'])),
      type: KLIMessageType.values.byName(json['type']),
    );
  }
}
