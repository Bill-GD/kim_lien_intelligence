import 'dart:io';

import 'package:kli_lib/kli_lib.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

String? parentFolder;
void initParentFolder() {
  if (parentFolder != null) return;

  final rawDir = Platform.resolvedExecutable.split(Platform.executable).first;
  parentFolder = rawDir.substring(0, rawDir.length - 1).replaceAll('\\', '/');

  File('$parentFolder\\log.txt').createSync();
}

late final PackageInfo packageInfo;
Future<void> initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  logger.i('PackageInfo init');
}

late final Logger logger;
void initLogger() {
  logger = Logger(
    printer: SimplePrinter(colors: false, printTime: true),
    filter: AlwaysLogFilter(),
    output: FileOutput(file: File('$parentFolder\\log.txt'), overrideExisting: true),
  );
  logger.i('Logger init');
}

late KLIClient kliClient;
Future<void> initClient(String ip, ClientID clientID, [int port = 8080]) async {
  kliClient = await KLIClient.init(ip, clientID, port);
}

String changelog = """
  0.1 ({latest}):
  - Improved UI
  - Improved server-client connection
  - Added changelog
  - Handles disconnection from server
  - Disable info fields if already connected
  - Logger now logs to file
  - Force fullscreen
  - Added themes

  0.0.1.x ({d9628a9}):
  - Initial version -> setup workspace
  - App icon
  - Added basic server setup & server-client connection""";
