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

  static Future<List<T>> getAllSavedQuestions<T extends BaseMatch>() async {
    logHandler.info('Getting all saved $T questions');
    final saved = await storageHandler.readFromFile(_mapTypeToFile(T));
    if (saved.isEmpty) return <T>[];

    List<T> q = [];
    try {
      q = (jsonDecode(saved) as List).map((j) => BaseMatch.fromJson<T>(j)).toList();
    } on Exception catch (e, stack) {
      logHandler.error('$e', stackTrace: stack);
    }
    return q;
  }

  static Future<void> updateQuestions<T extends BaseMatch>(T match) async {
    logHandler.info('Updating questions of match: ${match.matchName}', d: 3);
    final saved = await getAllSavedQuestions<T>();
    saved.removeWhere((e) => e.matchName == match.matchName);
    saved.add(match);
    await overwriteSave(saved, _mapTypeToFile(T));
  }

  static Future<void> updateAllQuestionMatchName({required String oldName, required String newName}) async {
    logHandler.info(
      'Match name update detected. Updating match name of all questions (\'$oldName\' -> \'$newName\')',
      d: 1,
    );

    List<Type> types = [StartMatch, ObstacleMatch, AccelMatch, FinishMatch, ExtraMatch];

    for (final type in types) {
      List<BaseMatch> m = switch (type) {
        StartMatch => await getAllSavedQuestions<StartMatch>(),
        ObstacleMatch => await getAllSavedQuestions<ObstacleMatch>(),
        AccelMatch => await getAllSavedQuestions<AccelMatch>(),
        FinishMatch => await getAllSavedQuestions<FinishMatch>(),
        ExtraMatch => await getAllSavedQuestions<ExtraMatch>(),
        _ => throw Exception('Unknown type'),
      };

      for (final e in m) {
        if (e.matchName == oldName) e.matchName = newName;
      }
      await overwriteSave(m, _mapTypeToFile(type));
      logHandler.info('Updated $type');
    }
  }

  static Future<List<String>> getMatchNames() async {
    List<String> matchNames = [];
    String value = await storageHandler.readFromFile(storageHandler.matchSaveFile);
    if (value.isNotEmpty) {
      matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
    }
    return matchNames;
  }

  static Future<void> saveNewQuestions<T extends BaseMatch>(T selectedMatch) async {
    logHandler.info('Saving new questions of match: ${selectedMatch.matchName}', d: 3);
    final saved = await getAllSavedQuestions<T>();
    saved.removeWhere((e) => e.matchName == selectedMatch.matchName);
    saved.add(selectedMatch);
    await overwriteSave(saved, _mapTypeToFile(T));
  }

  static Future<void> removeDeletedMatchQuestions<T extends BaseMatch>() async {
    logHandler.info('Removing questions of deleted matches', d: 3);
    final matchNames = await getMatchNames();
    final saved = (await getAllSavedQuestions<T>()).where((e) => matchNames.contains(e.matchName)).toList();
    await overwriteSave(saved, _mapTypeToFile(T));
  }

  static Future<void> removeQuestionsOfMatch<T extends BaseMatch>(T match) async {
    logHandler.info('Removing all questions of match: ${match.matchName}', d: 3);
    final saved = (await getAllSavedQuestions<T>())..removeWhere((e) => e.matchName == match.matchName);
    await overwriteSave(saved, _mapTypeToFile(T));
  }

  static Future<T> getMatchQuestions<T extends BaseMatch>(String matchName) async {
    final saved = await getAllSavedQuestions<T>();
    if (saved.isEmpty) return BaseMatch.empty<T>(matchName);

    T selectedMatch;

    try {
      selectedMatch = saved.firstWhere((e) => e.matchName == matchName);
      logHandler.info("Loaded questions of $T named '$matchName'", d: 2);
    } on StateError {
      logHandler.info("$T named '$matchName' not found, temp empty match created");
      selectedMatch = BaseMatch.empty<T>(matchName);
    }
    return selectedMatch;
  }

  static Future<void> overwriteSave<T>(List<T> q, String filePath) async {
    logHandler.info('Overwriting save');
    await storageHandler.writeToFile(filePath, jsonEncode(q));
  }
}
