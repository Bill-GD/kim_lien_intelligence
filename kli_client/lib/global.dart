import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';

DecorationImage? bgWidget;

late final LogHandler logHandler;
void initLogHandler() {
  logHandler = LogHandler(logFile: StorageHandler.getFullPath('log.txt'));
}

late final String appVersionString;
Future<void> initPackageInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  appVersionString = 'v${packageInfo.version}.${packageInfo.buildNumber}';
  logHandler.info('PackageInfo init: $appVersionString');
}

late final AssetHandler assetHandler;
void initAssetHandler() {
  assetHandler = AssetHandler.init();
}

late final AudioHandler audioHandler;
void initAudioHandler() {
  audioHandler = AudioHandler.init();
}

const String changelog = """
  0.2.1 ({latest}):
  - Fixed loading error scroll view overflows
  - Updated lower SDK to 3.0
  - Removed some unnecessary messages content
  - Fixed some Start screen issues: doesn't stop timer, too many setState calls
  - Now save PackageInfo (version) as string

  0.2 ({34c61cd}):
  - Added error message to loading screen
  - App is now always on top unless is in debug mode
  - Request player list from server, parses to Player objects
  - Added overview screen that shows players, highlight player if ready
  - Added start screen: question, score, subject, timer
  - Added a disconnect stream

  0.1.2.1 ({8b223b0}):
  - Updated KLI Lib to 0.4
  - Added 'feature' that allows user to manage background image and sounds
  
  0.1.2 ({c2fb3d0}):
  - Added Loading screen
  - Fixed client still listen to server after disconnect
  - Fixed UI not updating after getting connection error
  - Fixed some log messages
  
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
