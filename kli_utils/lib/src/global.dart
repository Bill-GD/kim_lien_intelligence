import 'dart:async';

import 'global_export.dart';

final logMessageController = StreamController<(LogType, String)>.broadcast();
