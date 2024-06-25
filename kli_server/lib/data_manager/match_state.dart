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
    if (_inst != null && _inst!.match.name == matchName) return;

    final value = await storageHandler.readFromFile(storageHandler.matchSaveFile);

    final newMatch = KLIMatch.fromJson((jsonDecode(value) as Iterable).firstWhere(
      (e) => e['name'] == matchName,
      orElse: () => throw Exception('Match not found'),
    ));

    _inst = MatchState._(newMatch);
    if (_inst!.section == MatchSection.obstacle) {
      _inst!.imagePartOrder.shuffle();
      _inst!.imagePartOrder.add(4);
    }
  }

  static void reset() => _inst = null;
  static bool get initialized => _inst != null;

  MatchState._(this.match) {
    players = match.playerList.map((e) => e!).toList();
  }

  void nextSection() {
    if (section == MatchSection.extra) return;

    section = MatchSection.values[(section.index + 1)];
  }

  Future<void> loadQuestions() async {
    switch (section) {
      case MatchSection.start:
        questionList = (await DataManager.getMatchQuestions<StartMatch>(match.name))
            .questions
            .where((e) => e.pos == startOrFinishPos + 1)
            .toList()
            .reversed
            .toList();
        break;
      case MatchSection.obstacle:
        questionList = null;
        obstacleMatch = await DataManager.getMatchQuestions<ObstacleMatch>(match.name);
        break;
      case MatchSection.accel:
        obstacleMatch = null;
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
    switch (section) {
      case MatchSection.start:
        startOrFinishPos++;
        break;
      case MatchSection.obstacle: // none, all player at once
        break;
      case MatchSection.accel: // none, all player at once
        break;
      case MatchSection.finish:
        if (finishPlayerDone.every((e) => !e)) {
          startOrFinishPos = (<int>[0, 1, 2, 3]..sort((a, b) => scores[b].compareTo(scores[a])))[0];
          finishPlayerDone[startOrFinishPos] = true;
        } else {
          final nonFinishedPlayers = List<int>.generate(4, (i) => i)
              .where((pos) => !finishPlayerDone[pos]) //
              .toList()
            ..sort((a, b) => scores[b].compareTo(scores[a]));

          if (nonFinishedPlayers.length == 1) {
            startOrFinishPos = nonFinishedPlayers[0];
          } else if (scores[nonFinishedPlayers[0]] == scores[nonFinishedPlayers[1]]) {
            startOrFinishPos = nonFinishedPlayers[0] < nonFinishedPlayers[1]
                ? nonFinishedPlayers[0] //
                : nonFinishedPlayers[1];
          }

          startOrFinishPos = nonFinishedPlayers[0];
          finishPlayerDone[startOrFinishPos] = true;
        }
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
  // static void setUnlockedPart(int index) => _inst?.revealedObstacleRows[index] = true;

  // These are instance variables
  late final KLIMatch match;
  final scores = <int>[0, 0, 0, 0];
  late final List<KLIPlayer> players;
  MatchSection section = MatchSection.obstacle;

  /// For Start, Accel, Finish, Extra. For Obstacle, use [obstacleMatch]
  List<BaseQuestion>? questionList;
  ObstacleMatch? obstacleMatch;

  int startOrFinishPos = 0;
  final finishPlayerDone = <bool>[false, false, false, false];
  late final List<int> finishOrder;

  final revealedObstacleRows = <bool>[false, false, false, false, false];
  final answeredObstacleRows = <bool>[false, false, false, false, false];
  late final List<int> imagePartOrder = <int>[0, 1, 2, 3];
  final revealedImageParts = <bool>[false, false, false, false, false];
}
