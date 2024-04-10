import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';
import 'start_question_editor.dart';

class StartQuestionManager extends StatefulWidget {
  const StartQuestionManager({super.key});

  @override
  State<StartQuestionManager> createState() => _StartQuestionManagerState();
}

class _StartQuestionManagerState extends State<StartQuestionManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  StartMatch? selectedMatch;
  int selectedMatchIndex = -1, sortPlayerPos = -1;
  QuestionSubject? sortType;

  @override
  void initState() {
    super.initState();
    logger.i('Start question manager init');
    getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await removeDeletedMatchQuestions();
    });
  }

  Future<List<StartMatch>> getAllSavedQuestions() async {
    logger.i('Getting all saved questions');
    final saved = await storageHandler!.readFromFile(storageHandler!.startSaveFile);
    if (saved.isEmpty) return [];
    final q = (jsonDecode(saved) as List).map((e) => StartMatch.fromJson(e)).toList();
    return q;
  }

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler!.readFromExcel(path, 4);

    logger.i('Extracting data from excel');

    final Map<int, List<StartQuestion>> allQ = {};
    int idx = 0;
    for (var name in data.keys) {
      final List<StartQuestion> questions = [];

      for (final r in (data[name] as List<Map>)) {
        final v = r.values;
        final q = StartQuestion(StartQuestion.mapType(v.elementAt(1)), v.elementAt(2), v.elementAt(3));
        questions.add(q);
      }
      allQ.putIfAbsent(idx, () => questions);
      idx++;
    }
    selectedMatch = StartMatch(match: matchNames[selectedMatchIndex], questions: allQ);
    logger.i('Loaded ${selectedMatch!.questionCount} questions from excel');
  }

  Future<void> saveNewQuestions() async {
    logger.i('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await getAllSavedQuestions();
    saved.removeWhere((e) => e.match == selectedMatch!.match);
    saved.add(selectedMatch!);
    await overwriteSave(saved);
  }

  Future<void> updateQuestions(StartMatch sMatch) async {
    logger.i('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await getAllSavedQuestions();
    saved.removeWhere((e) => e.match == sMatch.match);
    saved.add(sMatch);
    await overwriteSave(saved);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await getAllSavedQuestions();
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logger.i('Loaded ${selectedMatch!.questionCount} questions of match ${selectedMatch!.match}');
    } on StateError {
      selectedMatch = null;
    }
  }

  Future<void> removeDeletedMatchQuestions() async {
    logger.i('Removing questions of deleted matches');
    var saved = await getAllSavedQuestions();
    saved = saved.where((e) => matchNames.contains(e.match)).toList();
    await overwriteSave(saved);
  }

  Future<void> removeMatch(StartMatch sMatch) async {
    logger.i('Removing questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await getAllSavedQuestions();
    saved.removeWhere((e) => e.match == sMatch.match);
    await overwriteSave(saved);
  }

  Future<void> overwriteSave(List<StartMatch> q) async {
    logger.i('Overwriting save');
    await storageHandler!.writeToFile(storageHandler!.startSaveFile, jsonEncode(q));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Start Question Manager'),
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
          // sort player pos
          DropdownMenu(
            label: const Text('Filter position'),
            initialSelection: -1,
            enabled: selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: -1, label: 'All'),
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
            label: const Text('Filter subject'),
            initialSelection: null,
            enabled: selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: null, label: 'All'),
              for (final s in QuestionSubject.values)
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
            'Add Question',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              final ret =
                  await Navigator.of(context).push<(int, StartQuestion)>(DialogRoute<(int, StartQuestion)>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => StartEditorDialog(question: null, playerPos: -1),
              ));
              if (ret case (final newP, final newQ)?) {
                selectedMatch!.questions[newP]!.add(newQ);
                await updateQuestions(selectedMatch!);
              }
              setState(() {});
            },
          ),
          button(
            context,
            'Import Questions',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              logger.i('Import new questions (.xlsx)');

              final result = await FilePicker.platform.pickFiles(
                dialogTitle: 'Select File',
                initialDirectory: storageHandler!.newDataDir.replaceAll('/', '\\'),
                type: FileType.custom,
                allowedExtensions: ['xlsx'],
              );

              if (result != null) {
                final p = result.files.single.path!;
                logger.i(
                  'Chose ${storageHandler!.getRelative(p)} for match ${matchNames[selectedMatchIndex]}',
                );
                await getNewQuestion(p);
                await saveNewQuestions();
                setState(() {});
                return;
              }
              logger.i('No file selected');
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
            'Remove Questions',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: Text(
                      'Are you sure you want to delete questions for match: ${matchNames[selectedMatchIndex]}?',
                    ),
                    actionsAlignment: MainAxisAlignment.spaceEvenly,
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Yes', style: TextStyle(fontSize: fontSizeMedium)),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                      TextButton(
                        child: const Text('No', style: TextStyle(fontSize: fontSizeMedium)),
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                      ),
                    ],
                  );
                },
              ).then((value) async {
                if (value != true) return;
                showToastMessage(context, 'Removed questions for match: ${matchNames[selectedMatchIndex]}');
                await removeMatch(selectedMatch!);
                selectedMatch = null;
                setState(() {});
              });
            },
          ),
        ],
      ),
    );
  }

  Widget questionList() {
    List<(int, int, StartQuestion)> filtered = [];
    if (selectedMatch != null) {
      selectedMatch!.questions.forEach((pos, qL) {
        for (int i = 0; i < qL.length; i++) {
          if (sortType != null && qL[i].subject != sortType) continue;
          if (sortPlayerPos >= 0 && pos != sortPlayerPos) continue;
          filtered.add((i, pos, qL[i]));
        }
      });
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
              (const Text('Subject'), widthRatios[1]),
              (const Text('Question', textAlign: TextAlign.left), widthRatios[2]),
              (const Text('Answer', textAlign: TextAlign.right), widthRatios[3]),
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
                              selectedMatch!.questions[q.$2]?.removeAt(q.$1);
                              await updateQuestions(selectedMatch!);
                              logger.i('Removed question: pos=${q.$2}, idx=${q.$1}');
                              setState(() {});
                              return;
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
                            selectedMatch!.questions[q.$2]![q.$1] = newQ;
                          } else {
                            selectedMatch!.questions[q.$2]!.removeAt(q.$1);
                            selectedMatch!.questions[newP]!.add(newQ);
                          }
                          await updateQuestions(selectedMatch!);
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
