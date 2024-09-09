import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';

bool isTesting = kDebugMode, showDebugInfo = false;
DecorationImage? bgDecorationImage;
final buildDate = DateTime(2024, 9, 9);

late void Function() updateDebugOverlay;
late void Function() updateChild;

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
  audioHandler = AudioHandler.init(updateDebugOverlay);
}

String getSizeString(double bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  int unitIndex = 0;
  while (bytes > 900 && unitIndex < units.length - 1) {
    bytes /= 1024;
    unitIndex++;
  }
  return '${bytes.toStringAsFixed(2)} ${units[unitIndex]}';
}

const String changelog = """
  0.3.1 ({latest}):
  - Added viewer obstacle screens: question (like start), image, rows
  - Viewer wait screen says waiting before match
  - Now logs cache path when loading app
  - Now stores match name

  0.3 ({678b43e}):
  - Added viewer wait screen: used between sections
  - Added viewer start screen: transparent background, players, question, scores

  0.2.5.4 ({aa99930}):
  - Added Debug overlay: version, build date, test mode, ip, port, clientID, receiving data...
  - Fixed not listening to onDisconnected more than once

  0.2.5.3 ({085715f}):
  - Reworked connect screen: no longer need to re-enter id to reconnect

  0.2.5.2 ({cf809e4}):
  - Fixed can guess obstacle before first question
  - Fixed obstacle screen top "padding"
  - Highlights who signaled to steal finish answer in yellow
  - Added button to signal answer in extra
  - Doesn't create cache note if already exists
  - Enables quiting if match ended (received endMatch message)

  0.2.5.1 ({463fdf9}):
  - Fixed not showing match data received progress if missed cache
  - Fixed progress percentage is duplicated instead of multiplied
  - Players will only request player data, viewer & mc (?) will request match data (reduces wait time)
  - Reorganized waiting screen code
  - Separated match data cache from player data cache (match/player and match/other). Player folder will only
    contain player data, match folder will contain all match's image data and player data
  - Better waiting screen progress message
  - Fixed invalid url when opening app folder

  0.2.5 ({aeaa769}):
  - Added Extra screen: question, timer
  - Fixed not sending ready if MatchData is already initialized when switching to Overview
  - Added cache manager: view cached match, size, open, delete

  0.2.4 ({e8abe73}):
  - Added Finish screen: question, score, steal, timer
  - Fixed UI exception when checking cached match data
  - Some question info (e.g. question number, subject) now shows in the corner instead
  - Send playerReady before switching to Overview, Overview init requests scores, section name
  - Re-aligned Overview screen to match Server's
  - Shows player names & scores in section screens instead of question info

  0.2.3 ({79f968c}):
  - Added Accel screen: question, score, can answer
  - Caches all match data: images, video, names; will take cached if hit

  0.2.2 ({363f0c6}):
  - Added Obstacle screen: question, score, can guess, answer
  - Some errors show a popup message
  - Some routes are replaced
  - Global error handling using PlatformDispatcher, widget error screen now show stack, can turn back
  - Fixed cut error title

  0.2.1 ({cfc575a}):
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
