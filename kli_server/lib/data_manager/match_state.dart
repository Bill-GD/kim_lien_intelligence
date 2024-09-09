import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import 'data_manager.dart';

enum MatchSection { start, obstacle, accel, finish, extra }

/// A static class to save a state of the current match. Contains match name, current scores, current section, and current question.<br>
/// Server will select required info to send to clients when needed.
class MatchState {
  static MatchState? _inst;
  static bool get initialized => _inst != null;

  /// Get the current match state instance. Will throw if not exists.
  factory MatchState() {
    assert(_inst != null, 'MatchState not initialized');
    return _inst!;
  }

  MatchState._internal(this.match) {
    players = match.playerList.map((e) => e!).toList();
  }

  /// Takes `matchName`. If initialized, does nothing.
  static void instantiate(String matchName) {
    if (_inst != null && _inst!.match.name == matchName) return;

    final value = storageHandler.readFromFile(storageHandler.matchSaveFile);

    final newMatch = KLIMatch.fromJson((jsonDecode(value) as Iterable).firstWhere(
      (e) => e['name'] == matchName,
      orElse: () => throw Exception('Match not found'),
    ));

    _inst = MatchState._internal(newMatch);
    _inst!.imagePartOrder.shuffle();
    _inst!.imagePartOrder.add(4);
    logHandler.empty();
    logHandler.info('Match initialized');
  }

  static void reset() => _inst = null;

  static void sendPlayerData(ConnectionID id, bool sendData) {
    assert(initialized, 'MatchState not initialized');
    int actualDataSize = 0;

    final data = <String, dynamic>{};

    for (int i = 0; i < MatchState().players.length; i++) {
      final p = MatchState().players[i];
      final ext = p.imagePath.split('.').last;
      data['player_name_$i'] = p.name;
      data['player_image_$i.$ext'] = Networking.encodeMedia(p.imagePath);
      actualDataSize += FileStat.statSync(StorageHandler.getFullPath(p.imagePath)).size;
    }

    final msg = KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.playerData,
      message: String.fromCharCodes(zlib.encode(jsonEncode(data).codeUnits)),
    );

