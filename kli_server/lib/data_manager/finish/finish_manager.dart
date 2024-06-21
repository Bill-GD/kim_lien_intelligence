import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../import_dialog.dart';
import 'finish_question_editor.dart';

class FinishManager extends StatefulWidget {
  const FinishManager({super.key});

  @override
  State<FinishManager> createState() => _FinishManagerState();
}

class _FinishManagerState extends State<FinishManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  int selectedMatchIndex = -1, sortPoint = -1;
  late FinishMatch selectedMatch;
  final obstacleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Finish Manager', d: 1);
    logHandler.depth = 2;
    selectedMatch = FinishMatch.empty();
    DataManager.getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await DataManager.removeDeletedMatchQuestions<FinishMatch>();
    });
  }

  @override
  void dispose() {
    obstacleController.dispose();
    super.dispose();
  }

  Future<void> getNewQuestion(Map<String, dynamic> data) async {
    final List<FinishQuestion> questions = [];
    for (int i = 0; i < data.keys.length; i++) {
      for (final r in (data[data.keys.elementAt(i)] as List<Map>)) {
        final v = r.values;
        final q = FinishQuestion(
          point: (i + 1) * 10,
          question: v.elementAt(1),
          answer: v.elementAt(2),
          explanation: v.elementAt(3) == 'null' ? '' : v.elementAt(3),
        );
        questions.add(q);
      }
    }

    selectedMatch = FinishMatch(matchName: matchNames[selectedMatchIndex], questions: questions);
    logHandler.info('Loaded ${questions.length} Finish questions of ${selectedMatch.matchName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Quản lý câu hỏi về đích'),
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
            selectedMatchIndex = matchNames.indexOf(value!);
            logHandler.info('Selected match: ${matchNames[selectedMatchIndex]}');
            selectedMatch = await DataManager.getMatchQuestions<FinishMatch>(matchNames[selectedMatchIndex]);
            setState(() {});
          }),
          // sort point
          DropdownMenu(
            label: const Text('Lọc điểm'),
            initialSelection: -1,
            enabled: selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: -1, label: 'Tất cả'),
              for (var i = 1; i <= 3; i++)
                DropdownMenuEntry(
                  value: i * 10,
                  label: '${i * 10}',
                )
            ],
            onSelected: (value) async {
              sortPoint = value!;
              logHandler.info('Sort position: $value');
              setState(() {});
            },
          ),
          KLIButton(
            'Thêm câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
            enabledLabel: 'Thêm 1 câu hỏi cho phần thi',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              final newQ = await Navigator.of(context).push<FinishQuestion>(DialogRoute<FinishQuestion>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => const FinishQuestionEditor(),
              ));
              if (newQ != null) {
                selectedMatch.questions.add(newQ);
                await DataManager.updateQuestions<FinishMatch>(selectedMatch);
              }
              setState(() {});
            },
          ),
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
                  maxColumnCount: 4,
                  maxSheetCount: 3,
                  columnWidths: const [50, 500, 150, 400, 200],
                ),
              ));

              if (data == null) return;

              await getNewQuestion(data);
              await DataManager.saveNewQuestions<FinishMatch>(selectedMatch);
              setState(() {});
            },
          ),
          KLIButton(
            'Xóa câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
            enabledLabel: 'Xóa toàn bộ câu hỏi của phần thi hiện tại',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              await confirmDialog(
                context,
                message:
                    'Bạn có muốn xóa tất cả câu hỏi về đích của trận: ${matchNames[selectedMatchIndex]}?',
                acceptLogMessage: 'Removed all finish questions for match: ${matchNames[selectedMatchIndex]}',
                onAccept: () async {
                  if (mounted) {
                    showToastMessage(context, 'Đã xóa (match: ${matchNames[selectedMatchIndex]})');
                  }
                  await DataManager.removeQuestionsOfMatch<FinishMatch>(selectedMatch);
                  selectedMatch = FinishMatch.empty();
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
    List<(int, FinishQuestion)> filtered = [];
    for (int i = 0; i < selectedMatch.questions.length; i++) {
      if (sortPoint > 0 && selectedMatch.questions[i].point != sortPoint) continue;
      filtered.add((i, selectedMatch.questions[i]));
    }

    List<double> widthRatios = [0.07, 0.4, 0.1, 0.15, 0.03];

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
              (const Text('Điểm', textAlign: TextAlign.center), widthRatios[0]),
              (const Text('Câu hỏi'), widthRatios[1]),
              (const Text('Đáp án'), widthRatios[2]),
              (const Text('Giải thích'), widthRatios[3]),
              (const Text(''), widthRatios[4]),
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
                        (Text('${q.$2.point}', textAlign: TextAlign.center), widthRatios[0]),
                        (Text(q.$2.question), widthRatios[1]),
                        (Text(q.$2.answer), widthRatios[2]),
                        (Text(q.$2.explanation), widthRatios[3]),
                        (
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await confirmDialog(
                                context,
                                message: 'Bạn có muốn xóa câu hỏi này?\n"${q.$2.question}"',
                                acceptLogMessage: 'Removed finish question (p=${q.$2.point})',
                                onAccept: () async {
                                  selectedMatch.questions.removeAt(q.$1);
                                  await DataManager.updateQuestions<FinishMatch>(selectedMatch);
                                  setState(() {});
                                },
                              );
                            },
                          ),
                          widthRatios[4],
                        )
                      ],
                      onTap: () async {
                        final newQ = await Navigator.of(context).push<FinishQuestion>(
                          DialogRoute<FinishQuestion>(
                              context: context,
                              barrierDismissible: false,
                              barrierLabel: '',
                              builder: (_) => FinishQuestionEditor(question: q.$2)),
                        );

                        if (newQ != null) {
                          selectedMatch.questions[q.$1] = newQ;
                          await DataManager.updateQuestions<FinishMatch>(selectedMatch);
                        }
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
