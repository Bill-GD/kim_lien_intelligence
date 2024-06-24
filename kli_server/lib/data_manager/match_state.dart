import 'dart:convert';

import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import 'data_manager.dart';

enum MatchSection { intro, start, obstacle, accel, finish, extra }

/// A static class to save a state of the current match. Contains match name, current scores, current section, and current question.<br>
/// Server will select required info to send to clients when needed.
class MatchState {
  static MatchState? _inst;

  /// Get the current match state instance. Will throw if not exists.
  static MatchState get i {
    assert(_inst != null, 'MatchState not initialized');
    return _inst!;
  }

  /// Takes `matchName`. If initialized, does nothing.
  static Future<void> instantiate(String matchName) async {
    KLIMatch match;

    final value = await storageHandler.readFromFile(storageHandler.matchSaveFile);

    match = KLIMatch.fromJson((jsonDecode(value) as Iterable).firstWhere(
      (e) => e['name'] == matchName,
      orElse: () => throw Exception('Match not found'),
    ));

    if (_inst == null) {
      _inst = MatchState._(match);
      return;
    }
    if (_inst!.match.name != matchName) _inst = MatchState._(match);
  }

  static void reset() => _inst = null;
  static bool get initialized => _inst != null;

  MatchState._(this.match) {
    players = match.playerList.map((e) => e!).toList();
  }

  void nextSection() {
    if (currentSection == MatchSection.extra) return;

    currentSection = MatchSection.values[(currentSection.index + 1)];
  }

  Future<void> loadQuestions() async {
    switch (currentSection) {
      case MatchSection.start:
        currentQuestionList = (await DataManager.getMatchQuestions<StartMatch>(match.name))
            .questions
            .where((e) => e.pos == startPos + 1)
            .toList();
        break;
      case MatchSection.obstacle:
        currentQuestionList = null;
        currentObstacleMatch = await DataManager.getMatchQuestions<ObstacleMatch>(match.name);
        break;
      case MatchSection.accel:
        await DataManager.getMatchQuestions<AccelMatch>(match.name);
        break;
      case MatchSection.finish:
        await DataManager.getMatchQuestions<FinishMatch>(match.name);
        break;
      case MatchSection.extra:
        await DataManager.getMatchQuestions<ExtraMatch>(match.name);
        break;
      default:
        throw Exception('Invalid section, this should not happen.');
    }
  }

  void nextPlayer() {
    switch (currentSection) {
      case MatchSection.start:
        startPos++;
        break;
      case MatchSection.obstacle:
        break;
      case MatchSection.accel:
        break;
      case MatchSection.finish:
        break;
      case MatchSection.extra:
        break;
      default:
        throw Exception('Invalid section, this should not happen.');
    }
  }

  /// [score] can be negative.
  void modifyScore(int playerIndex, int score) => scores[playerIndex] += score;

  /// When unlocking part, select random 0..3, only unlock if not already unlocked, then set to true
  // static void setUnlockedPart(int index) => _inst?.unlockedObstacleParts[index] = true;

  // These are instance variables
  late final KLIMatch match;
  final scores = <int>[0, 0, 0, 0];
  late final List<KLIPlayer> players;
  MatchSection currentSection = MatchSection.start;

  /// For Start, Accel, Finish, Extra. FOr Obstacle, use [currentObstacleMatch]
  List<BaseQuestion>? currentQuestionList;
  ObstacleMatch? currentObstacleMatch;

  int startPos = -1;
  final unlockedObstacleParts = List<bool>.filled(5, false);
}
