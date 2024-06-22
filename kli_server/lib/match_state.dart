import 'dart:convert';

import 'package:kli_lib/kli_lib.dart';

import 'global.dart';

/// A static class to save a state of the current match. Contains match name, current scores, current section, and current question.<br>
/// Server will select required info to send to clients when needed.
class MatchState {
  static MatchState? _inst;

  /// Get the current match state instance. Will throw if not exists.
  static MatchState get instance {
    assert(_inst != null, 'MatchState not initialized');
    return _inst!;
  }

  /// Takes `matchName`. If initialized, does nothing.
  static void instantiate(String matchName) => _inst ??= MatchState._(matchName);

  static void reset() => _inst = null;

  MatchState._(String matchName) {
    storageHandler.readFromFile(storageHandler.matchSaveFile).then((value) {
      if (value.isEmpty) return;

      match = (jsonDecode(value) as Iterable)
          .firstWhere((e) => e['name'] == matchName, orElse: () => throw Exception('Match not found'))
          .map((e) => KLIMatch.fromJson(e));
      players = match.playerList.map((e) => e!).toList();
    });
  }

  void nextSection() {
    if (_inst == null) throw Exception('Match state not initialized');

    if (currentSection == MatchSection.extra) return;

    currentSection = MatchSection.values[(currentSection.index + 1)];
    currentQuestion = null;
  }

  /// When unlocking part, select random 0..3, only unlock if not already unlocked, then set to true
  static void setUnlockedPart(int index) => _inst?.unlockedObstacleParts[index] = true;

  // These are instance variables
  late final KLIMatch match;
  final scores = <int>[0, 0, 0, 0];
  late final List<KLIPlayer> players;
  MatchSection currentSection = MatchSection.none;
  BaseQuestion? currentQuestion;

  final unlockedObstacleParts = List<bool>.filled(5, false);
}
