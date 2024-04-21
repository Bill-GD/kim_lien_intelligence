import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

TextEditingController? logPanelController;

class Filter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

late final Logger logger;
void initLogger(String logPath) {
  logger = Logger(
    printer: SimplePrinter(colors: false, printTime: true),
    filter: Filter(),
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

Widget button(
  BuildContext context,
  final String label, {
  double fontSize = fontSizeMedium,
  bool enableCondition = true,
  void Function()? onPressed,
  String disabledLabel = 'Disabled',
}) {
  final mainButton = OutlinedButton(
    style: ButtonStyle(
      backgroundColor: MaterialStatePropertyAll<Color>(Theme.of(context).colorScheme.background),
      padding: const MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(vertical: 20, horizontal: 15)),
    ),
    onPressed: enableCondition && onPressed != null ? onPressed : null,
    child: Text(label, style: TextStyle(fontSize: fontSize)),
  );

  return enableCondition && onPressed != null
      ? mainButton
      : Tooltip(message: disabledLabel, child: mainButton);
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
    logger.i('Getting all saved questions');
    final saved = await storageHandler!.readFromFile(filePath);
    if (saved.isEmpty) return <T>[];
    List<T> q = [];
    try {
      q = (jsonDecode(saved) as List).map((e) => func(e)).toList();
    } on Exception catch (e) {
      logger.e(e);
    }
    return q;
  }

  static Future<void> overwriteSave<T>(List<T> q, String filePath) async {
    logger.i('Overwriting save');
    await storageHandler!.writeToFile(filePath, jsonEncode(q));
  }
}
