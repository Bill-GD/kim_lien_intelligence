import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

late final Logger logger;
void initLogger(String logPath) {
  logger = Logger(
    printer: SimplePrinter(colors: false, printTime: true),
    filter: AlwaysLogFilter(),
    output: FileOutput(file: File(storageHandler!.logFile), overrideExisting: true),
  );
  logger.i('Logger init');
}

late final PackageInfo packageInfo;
Future<void> initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  logger.i('PackageInfo init');
}

StorageHandler? storageHandler;
Future<void> initStorageHandler() async {
  if (storageHandler != null) return;

  final rawDir = Platform.resolvedExecutable.split(Platform.executable).first;
  String parentFolder = rawDir.substring(0, rawDir.length - 1).replaceAll('\\', '/');

  storageHandler = await StorageHandler.init(parentFolder);
}

Future<List<String>> getMatchNames() async {
  List<String> matchNames = [];
  String value = await storageHandler!.readFromFile(storageHandler!.matchSaveFile);
  if (value.isNotEmpty) {
    matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
  }
  return matchNames;
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

/// A custom ListTile with variable column count and an optional delete button.
///
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

class DataManager {
  static Future<List<T>> getAllSavedQuestions<T extends BaseMatch>(
    T Function(Map<String, dynamic>) func,
    String filePath,
  ) async {
    logger.i('Getting all saved $T questions');
    final saved = await storageHandler!.readFromFile(filePath);
    if (saved.isEmpty) return <T>[];
    List<T> q = [];
    try {
      q = (jsonDecode(saved) as List).map((e) => func(e)).toList();
    } on Exception catch (e, stack) {
      logger.e(e, stackTrace: stack);
    }
    return q;
  }

  static Future<void> updateAllQuestionMatchName({required String oldName, required String newName}) async {
    logger
        .i('Match name update detected. Updating match name of all questions (\'$oldName\' -> \'$newName\')');

    List<(Type, String)> typeToFileMap = [
      (StartMatch, storageHandler!.startSaveFile),
      (ObstacleMatch, storageHandler!.obstacleSaveFile),
      (AccelMatch, storageHandler!.accelSaveFile),
      (FinishMatch, storageHandler!.finishSaveFile),
      (ExtraMatch, storageHandler!.extraSaveFile),
    ];

    for (final (type, file) in typeToFileMap) {
      List<BaseMatch> q = [];
      if (type == StartMatch) {
        q = await getAllSavedQuestions<StartMatch>(StartMatch.fromJson, file);
      } else if (type == ObstacleMatch) {
        q = await getAllSavedQuestions<ObstacleMatch>(ObstacleMatch.fromJson, file);
      } else if (type == AccelMatch) {
        q = await getAllSavedQuestions<AccelMatch>(AccelMatch.fromJson, file);
      } else if (type == FinishMatch) {
        q = await getAllSavedQuestions<FinishMatch>(FinishMatch.fromJson, file);
      } else if (type == ExtraMatch) {
        q = await getAllSavedQuestions<ExtraMatch>(ExtraMatch.fromJson, file);
      }
      for (var e in q) {
        if (e.match == oldName) e.match = newName;
      }
      await overwriteSave(q, file);
      logger.i('$type: Done');
    }
  }

  static Future<void> overwriteSave<T>(List<T> q, String filePath) async {
    logger.i('Overwriting save');
    await storageHandler!.writeToFile(filePath, jsonEncode(q));
  }
}

String changelog = """
  0.3 ({latest}):
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
  - Added logger: logs to console
  - Added basic start screen: side navigation, app version
  - Added storage handler: read excel, write to file
  - Force fullscreen on launch

  0.0.1.x ({d9628a9}):
  - Initial version -> setup workspace
  - Added basic server setup & server-client connection""";
