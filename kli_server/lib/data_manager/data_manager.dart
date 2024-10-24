import 'dart:convert';
import 'dart:io';

import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

class DataManager {
  static String _mapTypeToFile(Type type, String match) {
    if (type == KLIMatch) return storageHandler.matchSaveFile(match);
    if (type == StartMatch) return storageHandler.startSaveFile(match);
    if (type == ObstacleMatch) return storageHandler.obstacleSaveFile(match);
    if (type == AccelMatch) return storageHandler.accelSaveFile(match);
    if (type == FinishMatch) return storageHandler.finishSaveFile(match);
    if (type == ExtraMatch) return storageHandler.extraSaveFile(match);
    throw Exception('Unknown type');
  }

  static List<String> getMatchNames() {
    List<String> matchNames = [];
    Directory(storageHandler.saveDataDir).listSync().forEach((e) {
      if (e is File) return;
      matchNames.add(e.path.split('\\').last);
    });
    return matchNames;
  }

  static List<KLIMatch> getAllMatches() {
    List<KLIMatch> matches = [];
    Directory(storageHandler.saveDataDir).listSync().forEach((d) {
      if (d is File) return;
      matches.add(KLIMatch.fromJson(jsonDecode(storageHandler.readFromFile('${d.path}\\match.kli'))));
    });
    return matches;
  }

  static KLIMatch getMatch(String name) {
    return KLIMatch.fromJson(jsonDecode(storageHandler.readFromFile('${storageHandler.saveDataDir}\\$name\\match.kli')));
  }

  static void updateMatch(KLIMatch match) {
    logHandler.info('Updating match: ${match.name}');
    overwriteSave(jsonEncode(match), storageHandler.matchSaveFile(match.name));
  }

  static void addMatch(String name) {
    logHandler.info('Adding match: $name');
    final files = [
      storageHandler.matchSaveFile(name),
      storageHandler.startSaveFile(name),
      storageHandler.obstacleSaveFile(name),
      storageHandler.accelSaveFile(name),
      storageHandler.finishSaveFile(name),
      storageHandler.extraSaveFile(name),
    ];

    for (final f in files) {
      final file = File(f);
      if (!file.existsSync()) file.createSync(recursive: true);
    }

    storageHandler.writeStringToFile(
      files[0],
      jsonEncode(KLIMatch(name: name, playerList: List.generate(4, (_) => null))),
    );
  }

  static void deleteMatch(String name) {
    logHandler.info('Deleting match: $name');
    Directory('${storageHandler.saveDataDir}\\$name').deleteSync(recursive: true);
  }

  static T getSectionQuestionsOfMatch<T extends BaseMatch>(String matchName) {
    logHandler.info('Getting all saved $T questions');
    final saved = storageHandler.readFromFile(_mapTypeToFile(T, matchName));
    if (saved.isEmpty) return BaseMatch.empty<T>(matchName);

    T q = BaseMatch.empty<T>(matchName);
    try {
      q = BaseMatch.fromJson<T>(jsonDecode(saved));
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
      final m = switch (type) {
        StartMatch => getSectionQuestionsOfMatch<StartMatch>(oldName),
        ObstacleMatch => getSectionQuestionsOfMatch<ObstacleMatch>(oldName),
        AccelMatch => getSectionQuestionsOfMatch<AccelMatch>(oldName),
        FinishMatch => getSectionQuestionsOfMatch<FinishMatch>(oldName),
        ExtraMatch => getSectionQuestionsOfMatch<ExtraMatch>(oldName),
        _ => throw Exception('Unknown type'),
      };
      m.matchName = newName;
      overwriteSave(jsonEncode(m), _mapTypeToFile(type, oldName));

      final match = getMatch(oldName);
      match.name = newName;
      overwriteSave(jsonEncode(match), storageHandler.matchSaveFile(oldName));
      logHandler.info('Updated $type');
    }
    // Directory('${storageHandler.saveDataDir}\\$oldName').deleteSync(recursive: true);
    Directory('${storageHandler.saveDataDir}\\$oldName').rename('${storageHandler.saveDataDir}\\$newName');
  }

  static void updateSectionDataOfMatch<T extends BaseMatch>(T match) {
    logHandler.info('Saving new questions of match: ${match.matchName}');
    overwriteSave(jsonEncode(match), _mapTypeToFile(T, match.matchName));
  }

  static void removeSectionDataOfMatch<T extends BaseMatch>(T match) {
    logHandler.info('Removing all questions of match: ${match.matchName}');
    overwriteSave('', _mapTypeToFile(T, match.matchName));
  }

  // delete match data that is left over
  static void removeDeletedMatchData() {
    logHandler.info('Removing remaining data of deleted matches');
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
