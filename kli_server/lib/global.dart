import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:side_navigation/side_navigation.dart';

bool useDefaultBackground = false;
DecorationImage? bgWidget;

late final LogHandler logHandler;
void initLogHandler() {
  final rawDir = Platform.resolvedExecutable.split(Platform.executable).first;
  logHandler = LogHandler(logFile: '$rawDir\\UserData\\log.txt');
}

late final PackageInfo packageInfo;
Future<void> initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  logHandler.info('PackageInfo init: v${packageInfo.version}.${packageInfo.buildNumber}');
}

late final StorageHandler storageHandler;
Future<void> initStorageHandler() async {
  final rawDir = Platform.resolvedExecutable.split(Platform.executable).first;
  storageHandler = await StorageHandler.init(rawDir);
}

AppBar managerAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    backgroundColor: Colors.transparent,
    surfaceTintColor: Theme.of(context).colorScheme.background,
    automaticallyImplyLeading: false,
    titleTextStyle: const TextStyle(fontSize: fontSizeXL),
    centerTitle: true,
    toolbarHeight: kToolbarHeight * 1.1,
  );
}

Widget matchSelector(List<String> matchNames, void Function(String?) onSelected) {
  return DropdownMenu(
    label: const Text('Trận đấu'),
    dropdownMenuEntries: [
      for (var i = 0; i < matchNames.length; i++)
        DropdownMenuEntry(
          value: matchNames[i],
          label: matchNames[i],
        )
    ],
    onSelected: onSelected,
  );
}

/// A custom ListTile with variable column count and an optional delete button.<br>
/// The columns are defined by a pair/record ```(content: Widget, widthRatio: double)```.
Widget customListTile(
  BuildContext context, {
  required List<(Widget, double)> columns,
  void Function()? onTap,
}) {
  return MouseRegion(
    cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 24, top: 24, bottom: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (child, ratio) in columns)
              SizedBox(
                width: MediaQuery.of(context).size.width * ratio.clamp(0, 1),
                child: child is Text ? _applyFontSize(child) : child,
              ),
          ],
        ),
      ),
    ),
  );
}

Text _applyFontSize(Text t) {
  return Text('${t.data}', textAlign: t.textAlign, style: const TextStyle(fontSize: fontSizeMedium));
}

SideNavigationBarTheme sideNavigationTheme(BuildContext context, [double height = 2]) {
  return SideNavigationBarTheme(
    itemTheme: SideNavigationBarItemTheme(
      selectedItemColor: Theme.of(context).colorScheme.primary,
      labelTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeMSmall, height: height),
    ),
    togglerTheme: SideNavigationBarTogglerTheme.standard(),
    dividerTheme: const SideNavigationBarDividerTheme(
      showHeaderDivider: true,
      headerDividerColor: Color(0x64FFFFFF),
      showMainDivider: true,
      showFooterDivider: false,
    ),
  );
}

class DataManager {
  static String _mapTypeToFile(Type type) {
    if (type == StartMatch) return storageHandler.startSaveFile;
    if (type == ObstacleMatch) return storageHandler.obstacleSaveFile;
    if (type == AccelMatch) return storageHandler.accelSaveFile;
    if (type == FinishMatch) return storageHandler.finishSaveFile;
    if (type == ExtraMatch) return storageHandler.extraSaveFile;
    throw Exception('Unknown type');
  }

  static Future<List<T>> getAllSavedQuestions<T extends BaseMatch>() async {
    logHandler.info('Getting all saved $T questions');
    final saved = await storageHandler.readFromFile(_mapTypeToFile(T));
    if (saved.isEmpty) return <T>[];

    List<T> q = [];
    try {
      q = (jsonDecode(saved) as List).map((j) => BaseMatch.fromJson<T>(j)).toList();
    } on Exception catch (e, stack) {
      logHandler.error('$e', stackTrace: stack);
    }
    return q;
  }

