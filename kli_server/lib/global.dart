import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

late final Logger logger;

void initLogger() {
  logger = Logger(printer: SimplePrinter());
}

late final PackageInfo packageInfo;
void initPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
}
