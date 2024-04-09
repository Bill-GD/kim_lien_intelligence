import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Filter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

late final Logger logger;
void initLogger(String logPath) {
  logger = Logger(
    printer: SimplePrinter(colors: false),
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

Widget button(BuildContext context, final String label,
    {required bool enableCondition, void Function()? onPressed}) {
  return OutlinedButton(
    style: ButtonStyle(
      backgroundColor: MaterialStatePropertyAll<Color>(Theme.of(context).colorScheme.background),
      padding: const MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(vertical: 25, horizontal: 15)),
    ),
    onPressed: enableCondition && onPressed != null ? onPressed : null,
    child: Text(label, style: const TextStyle(fontSize: fontSizeMedium)),
  );
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
    label: const Text('Match'),
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

Widget customListTile(
  BuildContext context,
  String col1,
  double width1,
  String col2,
  double width2,
  String col3,
  String col4,
  double width4, {
  bool bottomBorder = true,
  void Function()? onTap,
}) {
  return MouseRegion(
    cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(right: 24, top: 24, bottom: 24),
        decoration: bottomBorder
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
                ),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              constraints: BoxConstraints(minWidth: width1, maxWidth: width1),
              child: Text(
                col1,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: fontSizeMedium),
              ),
            ),
            Container(
              constraints: BoxConstraints(minWidth: width2, maxWidth: width2),
              child: Text(
                col2,
                // textAlign: TextAlign.center,
                style: const TextStyle(fontSize: fontSizeMedium),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  col3,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(minWidth: width4, maxWidth: width4),
              child: Text(
                col4,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: fontSizeMedium),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
