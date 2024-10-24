import 'dart:convert';
import 'dart:io';

import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

class DataManager {
  static String _mapTypeToFile(Type type, String match) {
    if (type == StartMatch) return storageHandler.startSaveFile(match);
    if (type == ObstacleMatch) return storageHandler.obstacleSaveFile(match);
    if (type == AccelMatch) return storageHandler.accelSaveFile(match);
    if (type == FinishMatch) return storageHandler.finishSaveFile(match);
    if (type == ExtraMatch) return storageHandler.extraSaveFile(match);
    throw Exception('Unknown type');
  }

  static List<String> getMatchNames() {
    List<String> matchNames = [];
    String value = storageHandler.readFromFile(storageHandler.matchSaveFile);
    if (value.isNotEmpty) {
      matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
    }
    return matchNames;
  }

  static T getSectionQuestionsOfMatch<T extends BaseMatch>(String matchName) {
    logHandler.info('Getting all saved $T questions');
    final saved = storageHandler.readFromFile(_mapTypeToFile(T, matchName));
    if (saved.isEmpty) return BaseMatch.empty<T>(matchName);

    T q = BaseMatch.empty<T>(matchName);
    try {
      q = BaseMatch.fromJson<T>(json.decode(saved));
      logHandler.info("Loaded questions of $T named '$matchName'");
    } on Exception catch (e, stack) {
      logHandler.error('$e', stackTrace: stack);
    }
    return q;
  }

  static void changeMatchName({required String oldName, required String newName}) {
    logHandler.info(
      'Match name update detected. Updating match name of all questions (\'$oldName\' -> \'$newName\')',
    );

    List<Type> types = [StartMatch, ObstacleMatch, AccelMatch, FinishMatch, ExtraMatch];

    for (final type in types) {
      BaseMatch m = switch (type) {
        StartMatch => getSectionQuestionsOfMatch<StartMatch>(oldName),
        ObstacleMatch => getSectionQuestionsOfMatch<ObstacleMatch>(oldName),
        AccelMatch => getSectionQuestionsOfMatch<AccelMatch>(oldName),
        FinishMatch => getSectionQuestionsOfMatch<FinishMatch>(oldName),
        ExtraMatch => getSectionQuestionsOfMatch<ExtraMatch>(oldName),
        _ => throw Exception('Unknown type'),
      };

      m.matchName = newName;

      // overwriteSave('', _mapTypeToFile(type, oldName));
      overwriteSave(jsonEncode(m), _mapTypeToFile(type, newName));
      logHandler.info('Updated $type');
    }
    Directory('${storageHandler.saveDataDir}\\$oldName').deleteSync(recursive: true);
  }

  static void updateSectionDataOfMatch<T extends BaseMatch>(T match) {
    logHandler.info('Saving new questions of match: ${match.matchName}');
    overwriteSave(jsonEncode(match), _mapTypeToFile(T, match.matchName));
  }

  static void removeSectionDataOfMatch<T extends BaseMatch>(T match) {
    logHandler.info('Removing all questions of match: ${match.matchName}');
    overwriteSave('', _mapTypeToFile(T, match.matchName));
  }

  static void removeDeletedMatchData() {
    logHandler.info('Removing data of deleted matches');
    final matchNames = getMatchNames();
    final savedMatchNames = Directory(storageHandler.saveDataDir) //
        .listSync()
        .map((e) => e.path.split('\\').last)
        .where((e) => !e.contains('match'));

    for (final matchName in savedMatchNames) {
      if (matchNames.contains(matchName)) continue;
      Directory('${storageHandler.saveDataDir}\\$matchName').deleteSync(recursive: true);
    }
  }

  static void overwriteSave<T>(String json, String filePath) {
    logHandler.info('Overwriting save');
    storageHandler.writeStringToFile(filePath, json, createIfNotExists: true);
  }
}
