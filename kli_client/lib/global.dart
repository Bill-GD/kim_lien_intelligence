import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';

bool useDefaultBackground = false;
DecorationImage? bgWidget;

late final LogHandler logHandler;
void initLogHandler() {
  final parentDir = Platform.resolvedExecutable.split(Platform.executable).first;
  logHandler = LogHandler(logFile: '$parentDir\\log.txt');
}

late final PackageInfo packageInfo;
Future<void> initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  logHandler.info('PackageInfo init: v${packageInfo.version}.${packageInfo.buildNumber}', d: 1);
}

String changelog = """
  0.1.2 ({ed509df}):
  - Added Loading screen
  
  0.1.1 ({aa2a188}):
  - Added waiting room
  - Now uses LogHandler for logging
  - Logs version on launch
  - Better log messages & nested log
  - Disabled light theme
  - Uses shared background hosted online, else default background

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
