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
    storageHandler!.readFromFile(storageHandler!.matchSaveFile).then((value) async {
      if (value.isNotEmpty) {
        matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
      }
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

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler!.readFromExcel(path, 4);

    logger.i('Extracting data from excel');

    final Map<int, List<StartQuestion>> allQ = {};
    int idx = 0;
    for (var name in data.keys) {
      final List<StartQuestion> questions = [];

      for (final e in (data[name] as List<Map>)) {
        final v = e.values;
        final q = StartQuestion(StartQuestion.mapType(v.elementAt(1)), v.elementAt(2), v.elementAt(3));
        questions.add(q);
      }
      allQ.putIfAbsent(idx, () => questions);
      idx++;
    }
    selectedMatch = StartMatch(match: matchNames[selectedMatchIndex], questions: allQ);
    logger.i('Loaded ${selectedMatch!.questionCount} questions from excel');
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

  Future<void> overwriteSave(List<StartMatch> q) async {
    logger.i('Overwriting save');
    await storageHandler!.writeToFile(storageHandler!.startSaveFile, jsonEncode(q));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Question Manager'),
        surfaceTintColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(fontSize: fontSizeXL),
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 1.1,
      ),
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
          DropdownMenu(
            label: const Text('Match'),
            dropdownMenuEntries: [
              for (var i = 0; i < matchNames.length; i++)
                DropdownMenuEntry(
                  value: matchNames[i],
                  label: matchNames[i],
                )
            ],
            onSelected: (value) async {
              selectedMatchIndex = matchNames.indexOf(value!);
              logger.i('Selected match: ${matchNames[selectedMatchIndex]}');
              await loadMatchQuestions(matchNames[selectedMatchIndex]);
              setState(() {});
            },
          ),
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
            'Import Questions',
            selectedMatchIndex < 0
                ? null
                : () async {
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
          button(
            context,
            'Export Excel',
            selectedMatchIndex < 0
                ? null
                : () async {
                    String fileName =
                        'KĐ_${matchNames[selectedMatchIndex]}_${DateTime.now().toString().split('.').first.replaceAll(RegExp('[:-]'), '_')}.xlsx';
                    logger.i('Exporting ${matchNames[selectedMatchIndex]} start questions to $fileName');

                    final data = (jsonDecode(
                      await storageHandler!.readFromFile(storageHandler!.startSaveFile),
                    ) as List)
                        .map((e) => StartMatch.fromJson(e))
                        .toList();

                    final newData = <String, List>{};

                    int idx = 0;
                    for (final m in data) {
                      for (final qL in m.questions.entries) {
                        final kName = 'Thí sinh ${qL.key + 1}';
                        final qMap = qL.value.map((q) {
                          idx++;
                          return {
                            'STT': '$idx',
                            'Loại câu hỏi': StartQuestion.mapTypeDisplay(q.subject),
                            'Nội dung': q.question,
                            'Đáp án': q.answer,
                          };
                        }).toList();

                        newData[kName] = qMap;
                      }
                    }

                    await storageHandler!.writeToExcel(fileName, newData);
                    if (mounted) {
                      showToastMessage(
                        context,
                        'Saved to ${storageHandler!.getRelative(storageHandler!.excelOutput)}/$fileName',
                      );
                    }
                  },
          ),
          button(
            context,
            'Remove Questions',
            selectedMatchIndex < 0
                ? null
                : () async {
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
                      showToastMessage(
                        context,
                        'Removed questions for match: ${matchNames[selectedMatchIndex]}',
                      );
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
    List<MapEntry<MapEntry<int, int>, StartQuestion>> filtered = [];
    if (selectedMatch != null) {
      selectedMatch!.questions.forEach((pos, qL) {
        for (int i = 0; i < qL.length; i++) {
          if (sortType != null && qL[i].subject != sortType) continue;
          if (sortPlayerPos >= 0 && pos != sortPlayerPos) continue;
          filtered.add(MapEntry(MapEntry(pos, i), qL[i]));
        }
      });
    }

    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Theme.of(context).colorScheme.onBackground),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            customListTile('Thí sinh', 'Subject', 'Question', 'Answer'),
            Flexible(
              child: Material(
                borderRadius: BorderRadius.circular(20),
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final q = filtered[index];

                    return customListTile(
                      '${q.key.key + 1}',
                      StartQuestion.mapTypeDisplay(q.value.subject),
                      q.value.question,
                      q.value.answer,
                      onTap: () async {
                        final newQ =
                            await Navigator.of(context).push<StartQuestion>(DialogRoute<StartQuestion>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => StartEditorDialog(question: q.value),
                        ));
                        if (newQ != null) {
                          selectedMatch!.questions[q.key.key]![q.key.value] = newQ;
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

  Widget customListTile(String col1, String col2, String col3, String col4, {void Function()? onTap}) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(right: 24, top: 24, bottom: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 130),
                child: Text(
                  col1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 150, maxWidth: 150),
                child: Text(
                  col2,
                  // textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
              ),
              Expanded(
                child: Text(
                  col3,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 290, maxWidth: 290),
                child: Text(
                  col4,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
