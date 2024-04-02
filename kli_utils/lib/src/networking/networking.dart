import 'dart:async';

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
