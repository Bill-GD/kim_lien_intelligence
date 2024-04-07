import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

late final Logger logger;
void initLogger(String logPath) {
  logger = Logger(
    printer: SimplePrinter(),
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

Widget button(BuildContext context, final String label, void Function()? onPressed) {
  return OutlinedButton(
    style: const ButtonStyle(
      padding: MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(vertical: 25, horizontal: 15)),
    ),
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(fontSize: fontSizeMedium)),
  );
}
