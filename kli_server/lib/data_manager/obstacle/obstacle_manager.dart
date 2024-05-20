import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../import_dialog.dart';
import 'obstacle_editor.dart';
import 'obstacle_question_editor.dart';

class ObstacleManager extends StatefulWidget {
  const ObstacleManager({super.key});

  @override
  State<ObstacleManager> createState() => _ObstacleManagerState();
}

class _ObstacleManagerState extends State<ObstacleManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  int selectedMatchIndex = -1;
  late ObstacleMatch selectedMatch;
  final obstacleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logHandler.info('Obstacle question manager init');
    selectedMatch = ObstacleMatch(
      match: '',
      charCount: 0,
      explanation: '',
      hintQuestions: List<ObstacleQuestion?>.filled(5, null),
      imagePath: '',
      keyword: '',
    );
    getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await removeDeletedMatchQuestions();
    });
  }

  @override
  void dispose() {
    obstacleController.dispose();
    super.dispose();
  }

  Future<void> getNewQuestion(Map<String, dynamic> data) async {
    final sheet = data.values.first;

    List<ObstacleQuestion> qL = [];
    for (int i = 0; i < sheet.length - 1; i++) {
      try {
        qL.add(ObstacleQuestion(
          id: i,
          question: sheet[i].values.elementAt(2),
          answer: sheet[i].values.elementAt(3),
          charCount: int.parse(sheet[i].values.elementAt(1)),
        ));
      } on FormatException {
        showToastMessage(context, 'Sai định dạng (số ký tự)');
        break;
      }
    }

    try {
      selectedMatch = ObstacleMatch(
        match: matchNames[selectedMatchIndex],
        keyword: sheet[5].values.elementAt(3),
        imagePath: '',
        charCount: int.parse(sheet[5].values.elementAt(1)),
        explanation: sheet[5].values.elementAt(4),
        hintQuestions: qL,
      );
    } on RangeError catch (e, stack) {
      showToastMessage(context, 'Sai định dạng (không đủ cột/hàng)');
      logHandler.error(e, stackTrace: stack);
      return;
    }
    logHandler.info('Loaded ${selectedMatch.match} (${selectedMatch.keyword})');
  }

  Future<void> saveNewQuestions() async {
    logHandler.info('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    saved.removeWhere((e) => e.match == selectedMatch.match);
    saved.add(selectedMatch);
    await DataManager.overwriteSave(saved, storageHandler!.obstacleSaveFile);
  }

  Future<void> updateQuestions(ObstacleMatch oMatch) async {
    logHandler.info('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    saved.removeWhere((e) => e.match == oMatch.match);
    saved.add(oMatch);
    await DataManager.overwriteSave(saved, storageHandler!.obstacleSaveFile);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logHandler.info('Loaded Obstacle (${selectedMatch.keyword}) of $match');
    } on StateError {
      logHandler.info('Obstacle match $match not found, temp empty match created');
      selectedMatch = ObstacleMatch(
        match: matchNames[selectedMatchIndex],
        keyword: '',
        imagePath: '',
        charCount: 0,
        explanation: '',
        hintQuestions: List<ObstacleQuestion?>.filled(5, null),
      );
    }
  }

  Future<void> removeDeletedMatchQuestions() async {
    logHandler.info('Removing questions of deleted matches');
    var saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    saved = saved.where((e) => matchNames.contains(e.match)).toList();
    await DataManager.overwriteSave(saved, storageHandler!.obstacleSaveFile);
  }

  Future<void> removeMatch(ObstacleMatch oMatch) async {
    logHandler.info('Removing questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    saved.removeWhere((e) => e.match == oMatch.match);
    await DataManager.overwriteSave(saved, storageHandler!.obstacleSaveFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Quản lý câu hỏi chướng ngại vật'),
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                managementButtons(),
                matchContent(),
              ],
            ),
    );
  }

  Widget managementButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          matchSelector(matchNames, (value) async {
            selectedMatchIndex = matchNames.indexOf(value!);
            logHandler.info('Selected match: ${matchNames[selectedMatchIndex]}');
            await loadMatchQuestions(matchNames[selectedMatchIndex]);
            setState(() {});
          }),
          KLIButton(
            'Nhập từ file',
            enableCondition: selectedMatchIndex >= 0,
            enabledLabel: 'Cho phép nhập dữ liệu từ file Excel',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              Map<String, dynamic>? data =
                  await Navigator.of(context).push<Map<String, dynamic>>(DialogRoute<Map<String, dynamic>>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => ImportQuestionDialog(
                  matchName: matchNames[selectedMatchIndex],
                  maxColumnCount: 5,
                  maxSheetCount: 1,
                  columnWidths: const [100, 75, 500, 200, 500],
                ),
              ));

              if (data == null) return;

              await getNewQuestion(data);
              await saveNewQuestions();
              setState(() {});
            },
          ),
          // KLIButton('Export Excel', enableCondition: false),
          KLIButton(
            'Xóa câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
            enabledLabel: 'Xóa toàn bộ câu hỏi của phần thi hiện tại',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              await confirmDialog(
                context,
                message: 'Bạn có muốn xóa tất cả hàng ngang của trận: ${matchNames[selectedMatchIndex]}?',
                acceptLogMessage:
                    'Removed all obstacle questions for match: ${matchNames[selectedMatchIndex]}',
                onAccept: () async {
                  if (mounted) showToastMessage(context, 'Đã xóa (match: ${matchNames[selectedMatchIndex]})');

                  await removeMatch(selectedMatch);
                  selectedMatch = ObstacleMatch(
                    match: matchNames[selectedMatchIndex],
                    keyword: '',
                    imagePath: '',
                    charCount: 0,
                    explanation: '',
                    hintQuestions: List<ObstacleQuestion?>.filled(5, null),
                  );
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget matchContent() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            questionList(),
            obstaclePreview(),
          ],
        ),
      ),
    );
  }

  Widget questionList() {
    return Flexible(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Danh sách câu hỏi', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          if (selectedMatchIndex < 0)
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
              ),
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
              child: const Material(child: Center(child: Text('Chưa chọn trận đấu'))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              itemCount: 5,
              separatorBuilder: (_, index) => const SizedBox(height: 20),
              itemBuilder: (_, index) {
                final q = selectedMatch.hintQuestions[index];

                return ListTile(
                  leading: Text("${index + 1}"),
                  tileColor: Theme.of(context).colorScheme.background,
                  leadingAndTrailingTextStyle: const TextStyle(fontSize: fontSizeMedium),
                  title: Text(q?.question ?? '', style: const TextStyle(fontSize: fontSizeMedium)),
                  subtitle: Text('${q?.charCount ?? 0} kí tự'),
                  subtitleTextStyle: const TextStyle(fontSize: fontSizeSmall),
                  trailing: Text(q?.answer ?? ''),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
                  ),
                  onTap: () async {
                    final nQ = await Navigator.of(context).push<ObstacleQuestion>(
                      DialogRoute<ObstacleQuestion>(
                        context: context,
                        builder: (_) => ObstacleQuestionEditor(question: q, index: index),
                      ),
                    );

                    if (nQ == null) return;
                    selectedMatch.hintQuestions[index] = nQ;
                    await updateQuestions(selectedMatch);
                    setState(() {});
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget obstaclePreview() {
    bool imageFound = false;
    String fullImagePath = '';
    fullImagePath = '${storageHandler!.parentFolder}\\${selectedMatch.imagePath}';
    imageFound = File(fullImagePath).existsSync();

    return Flexible(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Chướng ngại vật', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          if (selectedMatchIndex < 0)
            const SizedBox.shrink()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 128, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListTile(
                        tileColor: Theme.of(context).colorScheme.background,
                        leadingAndTrailingTextStyle: const TextStyle(fontSize: fontSizeMedium),
                        title: Text(selectedMatch.keyword),
                        subtitle: Text('${selectedMatch.charCount} kí tự'),
                        subtitleTextStyle: const TextStyle(fontSize: fontSizeSmall),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
                        ),
                        onTap: () async {
                          final newO = await Navigator.of(context).push<(String, String)>(
                            DialogRoute<(String, String)>(
                              context: context,
                              builder: (_) => ObstacleEditor(
                                keyword: selectedMatch.keyword,
                                explanation: selectedMatch.explanation,
                              ),
                            ),
                          );

                          if (newO == null) return;

                          selectedMatch.keyword = newO.$1;
                          selectedMatch.explanation = newO.$2;
                          selectedMatch.charCount = newO.$1.replaceAll(' ', '').length;
                          await updateQuestions(selectedMatch);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
            ),
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
            child: selectedMatchIndex >= 0 && fullImagePath.isNotEmpty && imageFound
                ? Image.file(File(fullImagePath), fit: BoxFit.contain)
                : Material(
                    child: Center(
                    child: Text(
                      selectedMatchIndex < 0
                          ? 'Chưa chọn trận đấu'
                          : selectedMatch.imagePath.isEmpty
                              ? 'Không có ảnh'
                              : 'Không tìm thấy ảnh $fullImagePath',
                    ),
                  )),
          ),
          const SizedBox(height: 20),
          if (selectedMatchIndex < 0)
            const SizedBox.shrink()
          else
            ElevatedButton(
              child: const Text('Chọn ảnh'),
              onPressed: () async {
                logHandler.info('Selecting image at ${storageHandler!.getRelative(storageHandler!.mediaDir)}');
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: 'Select image',
                  initialDirectory: storageHandler!.mediaDir.replaceAll('/', '\\'),
                  type: FileType.image,
                );

                if (result != null) {
                  final p = result.files.single.path!;
                  selectedMatch.imagePath = storageHandler!.getRelative(p);
                  await updateQuestions(selectedMatch);
                  logHandler.info('Chose ${selectedMatch.imagePath}');
                  setState(() {});
                }
              },
            ),
        ],
      ),
    );
  }
}
