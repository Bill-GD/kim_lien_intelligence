import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';
import '../import_dialog.dart';
import 'start_question_editor.dart';

class StartQuestionManager extends StatefulWidget {
  const StartQuestionManager({super.key});

  @override
  State<StartQuestionManager> createState() => _StartQuestionManagerState();
}

class _StartQuestionManagerState extends State<StartQuestionManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  late StartMatch selectedMatch;
  int selectedMatchIndex = -1, sortPlayerPos = -1;
  StartQuestionSubject? sortType;

  @override
  void initState() {
    super.initState();
    logger.i('Start question manager init');
    selectedMatch = StartMatch(match: '', questions: {});
    getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await removeDeletedMatchQuestions();
    });
  }

  Future<void> getNewQuestion(Map<String, dynamic> data) async {
    final Map<int, List<StartQuestion>> allQ = {};
    int idx = 0;
    for (var sheet in data.keys) {
      final List<StartQuestion> questions = [];

      for (final r in (data[sheet] as List<Map>)) {
        try {
          final v = r.values;
          final q = StartQuestion(
            subject: StartQuestion.mapTypeValue(v.elementAt(1)),
            question: v.elementAt(2),
            answer: v.elementAt(3),
          );
          questions.add(q);
        } on StateError {
          showToastMessage(context, 'Sai định dạng (lĩnh vực)');
          break;
        }
      }
      allQ.putIfAbsent(idx, () => questions);
      idx++;
    }
    selectedMatch = StartMatch(match: matchNames[selectedMatchIndex], questions: allQ);
    logger.i('Loaded ${selectedMatch.questionCount} questions from excel');
  }

  Future<void> saveNewQuestions() async {
    logger.i('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<StartMatch>(
        StartMatch.fromJson, storageHandler!.startSaveFile);
    saved.removeWhere((e) => e.match == selectedMatch.match);
    saved.add(selectedMatch);
    await DataManager.overwriteSave(saved, storageHandler!.startSaveFile);
  }

  Future<void> updateQuestions(StartMatch sMatch) async {
    logger.i('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<StartMatch>(
        StartMatch.fromJson, storageHandler!.startSaveFile);
    saved.removeWhere((e) => e.match == sMatch.match);
    saved.add(sMatch);
    await DataManager.overwriteSave(saved, storageHandler!.startSaveFile);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await DataManager.getAllSavedQuestions<StartMatch>(
        StartMatch.fromJson, storageHandler!.startSaveFile);
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logger.i('Loaded ${selectedMatch.questionCount} start questions of match ${selectedMatch.match}');
    } on StateError {
      logger.i('Start match $match not found, temp empty match created');
      selectedMatch = StartMatch(match: match, questions: {});
    }
  }

  Future<void> removeDeletedMatchQuestions() async {
    logger.i('Removing questions of deleted matches');
    var saved = await DataManager.getAllSavedQuestions<StartMatch>(
        StartMatch.fromJson, storageHandler!.startSaveFile);
    saved = saved.where((e) => matchNames.contains(e.match)).toList();
    await DataManager.overwriteSave(saved, storageHandler!.startSaveFile);
  }

  Future<void> removeMatch(StartMatch sMatch) async {
    logger.i('Removing all questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await DataManager.getAllSavedQuestions<StartMatch>(
        StartMatch.fromJson, storageHandler!.startSaveFile);
    saved.removeWhere((e) => e.match == sMatch.match);
    await DataManager.overwriteSave(saved, storageHandler!.startSaveFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Quản lý câu hỏi khởi động'),
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
            selectedMatch.match = value;
            logger.i('Selected match: ${matchNames[selectedMatchIndex]}');
            await loadMatchQuestions(matchNames[selectedMatchIndex]);
            setState(() {});
          }),
          // sort player pos
          DropdownMenu(
            label: const Text('Lọc vị trí'),
            initialSelection: -1,
            enabled: selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: -1, label: 'Tất cả'),
              for (var i = 0; i < 4; i++)
                DropdownMenuEntry(
                  value: i,
                  label: '${i + 1}',
                )
            ],
            onSelected: (value) async {
              sortPlayerPos = value!;
              logger.i('Sort position: $value');
              setState(() {});
            },
          ),
          // sort subject
          DropdownMenu(
            label: const Text('Lọc lĩnh vực'),
            initialSelection: null,
            enabled: selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: null, label: 'Tất cả'),
              for (final s in StartQuestionSubject.values)
                DropdownMenuEntry(
                  value: s,
                  label: StartQuestion.mapTypeDisplay(s),
                )
            ],
            onSelected: (value) async {
              logger.i('Sort subject: $value');
              sortType = value;
              setState(() {});
            },
          ),
          button(
            context,
            'Thêm câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              final ret =
                  await Navigator.of(context).push<(int, StartQuestion)>(DialogRoute<(int, StartQuestion)>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => const StartEditorDialog(question: null, playerPos: -1),
              ));
              if (ret case (final newP, final newQ)?) {
                final qList = selectedMatch.questions[newP];
                if (qList == null) {
                  selectedMatch.questions[newP] = [newQ];
                } else {
                  qList.add(newQ);
                }
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
                  maxSheetCount: 4,
                  columnWidths: const [100, 150, 600, 200, 200],
                ),
              ));

              if (data == null) return;

              await getNewQuestion(data);
              await saveNewQuestions();

              setState(() {});
            },
          ),
          // button(
          //   context,
          //   'Export Excel',
          //   enableCondition: selectedMatchIndex >= 0,
          //   onPressed: () async {
          //     String fileName =
          //         'KĐ_${matchNames[selectedMatchIndex]}_${DateTime.now().toString().split('.').first.replaceAll(RegExp('[:-]'), '_')}.xlsx';
          //     logger.i('Exporting ${matchNames[selectedMatchIndex]} start questions to $fileName');

          //     final data = (jsonDecode(
          //       await storageHandler!.readFromFile(storageHandler!.startSaveFile),
          //     ) as List)
          //         .map((e) => StartMatch.fromJson(e))
          //         .toList();

          //     final newData = <String, List>{};

          //     int idx = 0;
          //     for (final m in data) {
          //       for (final qL in m.questions.entries) {
          //         final kName = 'Thí sinh ${qL.key + 1}';
          //         final qMap = qL.value.map((q) {
          //           idx++;
          //           return {
          //             'STT': '$idx',
          //             'Loại câu hỏi': StartQuestion.mapTypeDisplay(q.subject),
          //             'Nội dung': q.question,
          //             'Đáp án': q.answer,
          //           };
          //         }).toList();

          //         newData[kName] = qMap;
          //       }
          //     }

          //     await storageHandler!.writeToExcel(fileName, newData);
          //     if (mounted) {
          //       showToastMessage(
          //         context,
          //         'Saved to ${storageHandler!.getRelative(storageHandler!.excelOutput)}/$fileName',
          //       );
          //     }
          //   },
          // ),
          button(
            context,
            'Xóa câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              await confirmDialog(
                context,
                message:
                    'Bạn có muốn xóa tất cả câu hỏi khởi động của trận: ${matchNames[selectedMatchIndex]}?',
                acceptLogMessage: 'Removed all start questions for match: ${matchNames[selectedMatchIndex]}',
                onAccept: () async {
                  if (mounted) showToastMessage(context, 'Đã xóa (trận: ${matchNames[selectedMatchIndex]})');

                  // logPanelController!.addText('Removed questions (match: ${matchNames[selectedMatchIndex]})');
                  await removeMatch(selectedMatch);
                  selectedMatch = StartMatch(match: matchNames[selectedMatchIndex], questions: {});
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
    List<(int, int, StartQuestion)> filtered = [];
    selectedMatch.questions.forEach((pos, qL) {
      for (int i = 0; i < qL.length; i++) {
        if (sortType != null && qL[i].subject != sortType) continue;
        if (sortPlayerPos >= 0 && pos != sortPlayerPos) continue;
        filtered.add((i, pos, qL[i]));
      }
    });

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
                        (Text('${q.$2 + 1}', textAlign: TextAlign.center), widthRatios[0]),
                        (Text(StartQuestion.mapTypeDisplay(q.$3.subject)), widthRatios[1]),
                        (Text(q.$3.question, textAlign: TextAlign.left), widthRatios[2]),
                        (Text(q.$3.answer, textAlign: TextAlign.right), widthRatios[3]),
                        (
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await confirmDialog(
                                context,
                                message: 'Bạn có muốn xóa câu hỏi này?\n"${q.$3.question}"',
                                acceptLogMessage: 'Removed start question: pos=${q.$2}, idx=${q.$1}',
                                onAccept: () async {
                                  selectedMatch.questions[q.$2]?.removeAt(q.$1);
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
                        final ret = await Navigator.of(context)
                            .push<(int, StartQuestion)>(DialogRoute<(int, StartQuestion)>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => StartEditorDialog(question: q.$3, playerPos: q.$2),
                        ));
                        if (ret case (final newP, final newQ)?) {
                          if (newP == q.$2) {
                            selectedMatch.questions[q.$2]![q.$1] = newQ;
                          } else {
                            selectedMatch.questions[q.$2]!.removeAt(q.$1);
                            selectedMatch.questions[newP]!.add(newQ);
                          }
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
