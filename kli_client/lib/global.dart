import 'package:logger/logger.dart';

late final Logger logger;

void initLogger() {
  logger = Logger(printer: SimplePrinter());
}
