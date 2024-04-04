import 'dart:io';

import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

late final Logger logger;

void initLogger() {
  logger = Logger(printer: SimplePrinter());
  logger.i('Logger init');
}

late final PackageInfo packageInfo;
void initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  logger.i('PackageInfo init');
}

late final String parentFolder;
void initExePath() {
  final rawDir = Platform.resolvedExecutable.split(Platform.executable).first;
  parentFolder = rawDir.substring(0, rawDir.length - 1).replaceAll('\\', '/');
  logger.i('Parent folder path: $parentFolder');
}
