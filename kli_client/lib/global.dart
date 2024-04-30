import 'package:kli_lib/kli_lib.dart';
import 'package:logger/logger.dart';

late final Logger logger;
void initLogger() {
  logger = Logger(printer: SimplePrinter());
}

late final KLIClient kliClient;
Future<void> initClient(String ip, String clientID, [int port = 8080]) async {
  kliClient = await KLIClient.init(ip, clientID, port);
}
