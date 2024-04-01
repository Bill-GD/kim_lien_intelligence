import 'dart:async';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;

Future<String> getPublicIP() async {
  return (await http.get(Uri.parse('https://api.ipify.org'))).body;
}

Future<String> getLocalIP() async {
  return (await NetworkInfo().getWifiIP()).toString();
}

Future<ServerSocket> initServer(String ip, [int port = 8080]) async {
  ServerSocket serverSocket;

  serverSocket = await ServerSocket.bind(InternetAddress(ip, type: InternetAddressType.IPv4), port);

  return serverSocket;
}

Future<Socket> connectToServer(String ip, [int port = 8080]) async {
  Socket socket;

  socket = await Socket.connect(ip, port).timeout(
    const Duration(seconds: 3),
    onTimeout: () {
      throw TimeoutException('Timeout when trying to connect to $ip');
    },
  );

  return socket;
}
