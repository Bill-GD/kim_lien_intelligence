import 'dart:async';
import 'dart:convert';

import 'package:network_info_plus/network_info_plus.dart';

class Networking {
  static Future<String> getLocalIP() async => (await NetworkInfo().getWifiIP()).toString();

  static const listOfClient = ['Player 1', 'Player 2', 'Player 3', 'Player 4', 'Viewer 1', 'Viewer 2', 'MC'];
}

enum KLIMessageType {
  sendID,
  disconnect,
  normal,
}

class KLISocketMessage {
  String? senderID;
  String msg;
  KLIMessageType type;

  KLISocketMessage(this.senderID, this.msg, this.type);

  @override
  String toString() {
    return jsonEncode({'senderID': senderID, 'message': utf8.encode(msg), 'type': type.name});
  }

  factory KLISocketMessage.fromJson(Map<String, dynamic> json) {
    return KLISocketMessage(
      json['senderID'],
      utf8.decode(List<int>.from(json['message'])),
      KLIMessageType.values.byName(json['type']),
    );
  }
}