    sendData
        ? KLIServer.sendMessage(id, msg)
        : KLIServer.sendMessage(
            id,
            KLISocketMessage(
              senderID: ConnectionID.host,
              type: KLIMessageType.dataSize,
              message: '${(msg.encode() + Networking.eom).codeUnits.length}|$actualDataSize',
            ),
          );
  }

  static void sendMatchData(ConnectionID id, bool sendData) {
    assert(initialized, 'MatchState not initialized');
    int actualDataSize = 0;

    final data = <String, dynamic>{};

    for (int i = 0; i < MatchState().players.length; i++) {
      final p = MatchState().players[i];
      final ext = p.imagePath.split('.').last;
      data['player_name_$i'] = p.name;
      data['player_image_$i.$ext'] = Networking.encodeMedia(p.imagePath);
      actualDataSize += FileStat.statSync(StorageHandler.getFullPath(p.imagePath)).size;
    }

    final obsPath = DataManager.getMatchQuestions<ObstacleMatch>(MatchState().match.name).imagePath;
    data['obstacle_image.${obsPath.split('.').last}'] = Networking.encodeMedia(obsPath);
    actualDataSize += FileStat.statSync(StorageHandler.getFullPath(obsPath)).size;

    for (final i in range(0, 3)) {
      final q = DataManager.getMatchQuestions<AccelMatch>(MatchState().match.name).questions[i];
      for (final j in range(0, q.imagePaths.length - 1)) {
        final ext = q.imagePaths[j].split('.').last;
        data['accel_image_${i}_$j.$ext'] = Networking.encodeMedia(q.imagePaths[j]);
        actualDataSize += FileStat.statSync(StorageHandler.getFullPath(q.imagePaths[j])).size;
      }
    }

    DataManager.getMatchQuestions<FinishMatch>(MatchState().match.name).questions.forEach((q) {
      if (q.mediaPath.isEmpty) return;
      final ext = q.mediaPath.split('.').last;
      data['finish_${q.mediaPath.split(r'\').last}.$ext'] = Networking.encodeMedia(q.mediaPath);
      actualDataSize += FileStat.statSync(StorageHandler.getFullPath(q.mediaPath)).size;
    });

    final msg = KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.matchData,
      message: String.fromCharCodes(zlib.encode(jsonEncode(data).codeUnits)),
    );

    sendData
        ? KLIServer.sendMessage(id, msg)
        : KLIServer.sendMessage(
            id,
            KLISocketMessage(
              senderID: ConnectionID.host,
              type: KLIMessageType.dataSize,
              message: '${(msg.encode() + Networking.eom).codeUnits.length}|$actualDataSize',
            ),
          );
  }

  void nextSection() {
    if (section == MatchSection.extra) return;

    section = MatchSection.values[(section.index + 1)];

    KLIServer.sendToAllClients(KLISocketMessage(
      senderID: ConnectionID.host,
      message: sectionDisplay(section),
      type: KLIMessageType.section,
    ));
    updateDebugOverlay();
  }

  void loadQuestions() {
    switch (section) {
      case MatchSection.start:
        questionList = DataManager.getMatchQuestions<StartMatch>(match.name)
            .questions
            .where((e) => e.pos == startOrFinishPos)
            .toList()
          ..shuffle();
        break;
      case MatchSection.obstacle:
        questionList = null;
        obstacleMatch = DataManager.getMatchQuestions<ObstacleMatch>(match.name);
        break;
      case MatchSection.accel:
        obstacleMatch = null;
        questionList = DataManager.getMatchQuestions<AccelMatch>(match.name).questions.reversed.toList();
        break;
      case MatchSection.finish:
        startOrFinishPos = 0;
        questionList = DataManager.getMatchQuestions<FinishMatch>(match.name).questions;
        break;
      case MatchSection.extra:
        questionList = DataManager.getMatchQuestions<ExtraMatch>(match.name).questions.reversed.toList();
        break;
      default:
        throw Exception('Invalid section, this should not happen.');
    }
  }

  /// Only for start, finish
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
        if (finishNotStarted) {
          startOrFinishPos = (<int>[0, 1, 2, 3]..sort((a, b) => scores[b].compareTo(scores[a])))[0];
          return;
        }

        final nonFinishedPlayers = <int>[0, 1, 2, 3]
            .where((pos) => !finishPlayerDone[pos]) //
            .toList()
          ..sort((a, b) => scores[b].compareTo(scores[a]));

        if (nonFinishedPlayers.length > 1 && scores[nonFinishedPlayers[0]] == scores[nonFinishedPlayers[1]]) {
          startOrFinishPos = min(nonFinishedPlayers[0], nonFinishedPlayers[1]);
        } else {
          startOrFinishPos = nonFinishedPlayers[0];
        }
        break;
      case MatchSection.extra: // all at once
        break;
      default:
        throw Exception('Invalid section, this should not happen.');
    }
  }

  String sectionDisplay(MatchSection section) {
    switch (section) {
      case MatchSection.start:
        return 'Khởi động';
      case MatchSection.obstacle:
        return 'Vượt chướng ngại vật';
      case MatchSection.accel:
        return 'Tăng tốc';
      case MatchSection.finish:
        return 'Về đích';
      case MatchSection.extra:
        return 'Câu hỏi phụ';
    }
  }

  /// [score] can be negative.
  void modifyScore(int idx, int score) {
    scores[idx] += score;
    if (scores[idx] < 0) scores[idx] = 0;
  }

  void eliminateObstaclePlayer(int pos) {
    eliminatedPlayers[pos] = true;
    KLIServer.sendToPlayer(
      pos,
      KLISocketMessage(senderID: ConnectionID.host, type: KLIMessageType.eliminated),
    );
  }

  // These are instance variables
  late final KLIMatch match;
  final scores = <int>[0, 0, 0, 0];
  final extraScores = <int>[0, 0, 0, 0];
  late final List<KLIPlayer> players;
  static final playerReady = <bool>[false, false, false, false];
  bool get allPlayerReady => playerReady.every((e) => e);
  MatchSection section = MatchSection.accel;

  /// For Start, Accel, Finish, Extra. For Obstacle, use [obstacleMatch]
  List<BaseQuestion>? questionList;
  ObstacleMatch? obstacleMatch;

  // start & finish
  int startOrFinishPos = 0;
  final finishPlayerDone = <bool>[false, false, false, false];
  bool get finishNotStarted => finishPlayerDone.every((e) => !e);
  bool get allFinishPlayerDone => finishPlayerDone.every((e) => e);

  // obstacle
  final revealedObstacleRows = <bool>[false, false, false, false, false];
  final answeredObstacleRows = <bool>[false, false, false, false, false];
  static const obstaclePoints = <int>[100, 80, 60, 40, 20, 10];
  late final List<int> imagePartOrder = <int>[0, 1, 2, 3];
  final List<String> rowAnswers = List.generate(4, (_) => '');
  final revealedImageParts = <bool>[false, false, false, false, false];
  bool get allRowsAnswered => answeredObstacleRows.take(4).every((e) => e);
  bool get allQuestionsAnswered => answeredObstacleRows.every((e) => e);
  final List<bool> eliminatedPlayers = <bool>[false, false, false, false];
}
