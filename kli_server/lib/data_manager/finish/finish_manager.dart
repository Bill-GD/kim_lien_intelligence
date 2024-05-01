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
    logger.i('Finish question manager init');
    selectedMatch = FinishMatch(match: '', questions: []);
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

    selectedMatch = FinishMatch(match: matchNames[selectedMatchIndex], questions: questions);
    logger.i('Loaded ${selectedMatch.match}');
  }

  Future<void> saveNewQuestions() async {
    logger.i('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<FinishMatch>(
      FinishMatch.fromJson,
      storageHandler!.finishSaveFile,
    );
    saved.removeWhere((e) => e.match == selectedMatch.match);
    saved.add(selectedMatch);
    await DataManager.overwriteSave(saved, storageHandler!.finishSaveFile);
  }

  Future<void> updateQuestions(FinishMatch fMatch) async {
    logger.i('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<FinishMatch>(
      FinishMatch.fromJson,
      storageHandler!.finishSaveFile,
    );
    saved.removeWhere((e) => e.match == fMatch.match);
    saved.add(fMatch);
    await DataManager.overwriteSave(saved, storageHandler!.finishSaveFile);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await DataManager.getAllSavedQuestions<FinishMatch>(
      FinishMatch.fromJson,
      storageHandler!.finishSaveFile,
    );
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logger.i('Loaded ${selectedMatch.questions.length} finish questions of ${selectedMatch.match}');
    } on StateError {
      logger.i('Finish match $match not found, temp empty match created');
      selectedMatch = FinishMatch(match: match, questions: []);
    }
  }

  Future<void> removeDeletedMatchQuestions() async {
    logger.i('Removing questions of deleted matches');
    var saved = await DataManager.getAllSavedQuestions<FinishMatch>(
      FinishMatch.fromJson,
      storageHandler!.finishSaveFile,
    );
    saved = saved.where((e) => matchNames.contains(e.match)).toList();
    await DataManager.overwriteSave(saved, storageHandler!.finishSaveFile);
  }

  Future<void> removeMatch(FinishMatch fMatch) async {
    logger.i('Removing questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await DataManager.getAllSavedQuestions<FinishMatch>(
      FinishMatch.fromJson,
      storageHandler!.finishSaveFile,
    );
    saved.removeWhere((e) => e.match == fMatch.match);
    await DataManager.overwriteSave(saved, storageHandler!.finishSaveFile);
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
            logger.i('Selected match: ${matchNames[selectedMatchIndex]}');
            await loadMatchQuestions(matchNames[selectedMatchIndex]);
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
              logger.i('Sort position: $value');
              setState(() {});
            },
          ),
          button(
            context,
            'Thêm câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              final newQ = await Navigator.of(context).push<FinishQuestion>(DialogRoute<FinishQuestion>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => const FinishQuestionEditor(),
              ));
              if (newQ != null) {
                selectedMatch.questions.add(newQ);
                await updateQuestions(selectedMatch);
              }
              setState(() {});
            },
          ),
          button(
            context,
            'Nhập từ file',
            enableCondition: selectedMatchIndex >= 0,
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
              await saveNewQuestions();
              setState(() {});
            },
          ),
          button(
            context,
            'Xóa câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
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
                  await removeMatch(selectedMatch);
                  selectedMatch = FinishMatch(match: '', questions: []);
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

    List<double> widthRatios = [0.035, 0.4, 0.1, 0.15, 0.03];

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
                                  await updateQuestions(selectedMatch);
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
                          await updateQuestions(selectedMatch);
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
