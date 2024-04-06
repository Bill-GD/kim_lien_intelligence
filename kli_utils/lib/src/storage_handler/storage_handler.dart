import 'dart:io';

import 'package:excel/excel.dart';

import '../global.dart';

class StorageHandler {
  // these are reletive to exe path
  final String _parentFolder;
  String get parentFolder => _parentFolder;
  final String _userDataDir;

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
    logger.i('StorageHandler init');

    final sh = StorageHandler(prefixPath.replaceAll('/', '\\'));

    await sh.createFileEntity(sh.mediaDir, StorageType.dir);
    await sh.createFileEntity(sh.newDataDir, StorageType.dir);
    await sh.createFileEntity(sh.excelOutput, StorageType.dir);
    await sh.createFileEntity(sh.matchSaveFile, StorageType.file);
    await sh.createFileEntity(sh.startSaveFile, StorageType.file);
    await sh.createFileEntity(sh.obstacleSaveFile, StorageType.file);
    await sh.createFileEntity(sh.accelSaveFile, StorageType.file);
    await sh.createFileEntity(sh.finishSaveFile, StorageType.file);
    await sh.createFileEntity(sh.extraSaveFile, StorageType.file);

    return sh;
  }

  // D:/Downloads/KĐ trận BK1.xlsx
  // D:/Downloads/output.txt
  /// Return: ```{tableName: [rows]}```
  Future readFromExcel(String path, int maxColumnCount) async {
    logger.i('Reading Excel from ${getRelative(path)}');

    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    return excelToJson(excel, maxColumnCount);
  }

  Future<void> writeToExcel(String fileName, Map<String, dynamic> json) async {
    logger.i('Writing Excel to ${getRelative('$excelOutput\\$fileName')}');

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
  }

  Future<Map<String, List<Map<String, dynamic>>>> excelToJson(Excel excel, int maxColumnCount) async {
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

  Future<String> readFromFile(String path) async {
    logger.i('Read from ${getRelative(path)}');
    return await File(path).readAsString();
  }

  Future<void> writeToFile(String path, String data) async {
    logger.i('Write to ${getRelative(path)}');
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
      logger.i('Created: ${getRelative(path)}');
    } on PathExistsException {
      return;
    }
  }

  String getRelative(String abs) {
    return abs.replaceAll(_parentFolder, '').replaceAll('\\', '/');
  }
}

enum StorageType { file, dir }
