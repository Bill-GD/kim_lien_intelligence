import 'dart:io';

import 'package:excel/excel.dart';

import '../global.dart';

/// A static class for reading & writing to file.
class StorageHandler {
  // these are reletive to exe path
  static const String _userDataDir = 'UserData';

  static String get mediaDir => '$_userDataDir/Media';

  static String get excelDir => '$_userDataDir/NewData';

  static String get matchSaveFile => '$_userDataDir/match.txt';

  static String get questionDir => '$_userDataDir/Questions';
  static String get startSaveFile => '$questionDir/start.txt';
  static String get obstacleSaveFile => '$questionDir/obstacle.txt';
  static String get accelSaveFile => '$questionDir/accel.txt';
  static String get finishSaveFile => '$questionDir/finish.txt';
  static String get extraSaveFile => '$questionDir/extra.txt';

  static Future<void> init(String prefixPath) async {
    logger.i('StorageHandler init');
    await StorageHandler.createFileEntity('$prefixPath/$mediaDir', StorageType.dir);
    await StorageHandler.createFileEntity('$prefixPath/$excelDir', StorageType.dir);

    await StorageHandler.createFileEntity('$prefixPath/$matchSaveFile', StorageType.file);

    await StorageHandler.createFileEntity('$prefixPath/$startSaveFile', StorageType.file);
    await StorageHandler.createFileEntity('$prefixPath/$obstacleSaveFile', StorageType.file);
    await StorageHandler.createFileEntity('$prefixPath/$accelSaveFile', StorageType.file);
    await StorageHandler.createFileEntity('$prefixPath/$finishSaveFile', StorageType.file);
    await StorageHandler.createFileEntity('$prefixPath/$extraSaveFile', StorageType.file);
  }

  // D:/Downloads/KĐ trận BK1.xlsx
  // D:/Downloads/output.txt
  static Future readFromExcel(String path, int maxColumnCount) async {
    logger.i('Reading from $path');

    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    return excelToJson(excel, maxColumnCount);
  }

  static Future<Map<String, List<Map<String, dynamic>>>> excelToJson(Excel excel, int maxColumnCount) async {
    final res = <String, List<Map<String, dynamic>>>{};

    for (final tableName in excel.tables.keys) {
      final allRows = excel.tables[tableName]!.rows;

      // attribute name
      final firstRow = allRows[0];
      final attributes = firstRow.map((e) => (e?.value).toString());

      final records = <Map<String, dynamic>>[];

      for (var rIdx = 1; rIdx < allRows.length; rIdx++) {
        final row = allRows[rIdx];

        // check for empty row
        final firstCell = row[0];
        if (firstCell?.value == null) break;

        final rec = <String, dynamic>{};

        int cIdx = 0;
        for (final cell in row) {
          if (cIdx >= maxColumnCount) break;

          rec[attributes.elementAt(cIdx)] = (cell?.value).toString();
          cIdx++;
        }

        records.add(rec);
      }
      res[tableName] = records;
    }
    return res;
  }

  static Future<String> readFromFile(String path) async {
    return await File(path).readAsString();
  }

  static Future<void> writeToFile(String path, String data) async {
    await File(path).writeAsString(data);
  }

  static Future<void> createFileEntity(String path, StorageType type) async {
    try {
      final FileSystemEntity f;

      if (type == StorageType.file) {
        f = File(path);
      } else {
        f = Directory(path);
      }

      await (f is File ? f.create(exclusive: true) : (f as Directory).create(recursive: true));
      logger.i('Created: $path');
    } on PathExistsException {
      return;
    }
  }
}

enum StorageType { file, dir }
