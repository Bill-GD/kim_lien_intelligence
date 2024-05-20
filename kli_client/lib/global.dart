import 'dart:io';

import 'package:kli_lib/kli_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';

late final PackageInfo packageInfo;
Future<void> initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  logHandler.info('PackageInfo init');
}

late final LogHandler logHandler;
void initLogHandler() {
  final rawDir = Platform.resolvedExecutable.split(Platform.executable).first;
  String parentFolder = '${rawDir.substring(0, rawDir.length - 1).replaceAll('\\', '/')}\\UserData';
  logHandler = LogHandler(logFile: '$parentFolder\\log.txt');
}

String changelog = """
  0.1.1 ({latest}):
  - Added waiting room
  - Now uses LogHandler for logging

  0.1.0.2 ({f043127}):
  - Moved assets to KLILib

  0.1.0.1 ({3cdc768}):
  - KLIClient is static again
  - KLIClient holds clientID
  
  0.1 ({3fbfae0}):
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
