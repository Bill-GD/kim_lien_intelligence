import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

/// Save a state of the current match. Contains match name, current section, and current question.
class MatchState {
  static MatchState? _instance;

  MatchState._({required this.matchName});

  static void createInstance(String matchName) {
    _instance ??= MatchState._(matchName: matchName);
  }

  factory MatchState.instance() {
    if (_instance != null) return _instance!;

    logMessageController.add((LogType.error, "MatchState instance is null, call `createInstance` first"));
    throw Exception("MatchState instance is null, call `createInstance` first");
  }

  String matchName;
  MatchSection currentSection = MatchSection.none;
  StartQuestion? startQuestion;
  ObstacleQuestion? obstacleQuestion;
  AccelQuestion? accelQuestion;
  FinishQuestion? finishQuestion;
  ExtraQuestion? extraQuestion;

  Map<String, dynamic> toJson() => {
        'matchName': matchName,
        'currentSection': currentSection.name,
        'startQuestion': startQuestion?.toJson(),
        'obstacleQuestion': obstacleQuestion?.toJson(),
        'accelQuestion': accelQuestion?.toJson(),
        'finishQuestion': finishQuestion?.toJson(),
        'extraQuestion': extraQuestion?.toJson(),
      };

  static void fromJson(Map<String, dynamic> json) {
    _instance = MatchState._(matchName: json['matchName']);
    _instance!.currentSection = MatchSection.values.byName(json['currentSection']);
    _instance!.startQuestion = StartQuestion.fromJson(json['currentQuestion']);
    _instance!.obstacleQuestion = ObstacleQuestion.fromJson(json['obstacleQuestion']);
    _instance!.accelQuestion = AccelQuestion.fromJson(json['accelQuestion']);
    _instance!.finishQuestion = FinishQuestion.fromJson(json['finishQuestion']);
    _instance!.extraQuestion = ExtraQuestion.fromJson(json['extraQuestion']);
  }
}

enum MatchSection { none, intro, start, obstacle, accel, finish, extra }
