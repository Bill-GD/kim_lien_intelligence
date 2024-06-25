import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../data_manager.dart';
import '../import_dialog.dart';
import 'accel_question_editor.dart';

class AccelManager extends StatefulWidget {
  const AccelManager({super.key});

  @override
  State<AccelManager> createState() => _AccelManagerState();
}

class _AccelManagerState extends State<AccelManager> {
  bool isLoading = true, hasSelectedMatch = false;
  List<String> matchNames = [];
  int selectedQuestionIndex = -1, selectedImageIndex = -1;
  late AccelMatch selectedMatch;
  late AccelQuestion selectedQuestion;

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Accel Manager', d: 1);
    logHandler.depth = 2;
    selectedMatch = AccelMatch.empty();
    selectedQuestion = AccelQuestion.empty();
    DataManager.getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await DataManager.removeDeletedMatchQuestions<AccelMatch>();
    });
  }

  Future<void> getNewQuestion(Map<String, dynamic> data) async {
    logHandler.info('Extracting excel data');
    final List<AccelQuestion> allQ = [];

    final sheet = data.values.first;

    for (final r in (sheet as List<Map>)) {
      final v = r.values;
      final q = AccelQuestion(
        type: AccelQuestionType.none,
        question: v.elementAt(1),
        answer: v.elementAt(2),
        explanation: v.elementAt(3) == 'null' ? '' : v.elementAt(3),
        imagePaths: [],
      );
      allQ.add(q);
      if (allQ.length >= 4) {
        logHandler.info('Got 4 questions -> break');
        break;
      }
    }
    if (allQ.length < 4) {
      logHandler.info('Got less than 4 questions -> creating empty questions');
      while (allQ.length < 4) {
        allQ.add(AccelQuestion.empty());
      }
    }
    selectedMatch = AccelMatch(matchName: selectedMatch.matchName, questions: allQ);
    logHandler.info('Loaded ${selectedMatch.questions.length} questions from excel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(
        context,
        'Quản lý câu hỏi tăng tốc',
        actions: [
          const KLIHelpButton(
            content: '''
              Thông tin câu hỏi: câu hỏi, câu trả lời, giải thích, ảnh (ít nhất 1).
              
              Chọn trận đấu: Chọn trận đấu để hiện các câu hỏi.

              Sửa câu hỏi: Sửa câu hỏi đang chọn.
              Nhập từ file: Nhập câu hỏi từ file Excel.
              Xóa câu hỏi: Xóa toàn bộ câu hỏi của trận đang chọn.
              
              Thêm ảnh: Thêm ảnh của câu hỏi đang chọn. Ảnh được thêm sau được lưu cuối.
              Xóa ảnh: Xóa ảnh đang xem của câu hỏi đang chọn.
              Loại câu hỏi được xác định bằng số lượng ảnh. 1 ảnh: IQ, 2 ảnh: Sắp xếp, 3+ ảnh: chuỗi hình ảnh.
              Có thể xem các ảnh bằng phím mũi tên.
              
              Định dạng file Excel:
              - Chỉ lấy câu hỏi ở sheet đầu
              - Cột 1: STT
              - Cột 2: Câu hỏi
              - Cột 3: Đáp án
              - Cột 4: Giải thích''',
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
            selectedMatch = await DataManager.getMatchQuestions<AccelMatch>(value!);
            selectedQuestionIndex = -1;
            selectedImageIndex = -1;
            setState(() {});
          }),
          KLIButton(
            'Sửa câu hỏi${selectedQuestionIndex >= 0 ? ' ${selectedQuestionIndex + 1}' : ''}',
            enableCondition: selectedQuestionIndex >= 0,
            onPressed: () async {
              final newQ = await Navigator.of(context).push<AccelQuestion>(DialogRoute<AccelQuestion>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => AccelQuestionEditor(question: selectedQuestion),
              ));
              if (newQ != null) {
                selectedMatch.questions[selectedQuestionIndex] = newQ;
                await DataManager.updateQuestions<AccelMatch>(selectedMatch);
              }
              setState(() {});
            },
          ),
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
                  maxColumnCount: 4,
                  maxSheetCount: 1,
                  columnWidths: const [100, 400, 150, 400, 200],
                ),
              ));

              if (data == null) return;

              await getNewQuestion(data);
              await DataManager.saveNewQuestions<AccelMatch>(selectedMatch);
              selectedQuestionIndex = -1;
              selectedImageIndex = -1;
              setState(() {});
            },
          ),
          KLIButton(
            'Xóa câu hỏi',
            enableCondition: hasSelectedMatch,
            enabledLabel: 'Xóa toàn bộ câu hỏi của phần thi hiện tại',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              await confirmDialog(
                context,
                message: 'Bạn có muốn xóa tất cả câu hỏi tăng tốc của trận: ${selectedMatch.matchName}?',
                acceptLogMessage: 'Removed all accel questions for match: ${selectedMatch.matchName}',
                onAccept: () async {
                  if (mounted) {
                    showToastMessage(context, 'Đã xóa (match: ${selectedMatch.matchName})');
                  }
                  await DataManager.removeQuestionsOfMatch<AccelMatch>(selectedMatch);
                  selectedMatch = AccelMatch(
                    matchName: selectedMatch.matchName,
                    questions: List.filled(4, null),
                  );
                  selectedQuestionIndex = -1;
                  selectedImageIndex = -1;
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
        padding: const EdgeInsets.symmetric(horizontal: 75),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            questionList(),
            imageManager(),
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
            padding: EdgeInsets.only(top: 32, bottom: 64),
            child: Text('Danh sách câu hỏi', style: TextStyle(fontSize: fontSizeLarge)),
          ),
          if (!hasSelectedMatch)
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.onBackground),
              ),
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 700),
              child: const Material(child: Center(child: Text('Chưa chọn trận đấu'))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              itemCount: 4,
              separatorBuilder: (_, index) => const SizedBox(height: 20),
              itemBuilder: (_, index) {
                final q = selectedMatch.questions[index];

                return ListTile(
                  leading: Text("${index + 1}"),
                  tileColor: Theme.of(context).colorScheme.background,
                  leadingAndTrailingTextStyle: const TextStyle(
                    fontSize: fontSizeMedium,
                    overflow: TextOverflow.fade,
                  ),
                  title: Text(
                    q?.question ?? '',
                    style: const TextStyle(fontSize: fontSizeMedium),
                  ),
                  subtitle: Text(q?.type != null ? 'Loại: ${AccelQuestion.mapTypeDisplay(q!.type)}' : ''),
                  subtitleTextStyle: const TextStyle(fontSize: fontSizeSmall),
                  trailing: Container(
                    constraints: const BoxConstraints(maxHeight: 100, maxWidth: 400),
                    child: Text(q?.answer ?? ''),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      width: 2,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  onTap: () async {
                    selectedQuestionIndex = index;
                    if (q == null) {
                      logHandler.info('Selected question is null, creating new question');
                      selectedQuestion = AccelQuestion.empty();
                      selectedMatch.questions[index] = selectedQuestion;
                      await DataManager.updateQuestions<AccelMatch>(selectedMatch);
                    } else {
                      selectedQuestion = q;
                    }
                    selectedImageIndex = selectedQuestion.imagePaths.isNotEmpty ? 0 : -1;
                    setState(() {});
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget imageManager() {
    bool imageFound = false;
    String fullImagePath = '';
    if (selectedQuestion.imagePaths.isNotEmpty && selectedImageIndex >= 0) {
      fullImagePath = StorageHandler.getFullPath(selectedQuestion.imagePaths[selectedImageIndex]);
      imageFound = File(fullImagePath).existsSync();
    }

    return Flexible(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 32, bottom: 16),
            child: Text('Ảnh', style: TextStyle(fontSize: fontSizeLarge)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              KLIButton(
                'Thêm ảnh',
                enableCondition: selectedQuestionIndex >= 0,
                fontSize: fontSizeSmall,
                onPressed: () async {
                  logHandler
                      .info('Selecting image at ${StorageHandler.getRelative(storageHandler.mediaDir)}');
                  final result = await FilePicker.platform.pickFiles(
                    dialogTitle: 'Select Image',
                    initialDirectory: storageHandler.mediaDir.replaceAll('/', '\\'),
                    type: FileType.image,
                  );

                  if (result == null) return;

                  final p = result.files.single.path!;
                  selectedQuestion.imagePaths.add(StorageHandler.getRelative(p));
                  selectedQuestion.type =
                      AccelQuestion.getTypeFromImageCount(selectedQuestion.imagePaths.length);
                  if (selectedImageIndex < 0) selectedImageIndex = 0;
                  await DataManager.updateQuestions<AccelMatch>(selectedMatch);
                  logHandler.info('Chose ${StorageHandler.getRelative(p)}');
                  setState(() {});
                },
              ),
              KLIButton(
                'Xóa ảnh: $selectedImageIndex',
                enableCondition: selectedQuestionIndex >= 0 && selectedImageIndex >= 0,
                fontSize: fontSizeSmall,
                onPressed: () async {
                  logHandler.info('Removing image $selectedImageIndex');
                  selectedQuestion.imagePaths.removeAt(selectedImageIndex);
                  if (selectedQuestion.imagePaths.isNotEmpty) {
                    if (selectedImageIndex > 0) selectedImageIndex--;
                  } else {
                    selectedImageIndex = -1;
                  }
                  selectedQuestion.type =
                      AccelQuestion.getTypeFromImageCount(selectedQuestion.imagePaths.length);
                  await DataManager.updateQuestions<AccelMatch>(selectedMatch);
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.onBackground),
            ),
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
            child: !hasSelectedMatch || selectedQuestionIndex < 0 || !imageFound
                ? Material(
                    child: Center(
                      child: Text(!hasSelectedMatch
                          ? 'Chưa chọn trận đấu'
                          : selectedQuestionIndex < 0
                              ? 'Chưa chọn câu hỏi'
                              : selectedQuestion.imagePaths.isEmpty
                                  ? 'Không có ảnh'
                                  : 'Không tìm thấy ảnh $fullImagePath'),
                    ),
                  )
                : Image.file(File(fullImagePath)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: selectedQuestionIndex >= 0 && selectedImageIndex > 0
                    ? () {
                        setState(() => selectedImageIndex--);
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                onPressed:
                    selectedQuestionIndex >= 0 && selectedImageIndex < selectedQuestion.imagePaths.length - 1
                        ? () => setState(() => selectedImageIndex++)
                        : null,
              )
            ],
          )
        ],
      ),
    );
  }
}
