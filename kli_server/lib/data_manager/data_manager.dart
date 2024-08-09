import 'dart:convert';

import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

class DataManager {
  static String _mapTypeToFile(Type type) {
    if (type == StartMatch) return storageHandler.startSaveFile;
    if (type == ObstacleMatch) return storageHandler.obstacleSaveFile;
    if (type == AccelMatch) return storageHandler.accelSaveFile;
    if (type == FinishMatch) return storageHandler.finishSaveFile;
    if (type == ExtraMatch) return storageHandler.extraSaveFile;
    throw Exception('Unknown type');
  }

  static List<T> getAllSavedQuestions<T extends BaseMatch>() {
    logHandler.info('Getting all saved $T questions');
    final saved = storageHandler.readFromFile(_mapTypeToFile(T));
    if (saved.isEmpty) return <T>[];

    List<T> q = [];
    try {
      q = (jsonDecode(saved) as List).map((j) => BaseMatch.fromJson<T>(j)).toList();
    } on Exception catch (e, stack) {
      logHandler.error('$e', stackTrace: stack);
    }
    return q;
  }

  static void updateQuestions<T extends BaseMatch>(T match) {
    logHandler.info('Updating questions of match: ${match.matchName}');
    final saved = getAllSavedQuestions<T>();
    saved.removeWhere((e) => e.matchName == match.matchName);
    saved.add(match);
    overwriteSave(saved, _mapTypeToFile(T));
  }

  static void updateAllQuestionMatchName({required String oldName, required String newName}) {
    logHandler.info(
      'Match name update detected. Updating match name of all questions (\'$oldName\' -> \'$newName\')',
    );

    List<Type> types = [StartMatch, ObstacleMatch, AccelMatch, FinishMatch, ExtraMatch];

    for (final type in types) {
      List<BaseMatch> m = switch (type) {
        StartMatch => getAllSavedQuestions<StartMatch>(),
        ObstacleMatch => getAllSavedQuestions<ObstacleMatch>(),
        AccelMatch => getAllSavedQuestions<AccelMatch>(),
        FinishMatch => getAllSavedQuestions<FinishMatch>(),
        ExtraMatch => getAllSavedQuestions<ExtraMatch>(),
        _ => throw Exception('Unknown type'),
      };

      for (final e in m) {
        if (e.matchName == oldName) e.matchName = newName;
      }
      overwriteSave(m, _mapTypeToFile(type));
      logHandler.info('Updated $type');
    }
  }

  static List<String> getMatchNames() {
    List<String> matchNames = [];
    String value = storageHandler.readFromFile(storageHandler.matchSaveFile);
    if (value.isNotEmpty) {
      matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
    }
    return matchNames;
  }

  static void saveNewQuestions<T extends BaseMatch>(T selectedMatch) {
    logHandler.info('Saving new questions of match: ${selectedMatch.matchName}');
    final saved = getAllSavedQuestions<T>();
    saved.removeWhere((e) => e.matchName == selectedMatch.matchName);
    saved.add(selectedMatch);
    overwriteSave(saved, _mapTypeToFile(T));
  }

  static void removeDeletedMatchQuestions<T extends BaseMatch>() {
    logHandler.info('Removing questions of deleted matches');
    final matchNames = getMatchNames();
    final saved = (getAllSavedQuestions<T>()).where((e) => matchNames.contains(e.matchName)).toList();
    overwriteSave(saved, _mapTypeToFile(T));
  }

  static void removeQuestionsOfMatch<T extends BaseMatch>(T match) {
    logHandler.info('Removing all questions of match: ${match.matchName}');
    final saved = (getAllSavedQuestions<T>())..removeWhere((e) => e.matchName == match.matchName);
    overwriteSave(saved, _mapTypeToFile(T));
  }

  static T getMatchQuestions<T extends BaseMatch>(String matchName) {
    final saved = getAllSavedQuestions<T>();
    if (saved.isEmpty) return BaseMatch.empty<T>(matchName);

    T selectedMatch;

    try {
      selectedMatch = saved.firstWhere((e) => e.matchName == matchName);
      logHandler.info("Loaded questions of $T named '$matchName'");
    } on StateError {
      logHandler.info("$T named '$matchName' not found, temp empty match created");
      selectedMatch = BaseMatch.empty<T>(matchName);
    }
    return selectedMatch;
  }

  static void overwriteSave<T>(List<T> q, String filePath) {
    logHandler.info('Overwriting save');
    storageHandler.writeStringToFile(filePath, jsonEncode(q));
  }
}
