import 'dart:io';

import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

late final Logger logger;

void initLogger() {
  logger = Logger(printer: SimplePrinter());
  logger.i('Logger finished init');
}

late final PackageInfo packageInfo;
void initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  logger.i('PackageInfo finished init');
}

late final String parentFolder;
void initExePath() {
  parentFolder = Platform.resolvedExecutable.split(Platform.executable).first;
  logger.i('Parent folder path: $parentFolder');
}
