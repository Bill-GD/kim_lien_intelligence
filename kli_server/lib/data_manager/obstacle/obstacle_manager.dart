import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../data_manager.dart';
import '../import_dialog.dart';
import 'obstacle_editor.dart';
import 'obstacle_question_editor.dart';

class ObstacleManager extends StatefulWidget {
  const ObstacleManager({super.key});

  @override
  State<ObstacleManager> createState() => _ObstacleManagerState();
}

class _ObstacleManagerState extends State<ObstacleManager> {
  bool isLoading = true, hasSelectedMatch = false;
  List<String> matchNames = [];
  late ObstacleMatch selectedMatch;
  final obstacleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Obstacle Manager', d: 1);
    logHandler.depth = 2;
    selectedMatch = ObstacleMatch.empty();
    DataManager.getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await DataManager.removeDeletedMatchQuestions<ObstacleMatch>();
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
        matchName: selectedMatch.matchName,
        keyword: sheet[5].values.elementAt(3),
        imagePath: '',
        charCount: int.parse(sheet[5].values.elementAt(1)),
        explanation: sheet[5].values.elementAt(4),
        hintQuestions: qL,
      );
    } on RangeError catch (e, stack) {
      showToastMessage(context, 'Sai định dạng (không đủ cột/hàng)');
      logHandler.error('$e', stackTrace: stack, d: 3);
      return;
    }
    logHandler.info('Loaded ${selectedMatch.matchName} (${selectedMatch.keyword})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(
        context,
        'Quản lý câu hỏi chướng ngại vật',
        actions: [
          const HelpButton(
            content: '''
              Thông tin chướng ngại vật: ảnh & từ khoá.
              Thông tin câu hỏi: nội dung, đáp án. Số ký tự là các ký tự khác dấu cách, được tính tự động.
              
              Chọn trận đấu: Chọn trận đấu để hiện các câu hỏi.

              Nhập từ file: Nhập câu hỏi từ file Excel.
              Xóa câu hỏi: Xóa toàn bộ câu hỏi của trận đang chọn.
        
              Bấm vào câu hỏi để sửa câu hỏi.
              Thay đổi chướng ngại vật và chọn ảnh chướng ngại vật ở bên phải.
              
              Định dạng file Excel:
              - Chỉ lấy câu hỏi ở sheet đầu tiên
              - Cột 1: STT
              - Cột 2: Số ký tự
              - Cột 3: Nội dung câu hỏi
              - Cột 4: Đáp án
              - Cột 5: Giải thích
              - Hàng 2-6: Câu hỏi hàng ngang & trung tâm
              - Hàng 7: Chướng ngại vật''',
          ),
        ],
      ),
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
            logHandler.info('Selected match: $value');
            hasSelectedMatch = value != null;
            selectedMatch = await DataManager.getMatchQuestions<ObstacleMatch>(value!);
            setState(() {});
          }),
          KLIButton(
            'Nhập từ file',
            enableCondition: hasSelectedMatch,
            enabledLabel: 'Cho phép nhập dữ liệu từ file Excel',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              Map<String, dynamic>? data =
                  await Navigator.of(context).push<Map<String, dynamic>>(DialogRoute<Map<String, dynamic>>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => ImportQuestionDialog(
                  matchName: selectedMatch.matchName,
                  maxColumnCount: 5,
                  maxSheetCount: 1,
                  columnWidths: const [100, 75, 500, 200, 500],
                ),
              ));

              if (data == null) return;

              await getNewQuestion(data);
              await DataManager.saveNewQuestions<ObstacleMatch>(selectedMatch);
              setState(() {});
            },
          ),
          // KLIButton('Export Excel', enableCondition: false),
          KLIButton(
            'Xóa câu hỏi',
            enableCondition: hasSelectedMatch,
            enabledLabel: 'Xóa toàn bộ câu hỏi của phần thi hiện tại',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              await confirmDialog(
                context,
                message: 'Bạn có muốn xóa tất cả hàng ngang của trận: ${selectedMatch.matchName}?',
                acceptLogMessage: 'Removed all obstacle questions for match: ${selectedMatch.matchName}',
                onAccept: () async {
                  if (mounted) showToastMessage(context, 'Đã xóa (match: ${selectedMatch.matchName})');

                  await DataManager.removeQuestionsOfMatch<ObstacleMatch>(selectedMatch);
                  selectedMatch = ObstacleMatch.empty(selectedMatch.matchName);
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
          if (!hasSelectedMatch)
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
                    await DataManager.updateQuestions<ObstacleMatch>(selectedMatch);
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
    fullImagePath = '${StorageHandler.appRootDirectory}\\${selectedMatch.imagePath}';
    imageFound = File(fullImagePath).existsSync();

    return Flexible(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Chướng ngại vật', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          if (!hasSelectedMatch)
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
                          await DataManager.updateQuestions<ObstacleMatch>(selectedMatch);
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
            child: hasSelectedMatch && fullImagePath.isNotEmpty && imageFound
                ? Image.file(File(fullImagePath), fit: BoxFit.contain)
                : Material(
                    child: Center(
                    child: Text(
                      !hasSelectedMatch
                          ? 'Chưa chọn trận đấu'
                          : selectedMatch.imagePath.isEmpty
                              ? 'Không có ảnh'
                              : 'Không tìm thấy ảnh $fullImagePath',
                    ),
                  )),
          ),
          const SizedBox(height: 20),
          if (!hasSelectedMatch)
            const SizedBox.shrink()
          else
            ElevatedButton(
              child: const Text('Chọn ảnh'),
              onPressed: () async {
                logHandler.depth = 3;
                logHandler.info('Selecting image at ${StorageHandler.getRelative(storageHandler.mediaDir)}');
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: 'Select image',
                  initialDirectory: storageHandler.mediaDir.replaceAll('/', '\\'),
                  type: FileType.image,
                );

                if (result != null) {
                  final p = result.files.single.path!;
                  selectedMatch.imagePath = StorageHandler.getRelative(p);
                  await DataManager.updateQuestions<ObstacleMatch>(selectedMatch);
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
