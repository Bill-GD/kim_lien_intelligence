import 'dart:convert';

import 'package:kli_lib/kli_lib.dart';

import 'global.dart';

/// Save a state of the current match. Contains match name, current section, and current question.
///
/// Server will select required info to send to clients when needed.
class MatchState {
  static MatchState? _instance;

  static MatchState instance([String? matchName]) {
    _instance ??= MatchState._();
    return _instance!;
  }

  MatchState._([String? matchName]) {
    storageHandler.readFromFile(storageHandler.matchSaveFile).then((value) {
      if (value.isEmpty) return;

      match = (jsonDecode(value) as Iterable)
          .firstWhere((e) => e['name'] == matchName, orElse: () => throw Exception('Match not found'))
          .map((e) => KLIMatch.fromJson(e));
    });
  }

  KLIMatch? match;
  final scores = <int>[0, 0, 0, 0];
  MatchSection currentSection = MatchSection.none;
  StartQuestion? startQuestion;
  ObstacleQuestion? obstacleQuestion;
  AccelQuestion? accelQuestion;
  FinishQuestion? finishQuestion;
  ExtraQuestion? extraQuestion;
}

enum MatchSection { none, intro, start, obstacle, accel, finish, extra }
