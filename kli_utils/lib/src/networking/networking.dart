import 'dart:async';
import 'dart:convert';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;

Future<String> getPublicIP() async {
  final http.Response response;

  try {
    response = await http.get(Uri.parse('https://api.ipify.org'));
  } on Exception {
    return 'None';
  }

  return response.body;
}

Future<String> getLocalIP() async {
  return (await NetworkInfo().getWifiIP()).toString();
}

const listOfClient = ['Player 1', 'Player 2', 'Player 3', 'Player 4', 'Viewer 1', 'Viewer 2', 'MC'];

enum KLIMessageType {
  sendID,
  normal,
}

class KLISocketMessage {
  String? senderID;
  String msg;
  KLIMessageType type;

  KLISocketMessage(this.senderID, this.msg, this.type);

  @override
  String toString() {
    return jsonEncode({'senderID': senderID, 'message': msg, 'type': type.name});
  }

  factory KLISocketMessage.fromJson(Map<String, dynamic> json) {
    return KLISocketMessage(json['senderID'], json['message'], KLIMessageType.values.byName(json['type']));
  }
}