  static Future<void> updateQuestions<T extends BaseMatch>(T match) async {
    logHandler.info('Updating questions of match: ${match.matchName}', d: 3);
    final saved = await getAllSavedQuestions<T>();
    saved.removeWhere((e) => e.matchName == match.matchName);
    saved.add(match);
    await overwriteSave(saved, _mapTypeToFile(T));
  }

  static Future<void> updateAllQuestionMatchName({required String oldName, required String newName}) async {
    logHandler.info(
      'Match name update detected. Updating match name of all questions (\'$oldName\' -> \'$newName\')',
      d: 1,
    );

    List<Type> types = [StartMatch, ObstacleMatch, AccelMatch, FinishMatch, ExtraMatch];

    for (final type in types) {
      List<BaseMatch> m = switch (type) {
        StartMatch => await getAllSavedQuestions<StartMatch>(),
        ObstacleMatch => await getAllSavedQuestions<ObstacleMatch>(),
        AccelMatch => await getAllSavedQuestions<AccelMatch>(),
        FinishMatch => await getAllSavedQuestions<FinishMatch>(),
        ExtraMatch => await getAllSavedQuestions<ExtraMatch>(),
        _ => throw Exception('Unknown type'),
      };

      for (final e in m) {
        if (e.matchName == oldName) e.matchName = newName;
      }
      await overwriteSave(m, _mapTypeToFile(type));
      logHandler.info('Updated $type');
    }
  }

  static Future<List<String>> getMatchNames() async {
    List<String> matchNames = [];
    String value = await storageHandler.readFromFile(storageHandler.matchSaveFile);
    if (value.isNotEmpty) {
      matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
    }
    return matchNames;
  }

  static Future<void> saveNewQuestions<T extends BaseMatch>(T selectedMatch) async {
    logHandler.info('Saving new questions of match: ${selectedMatch.matchName}', d: 3);
    final saved = await getAllSavedQuestions<T>();
    saved.removeWhere((e) => e.matchName == selectedMatch.matchName);
    saved.add(selectedMatch);
    await overwriteSave(saved, _mapTypeToFile(T));
  }

  static Future<void> removeDeletedMatchQuestions<T extends BaseMatch>() async {
    logHandler.info('Removing questions of deleted matches', d: 3);
    final matchNames = await getMatchNames();
    final saved =
        (await getAllSavedQuestions<T>()).where((e) => matchNames.contains(e.matchName)).toList();
    await overwriteSave(saved, _mapTypeToFile(T));
  }

  static Future<void> removeQuestionsOfMatch<T extends BaseMatch>(T match) async {
    logHandler.info('Removing all questions of match: ${match.matchName}', d: 3);
    final saved = (await getAllSavedQuestions<T>())
      ..removeWhere((e) => e.matchName == match.matchName);
    await overwriteSave(saved, _mapTypeToFile(T));
  }

  static Future<T> getMatchQuestions<T extends BaseMatch>(String matchName) async {
    final saved = await DataManager.getAllSavedQuestions<T>();
    if (saved.isEmpty) return BaseMatch.empty<T>(matchName);

    T selectedMatch;

    try {
      selectedMatch = saved.firstWhere((e) => e.matchName == matchName);
      logHandler.info("Loaded questions of $T named '$matchName'", d: 2);
    } on StateError {
      logHandler.info("$T named '$matchName' not found, temp empty match created");
      selectedMatch = BaseMatch.empty<T>(matchName);
    }
    return selectedMatch;
  }

  static Future<void> overwriteSave<T>(List<T> q, String filePath) async {
    logHandler.info('Overwriting save');
    await storageHandler.writeToFile(filePath, jsonEncode(q));
  }
}

