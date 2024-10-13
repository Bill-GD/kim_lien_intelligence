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

  static void prepareMatchData(String matchDataPath, String playerDataPath) {
    if (!initialized) return;
    logHandler.info('Preparing match data');

    final fm = File(matchDataPath), fp = File(playerDataPath);
    DataSize.matchActualDataSize = 0;
    DataSize.playerActualDataSize = 0;

    final md = <String, dynamic>{}, pd = <String, dynamic>{};

    for (int i = 0; i < MatchState().players.length; i++) {
      final p = MatchState().players[i];
      final ext = p.imagePath.split('.').last;

      md['pn_$i'] = pd['pn_$i'] = p.name;
      md['pi_$i.$ext'] = pd['pi_$i.$ext'] = Networking.encodeMedia(p.imagePath);

      DataSize.playerActualDataSize += FileStat.statSync(StorageHandler.getFullPath(p.imagePath)).size;
      DataSize.matchActualDataSize += FileStat.statSync(StorageHandler.getFullPath(p.imagePath)).size;
    }

    final pm = String.fromCharCodes(zlib.encode(jsonEncode(pd).codeUnits));
    // final pm = jsonEncode(pd);
    DataSize.playerMessageSize = KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.playerData,
      message: pm,
      // message: String.fromCharCodes(zlib.encode(pm.codeUnits)),
    ).encode().codeUnits.length;
    fp.writeAsStringSync(pm);
    logHandler.info('Player data done');

    final obsPath = DataManager.getMatchQuestions<ObstacleMatch>(MatchState().match.name).imagePath;
    md['oi.${obsPath.split('.').last}'] = Networking.encodeMedia(obsPath);
    DataSize.matchActualDataSize += FileStat.statSync(StorageHandler.getFullPath(obsPath)).size;
    pd.clear();

    for (final i in range(0, 3)) {
      final q = DataManager.getMatchQuestions<AccelMatch>(MatchState().match.name).questions[i];
      for (final j in range(0, q.imagePaths.length - 1)) {
        final ext = q.imagePaths[j].split('.').last;
        md['ai_${i}_$j.$ext'] = Networking.encodeMedia(q.imagePaths[j]);
        DataSize.matchActualDataSize += FileStat.statSync(StorageHandler.getFullPath(q.imagePaths[j])).size;
      }
    }

    DataManager.getMatchQuestions<FinishMatch>(MatchState().match.name).questions.forEach((q) {
      if (q.mediaPath.isEmpty) return;
      if (md.containsKey('f_${q.mediaPath.split(r'\').last}')) return;

      md['f_${q.mediaPath.split(r'\').last}'] = Networking.encodeMedia(q.mediaPath);
      DataSize.matchActualDataSize += FileStat.statSync(StorageHandler.getFullPath(q.mediaPath)).size;
    });

    // final mm = jsonEncode(md);
    final mm = String.fromCharCodes(zlib.encode(jsonEncode(md).codeUnits));
    DataSize.matchMessageSize = KLISocketMessage(
      senderID: ConnectionID.host,
      type: KLIMessageType.matchData,
      message: mm,
      // message: String.fromCharCodes(zlib.encode(mm.codeUnits)),
    ).encode().codeUnits.length;
    fm.writeAsStringSync(mm);
    logHandler.info('Match data done');
  }

  static void sendPlayerData(ConnectionID id, bool sendData, String playerDataPath) {
    assert(initialized, 'MatchState not initialized');
    if (sendData) {
      final msg = File(playerDataPath).readAsStringSync();

      KLIServer.sendMessage(
        id,
        KLISocketMessage(
          senderID: ConnectionID.host,
          type: KLIMessageType.playerData,
          message: msg,
          // message: String.fromCharCodes(zlib.encode(msg.codeUnits)),
        ),
      );
      return;
    }
    KLIServer.sendMessage(
      id,
      KLISocketMessage(
        senderID: ConnectionID.host,
        type: KLIMessageType.dataSize,
        message: '${DataSize.playerMessageSize}|${DataSize.playerActualDataSize}',
      ),
    );
  }

  static void sendMatchData(ConnectionID id, bool sendData, String matchDataPath) {
    assert(initialized, 'MatchState not initialized');
    if (sendData) {
      final msg = File(matchDataPath).readAsStringSync();

      KLIServer.sendMessage(
        id,
        KLISocketMessage(
          senderID: ConnectionID.host,
          type: KLIMessageType.matchData,
          message: msg,
          // message: String.fromCharCodes(zlib.encode(msg.codeUnits)),
        ),
      );
      return;
    }
    KLIServer.sendMessage(
      id,
      KLISocketMessage(
        senderID: ConnectionID.host,
        type: KLIMessageType.dataSize,
        message: '${DataSize.matchMessageSize}|${DataSize.matchActualDataSize}',
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
        questionList = DataManager.getMatchQuestions<StartMatch>(match.name) //
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
  MatchSection section = MatchSection.start;

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
