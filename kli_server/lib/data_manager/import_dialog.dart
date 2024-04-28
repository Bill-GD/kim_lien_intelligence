import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../global.dart';

class ImportQuestionDialog extends StatefulWidget {
  final String matchName;
  final int maxColumnCount, maxSheetCount;
  final List<double> columnWidths;
  const ImportQuestionDialog({
    super.key,
    required this.matchName,
    required this.maxColumnCount,
    required this.maxSheetCount,
    required this.columnWidths,
  });

  @override
  State<ImportQuestionDialog> createState() => _ImportQuestionDialogState();
}

class _ImportQuestionDialogState extends State<ImportQuestionDialog> with TickerProviderStateMixin {
  String chosenFile = 'Chưa chọn file';
  Map<String, List<Map<String, dynamic>>> data = {};
  late TabController tabController;

  bool disableDone = true;
  int nonNullColCount = 0, sheetCount = 0;
  int sheetIndex = 0;

  @override
  void initState() {
    logger.i('Import question dialog: ${widget.matchName}');
    tabController = TabController(length: sheetCount, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        title: const Text('Nhập câu hỏi từ file (Xem trước)', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(chosenFile, style: const TextStyle(fontSize: fontSizeSmall)),
                const SizedBox(width: 20),
                ElevatedButton(
                  child: const Text('Chọn file'),
                  onPressed: () async {
                    logger.i('Import new questions (.xlsx)');

                    final result = await FilePicker.platform.pickFiles(
                      dialogTitle: 'Select File',
                      initialDirectory: storageHandler!.newDataDir.replaceAll('/', '\\'),
                      type: FileType.custom,
                      allowedExtensions: ['xlsx'],
                    );

                    if (result == null) {
                      logger.i('No file selected');
                      return;
                    }

                    disableDone = false;

                    final p = result.files.single.path!;
                    chosenFile = storageHandler!.getRelative(p);
                    logger.i('Import: $chosenFile');

                    data = await storageHandler!.readFromExcel(
                      p,
                      widget.maxColumnCount,
                      widget.maxSheetCount,
                    );

                    sheetCount = data.keys.length;
                    nonNullColCount =
                        data.values.first.first.keys.takeWhile((value) => value != 'null').length;

                    tabController = TabController(length: sheetCount, vsync: this);

                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(width: 40),
            data.keys.length < 2
                ? const SizedBox.shrink()
                : TabBar(
                    controller: tabController,
                    onTap: (value) {
                      setState(() => sheetIndex = value);
                    },
                    tabs: [
                      for (final sheet in data.keys) Tab(text: sheet),
                    ],
                  ),
            Flexible(
              child: SingleChildScrollView(
                child: data.isEmpty
                    ? const Text('Chưa có dữ liệu', textAlign: TextAlign.center)
                    : createTable(sheetIndex),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: disableDone
                ? null
                : () {
                    Navigator.of(context).pop(data);
                  },
            child: const Text('Hoàn tất', style: TextStyle(fontSize: fontSizeMSmall)),
          ),
          TextButton(
            child: const Text('Hủy', style: TextStyle(fontSize: fontSizeMSmall)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Table createTable(int sheetIndex) {
    final headerRow = <Widget>[];

    final q = data.values.elementAt(sheetIndex).first;
    final colTitles = q.keys;

    for (int i = 0; i < colTitles.length; i++) {
      final col = colTitles.elementAt(i);
      headerRow.add(Text(
        col,
        style: TextStyle(
          fontSize: fontSizeMSmall,
          color: i > nonNullColCount - 1 && col == 'null' ? Colors.red : null,
        ),
      ));
    }

    final rows = <TableRow>[TableRow(children: headerRow)];

    for (final q in data.values.elementAt(sheetIndex)) {
      final row = <Widget>[];
      for (int i = 0; i < q.values.length; i++) {
        final val = q.values.elementAt(i);
        row.add(Text(
          val.toString(),
          style: TextStyle(
            fontSize: fontSizeMSmall,
            color: i > nonNullColCount - 1 && val.toString() == 'null' ? Colors.red : null,
          ),
        ));
      }
      rows.add(TableRow(children: row));
    }

    return Table(
      children: rows,
      columnWidths: {
        0: FixedColumnWidth(widget.columnWidths[0]),
        1: FixedColumnWidth(widget.columnWidths[1]),
        2: FixedColumnWidth(widget.columnWidths[2]),
        3: FixedColumnWidth(widget.columnWidths[3]),
        4: FixedColumnWidth(widget.columnWidths[4]),
      },
    );
  }
}