String changelog = """
  0.3.2.1 ({latest}):
  - Updated KLI Lib to 0.4
  - Extracted repeating manager methods to generics
  
  0.3.2 ({c2fb3d0}):
  - Added Loading screen
  - Can now delete shared background
  - Fixed client list wrong IP and port
  - Fixed more log messages

  0.3.1.3 ({aa2a188}):
  - Now uses LogHandler for logging
  - Logs version on launch
  - Better log messages & nested log
  - Added background manager
  - Uses shared background hosted online, else default background
  - Better client list in Server Setup

  0.3.1.2 ({e50b469}):
  - Disabled light theme (like who need this anyway)
  - Use less theme colors
  - Can use 'Esc' to quickly exit page
  - Fixed background images is a little dim
  - Added Start match button after all player joined

  0.3.1.1 ({8541f82}):
  - Assets moved to KLILib
  - Added more tooltips to buttons
  - Better data checker error for start question display
  - Added iconButton custom widget (similar to other buttons)
  - Checks Accel image errors better

  0.3.1 ({8e8f615}):
  - Renamed data manager pages
  - Match data checker page: check if all info are good, show errors if not

  0.3 ({3fbfae0}):
  - Improved Server Setup UI
  - Fixed stream controller not re-opened after restarting server
  - Added disconnect message type
  - Can no longer start/stop server when there is/isn't a running server
  - Reworked Client ID
  - Can disconnect individual client
  - Disconnect all clients when stopping server

  0.2.8.3 ({47176ce}):
  - Added changelog & changelog view in app
  - Changed help screen layout to avoid overflow on launch
  - Added 'Licenses' button in changelog

  0.2.8.2 ({8491f11}):
  - Trim all text input fields
  - Import preview line spacing
  - Named parameters consistency

  0.2.8.1 ({c858fb4}):
  - Changed all save files to json
  - Notify on errors where applicable

  0.2.8 ({f06065d}):
  - Added preview window for importing data -> can check for errors in data
  - Added obstacle editor (NOT obstacle QUESTION editor)

  0.2.7.1 ({dc7ecea}):
  - Only enable editor 'Done' when all required fields is filled
  - Fixed changing match name delete all of its saved questions

  0.2.7 ({f41ab9c}):
  - Added "localization"
  - Added accel question type
  - Better confirm dialog

  0.2.6.3 ({34330ac}):
  - Added confirm dialog when deleting questions
  - Backend changes: early returns, save files structure
  - Shortened some messages
  - Log message has time
  - Button to open app folder, instruction file, log file

  0.2.6.2 ({7096e17}):
  - Generics for question managers
  - New background image
  - Ensure window only show after forced fullscreen
  - Added exit button in start screen

  0.2.6.1 ({4e00f85}):
  - Help screen is first/default page in start screen

  0.2.6 ({6b65e46}):
  - Added help screen
  - Storage handler excel reader: limit sheet count
  
  0.2.5 ({119b134}):
  - Added feature to add singular start question
  - Fixed manager bug related to nullable
  - Added acceleration question manager
  - Minor fixes: match manager background, can't add start question, wrong log messages

  0.2.4 ({e155b1c}):
  - Better seekbar for finish question video
  - Notify if media file isn't found at specified path
  - Extra question manager
  - Changed sdk lower bound: 2.19.6 -> 3.0 (record/pattern)
  - Better custom list tile for question lists

  0.2.3 ({2cb1ac7}):
  - Finish question video rework: change lib, can remove
  - Output log in release build
  - Updated data manager background

  0.2.2 ({2eea3c9}):
  - Wrap Start questions in a match
  - Log output to file, even from kli_lib
  - Added finish question manager
  - Change log file location

  0.2.1 ({5f21bdf}):
  - Obstacle question manager: wrap questions in a match

  0.2 ({e8fc93f}):
  - Added Match manager: match name, players
  - Added Start question manager: question list, add/edit/remove
  - App theme, icon
  - Better storage handler: init folders/files, read/write file

  0.1.x ({333b4f3}):
  - Added basic messaging (with utf8)
  - Basic setup for data manager: UI
  - Added LogHandler: logs to console
  - Added basic start screen: side navigation, app version
  - Added storage handler: read excel, write to file
  - Force fullscreen on launch

  0.0.1.x ({d9628a9}):
  - Initial version -> setup workspace
  - Added basic server setup & server-client connection""";
