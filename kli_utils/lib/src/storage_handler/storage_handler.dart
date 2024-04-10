import 'dart:io';

import 'package:excel/excel.dart';

import '../global.dart';
import '../global_export.dart';

enum StorageType { file, dir }

class StorageHandler {
  // these are relative to exe path
  final String _parentFolder;
  String get parentFolder => _parentFolder;
  final String _userDataDir;

  String get logFile => '$_userDataDir\\log.txt';
  String get excelOutput => '$_userDataDir\\ExcelExport';

  String get mediaDir => '$_userDataDir\\Media';
  String get newDataDir => '$_userDataDir\\NewData';
  String get questionDir => '$_userDataDir\\Questions';

  String get matchSaveFile => '$_userDataDir\\match.txt';
  String get startSaveFile => '$questionDir\\start.txt';
  String get obstacleSaveFile => '$questionDir\\obstacle.txt';
  String get accelSaveFile => '$questionDir\\accel.txt';
  String get finishSaveFile => '$questionDir\\finish.txt';
  String get extraSaveFile => '$questionDir\\extra.txt';

  /// Use [StorageHandler.init] to create an instance instead.
  StorageHandler(this._parentFolder) : _userDataDir = '$_parentFolder\\UserData';

  static Future<StorageHandler> init(String prefixPath) async {
    logMessageController.add(const (LogType.info, 'StorageHandler init'));

    final sh = StorageHandler(prefixPath.replaceAll('/', '\\'));
    logMessageController.add((LogType.info, sh.parentFolder));

    await sh.createFileEntity(sh.mediaDir, StorageType.dir);
    await sh.createFileEntity(sh.newDataDir, StorageType.dir);
    await sh.createFileEntity(sh.excelOutput, StorageType.dir);
    await sh.createFileEntity(sh.logFile, StorageType.file);
    await sh.createFileEntity(sh.matchSaveFile, StorageType.file);
    await sh.createFileEntity(sh.startSaveFile, StorageType.file);
    await sh.createFileEntity(sh.obstacleSaveFile, StorageType.file);
    await sh.createFileEntity(sh.accelSaveFile, StorageType.file);
    await sh.createFileEntity(sh.finishSaveFile, StorageType.file);
    await sh.createFileEntity(sh.extraSaveFile, StorageType.file);

    return sh;
  }

  /// Return: ```{tableName: [rows]}```
  Future readFromExcel(String path, int maxColumnCount, int maxSheetCount) async {
    logMessageController.add((LogType.info, 'Reading Excel from ${getRelative(path)}'));

    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    return excelToJson(excel, maxColumnCount, maxSheetCount);
  }

  Future<Map<String, List<Map<String, dynamic>>>> excelToJson(
      Excel excel, int maxColumnCount, int maxSheetCount) async {
    logMessageController.add(const (LogType.info, 'Format: Excel -> Json'));
    final res = <String, List<Map<String, dynamic>>>{};

    int sIdx = 1;
    for (final tableName in excel.tables.keys) {
      if (sIdx > maxSheetCount) {
        logMessageController.add((LogType.info, 'Max sheet count reached, break'));
        break;
      }

      final allRows = excel.tables[tableName]!.rows;

      // attribute name
      final firstRow = allRows[0];
      final attributes = firstRow.map((e) => (e?.value).toString()).take(maxColumnCount);

      logMessageController.add((LogType.info, 'First row: ${attributes.join(', ')}'));

      final records = <Map<String, dynamic>>[];

      for (var rIdx = 1; rIdx < allRows.length; rIdx++) {
        final row = allRows[rIdx];

        // check for empty row
        final firstCell = row[0];
        if (firstCell?.value == null) {
          logMessageController.add((LogType.info, 'row=${rIdx + 1} -> empty -> break'));
          break;
        }

        final rec = <String, dynamic>{};

        int cIdx = 0;
        for (final cell in row) {
          if (cIdx >= maxColumnCount) {
            // logMessageController.add((
            //   LogType.info,
            //   'row=${rIdx + 1} -> maxColumnCount exceeded -> break',
            // ));
            break;
          }

          rec[attributes.elementAt(cIdx)] = (cell?.value).toString();
          cIdx++;
        }

        records.add(rec);
      }
      res[tableName] = records;
      sIdx++;
    }
    return res;
  }

  Future<void> writeToExcel(String fileName, Map<String, dynamic> json) async {
    logMessageController.add((
      LogType.info,
      'Writing Excel to ${getRelative('$excelOutput\\$fileName')}',
    ));

    final columnTitles = ((json.values.elementAt(0) as List)[0] as Map<String, dynamic>).keys.toList();

    final excel = Excel.createExcel();

    for (final String tableName in json.keys) {
      Sheet sheetObject = excel[tableName];

      // first row
      for (var i = 0; i < columnTitles.length; i++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
            TextCellValue(columnTitles[i]);
      }

      int rIdx = 1;
      final data = json[tableName] as List;
      for (var i = 0; i < data.length; i++) {
        final row = data[i].values;
        for (var j = 0; j < row.length; j++) {
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rIdx)).value =
              TextCellValue(row.elementAt(j));
        }
        rIdx++;
      }
    }
    excel.delete('Sheet1');

    await File('$excelOutput\\$fileName').writeAsBytes(excel.encode()!);
    logMessageController.add((LogType.info, 'Done writing to $excelOutput\\$fileName'));
  }

  Future<String> readFromFile(String path) async {
    logMessageController.add((LogType.info, 'Read from ${getRelative(path)}'));
    return await File(path).readAsString();
  }

  Future<void> writeToFile(String path, String data) async {
    logMessageController.add((LogType.info, 'Write to ${getRelative(path)}'));
    await File(path).writeAsString(data);
  }

  Future<void> createFileEntity(String path, StorageType type) async {
    try {
      final FileSystemEntity f;

      if (type == StorageType.file) {
        f = File(path);
      } else {
        f = Directory(path);
      }
      if (f.existsSync()) return;

      await (f is File ? f.create(recursive: true) : (f as Directory).create(recursive: true));
      logMessageController.add((LogType.info, 'Created: ${getRelative(path)}'));
    } on PathExistsException {
      return;
    }
  }

  String getRelative(String abs) {
    return abs.replaceAll(_parentFolder, '').substring(1);
  }
}
