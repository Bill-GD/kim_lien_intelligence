import 'dart:convert';

import 'package:kli_lib/kli_lib.dart';

import 'global.dart';

/// Save a state of the current match. Contains match name, current scores, current section, and current question.<br>
/// Server will select required info to send to clients when needed.
class MatchState {
  static MatchState? _instance;

  /// Get the current match state instance.<br>
  /// Takes optional `matchName`, still required if no instance exists and will throw.
  static MatchState instance([String? matchName]) {
    _instance ??= MatchState._(matchName);
    return _instance!;
  }

  static void reset() => _instance = null;

  MatchState._([String? matchName]) {
    if (matchName == null) throw Exception('Match name is required');
    
    storageHandler.readFromFile(storageHandler.matchSaveFile).then((value) {
      if (value.isEmpty) return;

      match = (jsonDecode(value) as Iterable)
          .firstWhere((e) => e['name'] == matchName, orElse: () => throw Exception('Match not found'))
          .map((e) => KLIMatch.fromJson(e));
      players.addAll(match!.playerList as Iterable<KLIPlayer>);
    });
  }

  late final KLIMatch? match;
  final scores = <int>[0, 0, 0, 0];
  final players = <KLIPlayer>[];
  MatchSection currentSection = MatchSection.none;
  StartQuestion? startQuestion;
  ObstacleQuestion? obstacleQuestion;
  AccelQuestion? accelQuestion;
  FinishQuestion? finishQuestion;
  ExtraQuestion? extraQuestion;
}

enum MatchSection { none, intro, start, obstacle, accel, finish, extra }
