import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../data_manager.dart';
import '../import_dialog.dart';
import 'start_question_editor.dart';

class StartQuestionManager extends StatefulWidget {
  const StartQuestionManager({super.key});

  @override
  State<StartQuestionManager> createState() => _StartQuestionManagerState();
}

class _StartQuestionManagerState extends State<StartQuestionManager> {
  bool isLoading = true, hasSelectedMatch = false;
  List<String> matchNames = [];
  late StartMatch selectedMatch;
  int sortPlayerPos = -1;
  StartQuestionSubject? sortType;

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Start Manager', d: 1);
    logHandler.depth = 2;
    selectedMatch = StartMatch.empty();
    DataManager.getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await DataManager.removeDeletedMatchQuestions<StartMatch>();
    });
  }

  Future<void> getNewQuestion(Map<String, dynamic> data) async {
    final List<StartQuestion> questions = [];
    int idx = 0;

    for (var sheet in data.keys) {
      for (final r in (data[sheet] as List<Map>)) {
        try {
          final v = r.values;
          questions.add(StartQuestion(
            pos: idx + 1,
            subject: StartQuestion.mapTypeValue(v.elementAt(1)),
            question: v.elementAt(2),
            answer: v.elementAt(3),
          ));
        } on StateError {
          showToastMessage(context, 'Sai định dạng (lĩnh vực)');
          break;
        }
      }
      idx++;
    }
    selectedMatch = StartMatch(matchName: selectedMatch.matchName, questions: questions);
    logHandler.info('Loaded ${selectedMatch.questionCount} questions from excel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(
        context,
        'Quản lý câu hỏi khởi động',
        actions: [
          const KLIHelpButton(
            content: '''
              Thông tin câu hỏi: Thứ tự thí sinh, lĩnh vực, nội dung, đáp án.

              Chọn trận đấu: Chọn trận đấu để hiện các câu hỏi.
              Lọc vị trí: Lọc câu hỏi theo vị trí của thí sinh.
              Lọc lĩnh vực: Lọc câu hỏi theo lĩnh vực. Có thể kết hợp 2 chế độ lọc.

              Thêm câu hỏi: Thêm câu hỏi mới cho trận đấu đang chọn.
              Nhập từ file: Nhập câu hỏi từ file Excel.
              Xóa câu hỏi: Xóa toàn bộ câu hỏi của trận đang chọn.

              Bấm vào câu hỏi để chỉnh sửa. Xóa câu hỏi bằng cách bấm vào biểu tượng xóa.

              Danh sách lĩnh vực: Toán, Vật lý, Hóa học, Sinh học, Văn học, Lịch sử, Địa lý, Tiếng Anh, Thể thao, Nghệ thuật, HBC.
              
              Định dạng file Excel:
              - Mỗi sheet là câu hỏi 1 thí sinh (4 sheet)
              - Cột 1: STT
              - Cột 2: Lĩnh vực (cần đúng với danh sách lĩnh vực)
              - Cột 3: Nội dung câu hỏi
              - Cột 4: Đáp án''',
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
                questionList(),
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
            selectedMatch = await DataManager.getMatchQuestions<StartMatch>(value!);
            setState(() {});
          }),
          // sort player pos
          DropdownMenu(
            label: const Text('Lọc vị trí'),
            initialSelection: -1,
            enabled: hasSelectedMatch,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: -1, label: 'Tất cả'),
              for (var i = 1; i <= 4; i++)
                DropdownMenuEntry(
                  value: i,
                  label: '$i',
                )
            ],
            onSelected: (value) async {
              sortPlayerPos = value!;
              logHandler.info('Sort position: $value');
              setState(() {});
            },
          ),
          // sort subject
          DropdownMenu(
            label: const Text('Lọc lĩnh vực'),
            initialSelection: null,
            enabled: hasSelectedMatch,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: null, label: 'Tất cả'),
              for (final s in StartQuestionSubject.values)
                DropdownMenuEntry(
                  value: s,
                  label: StartQuestion.mapTypeDisplay(s),
                )
            ],
            onSelected: (value) async {
              logHandler.info('Sort subject: $value');
              sortType = value;
              setState(() {});
            },
          ),
          KLIButton(
            'Thêm câu hỏi',
            enableCondition: hasSelectedMatch,
            enabledLabel: 'Thêm 1 câu hỏi cho phần thi',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              final ret = await Navigator.of(context).push<StartQuestion>(DialogRoute<StartQuestion>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => const StartQuestionEditor(question: null),
              ));

              if (ret == null) return;

              selectedMatch.questions.add(ret);
              await DataManager.updateQuestions<StartMatch>(selectedMatch);
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
                  maxSheetCount: 4,
                  columnWidths: const [100, 150, 600, 200, 200],
                ),
              ));

              if (data == null) return;

              await getNewQuestion(data);
              await DataManager.saveNewQuestions<StartMatch>(selectedMatch);

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
                message: 'Bạn có muốn xóa tất cả câu hỏi khởi động của trận: ${selectedMatch.matchName}?',
                acceptLogMessage: 'Removed all start questions for match: ${selectedMatch.matchName}',
                onAccept: () async {
                  if (mounted) showToastMessage(context, 'Đã xóa (trận: ${selectedMatch.matchName})');

                  await DataManager.removeQuestionsOfMatch<StartMatch>(selectedMatch);
                  selectedMatch = StartMatch.empty(selectedMatch.matchName);
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget questionList() {
    List<StartQuestion> filtered = [];
    for (var q in selectedMatch.questions) {
      if (sortType != null && q.subject != sortType) continue;
      if (sortPlayerPos >= 0 && q.pos != sortPlayerPos) continue;
      filtered.add(q);
    }

    List<double> widthRatios = [0.07, 0.1, 0.4, 0.1, 0.02];

    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Theme.of(context).colorScheme.onBackground),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            customListTile(context, columns: [
              (const Text('Thí sinh', textAlign: TextAlign.center), widthRatios[0]),
              (const Text('Lĩnh vực'), widthRatios[1]),
              (const Text('Câu hỏi', textAlign: TextAlign.left), widthRatios[2]),
              (const Text('Đáp án', textAlign: TextAlign.right), widthRatios[3]),
              (const Text('', textAlign: TextAlign.right), widthRatios[4]),
            ]),
            Flexible(
              child: Material(
                borderRadius: BorderRadius.circular(10),
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final q = filtered[index];

                    return customListTile(
                      context,
                      columns: [
                        (Text('${q.pos}', textAlign: TextAlign.center), widthRatios[0]),
                        (Text(StartQuestion.mapTypeDisplay(q.subject)), widthRatios[1]),
                        (Text(q.question, textAlign: TextAlign.left), widthRatios[2]),
                        (Text(q.answer, textAlign: TextAlign.right), widthRatios[3]),
                        (
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await confirmDialog(
                                context,
                                message: 'Bạn có muốn xóa câu hỏi này?\n"${q.question}"',
                                acceptLogMessage: 'Removed start question: pos=${q.pos}, idx=$index',
                                onAccept: () async {
                                  selectedMatch.questions.removeWhere((e) => e == q);
                                  await DataManager.updateQuestions<StartMatch>(selectedMatch);
                                  setState(() {});
                                },
                              );
                            },
                          ),
                          widthRatios[4],
                        )
                      ],
                      onTap: () async {
                        final ret =
                            await Navigator.of(context).push<StartQuestion>(DialogRoute<StartQuestion>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => StartQuestionEditor(question: q),
                        ));

                        if (ret == null) return;

                        selectedMatch.questions[selectedMatch.questions.indexOf(q)] = ret;
                        await DataManager.updateQuestions<StartMatch>(selectedMatch);

                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
