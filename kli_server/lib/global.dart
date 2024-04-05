import 'dart:io';

import 'package:kli_utils/kli_utils.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

late final Logger logger;

void initLogger() {
  logger = Logger(printer: SimplePrinter());
  logger.i('Logger init');
}

late final PackageInfo packageInfo;
Future<void> initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  logger.i('PackageInfo init');
}

late final StorageHandler storageHandler;
Future<void> initStorageHandler() async {
  final rawDir = Platform.resolvedExecutable.split(Platform.executable).first;
  String parentFolder = rawDir.substring(0, rawDir.length - 1).replaceAll('\\', '/');
  logger.i('Parent folder path: $parentFolder');

  storageHandler = await StorageHandler.init(parentFolder);
}

// late final KLIServer kliServer;