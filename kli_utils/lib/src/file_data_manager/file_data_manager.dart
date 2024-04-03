import 'dart:io';

import 'package:excel/excel.dart';

/// A static class for reading & writing to file.
class FileDataManager {
  // D:/Downloads/KĐ trận BK1.xlsx
  // D:/Downloads/output.txt
  static Future<String> readFromExcel(String path, int maxColumnCount, [int startRow = 0]) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    String result = '';

    for (final tableName in excel.tables.keys) {
      result += '$tableName\n';
      final allRows = excel.tables[tableName]!.rows;

      for (final row in allRows) {
        final firstCell = row[0];
        if (firstCell?.value == null) break;
        if (firstCell != null && firstCell.rowIndex < startRow) continue;

        result += '\t';

        for (final cell in row) {
          if (cell == null) continue;
          if (cell.columnIndex >= maxColumnCount) break;

          result += '${cell.value} || ';
        }
        result += '\n';
      }
      result += '\n';
    }
    return result;
  }

  static Future<void> writeToFile(String path, String data) async {
    await File(path).writeAsString(data);
  }
}
