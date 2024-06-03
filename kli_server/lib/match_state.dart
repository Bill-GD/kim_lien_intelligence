import 'dart:convert';

import 'package:kli_lib/kli_lib.dart';

import 'global.dart';

/// Save a state of the current match. Contains match name, current scores, current section, and current question.<br>
/// Server will select required info to send to clients when needed.
class MatchState {
  static MatchState? _inst;

  /// Get the current match state instance.<br>
  /// Takes optional `matchName`, will be required if no instance exists and will throw.
  static MatchState instance([String? matchName]) {
    _inst ??= MatchState._(matchName);
    return _inst!;
  }

  static void reset() => _inst = null;

  MatchState._(String? matchName) {
    if (matchName == null) throw Exception('Match name is required');

    storageHandler.readFromFile(storageHandler.matchSaveFile).then((value) {
      if (value.isEmpty) return;

      match = (jsonDecode(value) as Iterable)
          .firstWhere((e) => e['name'] == matchName, orElse: () => throw Exception('Match not found'))
          .map((e) => KLIMatch.fromJson(e));
      players = match.playerList.map((e) => e!).toList();
    });
  }

  static void nextSection() {
    if (_inst == null) throw Exception('Match _inst not initialized');

    if (_inst!.currentSection == MatchSection.extra) return;

    _inst!.currentSection = MatchSection.values[(_inst!.currentSection.index + 1)];
    _inst!.startQuestion = null;
    _inst!.obstacleQuestion = null;
    _inst!.accelQuestion = null;
    _inst!.finishQuestion = null;
    _inst!.extraQuestion = null;
  }

  static void setUnlockedPart(int index) => _inst?.unlockedObstacleParts[index] = true;

  // Overall
  late final KLIMatch match;
  final scores = <int>[0, 0, 0, 0];
  late final List<KLIPlayer> players;
  MatchSection currentSection = MatchSection.none;

  StartQuestion? startQuestion;
  ObstacleQuestion? obstacleQuestion;
  AccelQuestion? accelQuestion;
  FinishQuestion? finishQuestion;
  ExtraQuestion? extraQuestion;

  /// When unlocking part, select random 0..3, only unlock if not already unlocked, then set to true
  final unlockedObstacleParts = List<bool>.filled(5, false);
}
