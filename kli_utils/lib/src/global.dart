import 'dart:async';

import 'global_export.dart';

final logMessageController = StreamController<MapEntry<LogType, String>>.broadcast();
