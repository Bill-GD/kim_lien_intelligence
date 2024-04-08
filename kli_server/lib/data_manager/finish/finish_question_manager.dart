import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';
import 'finish_question_editor.dart';

class FinishQuestionManager extends StatefulWidget {
  const FinishQuestionManager({super.key});

  @override
  State<FinishQuestionManager> createState() => _FinishQuestionManagerState();
}

class _FinishQuestionManagerState extends State<FinishQuestionManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  int selectedMatchIndex = -1, sortPoint = -1;
  FinishMatch? selectedMatch;
  final obstacleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logger.i('Finish question manager init');
    storageHandler!.readFromFile(storageHandler!.matchSaveFile).then((value) async {
      if (value.isNotEmpty) {
        matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
      }
      setState(() => isLoading = false);
      await removeDeletedMatchQuestions();
    });
  }

  @override
  void dispose() {
    obstacleController.dispose();
    super.dispose();
  }

  Future<List<FinishMatch>> getAllSavedQuestions() async {
    logger.i('Getting all saved questions');
    final saved = await storageHandler!.readFromFile(storageHandler!.finishSaveFile);
    if (saved.isEmpty) return [];
    final q = (jsonDecode(saved) as List).map((e) => FinishMatch.fromJson(e)).toList();
    return q;
  }

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler!.readFromExcel(path, 4);

    logger.i('Extracting data from excel');

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
    logger.i('Loaded ${selectedMatch!.match}');
  }

  Future<void> saveNewQuestions() async {
    logger.i('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await getAllSavedQuestions();
    saved.removeWhere((e) => e.match == selectedMatch!.match);
    saved.add(selectedMatch!);
    await overwriteSave(saved);
  }

  Future<void> updateQuestions(FinishMatch fMatch) async {
    logger.i('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await getAllSavedQuestions();
    saved.removeWhere((e) => e.match == fMatch.match);
    saved.add(fMatch);
    await overwriteSave(saved);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await getAllSavedQuestions();
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logger.i('Loaded Finish questions of ${selectedMatch!.match}');
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

  Future<void> removeMatch(FinishMatch fMatch) async {
    logger.i('Removing questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await getAllSavedQuestions();
    saved.removeWhere((e) => e.match == fMatch.match);
    await overwriteSave(saved);
  }

  Future<void> overwriteSave(List<FinishMatch> q) async {
    logger.i('Overwriting save');
    await storageHandler!.writeToFile(storageHandler!.finishSaveFile, jsonEncode(q));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Finish Question Manager'),
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
          // sort point
          DropdownMenu(
            label: const Text('Filter position'),
            initialSelection: -1,
            enabled: selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: -1, label: 'All'),
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
    List<MapEntry<int, FinishQuestion>> filtered = [];
    if (selectedMatch != null) {
      for (int i = 0; i < selectedMatch!.questions.length; i++) {
        if (sortPoint > 0 && selectedMatch!.questions[i].point != sortPoint) continue;
        filtered.add(MapEntry(i, selectedMatch!.questions[i]));
      }
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
            customListTile(context, 'Point', 130, 'Question', 800, 'Answer', 'Explanation', 240),
            Flexible(
              child: Material(
                borderRadius: BorderRadius.circular(20),
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final q = filtered[index];

                    return customListTile(
                      context,
                      '${q.value.point}',
                      130,
                      q.value.question,
                      800,
                      q.value.answer,
                      q.value.explanation,
                      290,
                      onTap: () async {
                        final newQ =
                            await Navigator.of(context).push<FinishQuestion>(DialogRoute<FinishQuestion>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => FinishEditorDialog(question: q.value),
                        ));
                        if (newQ != null) {
                          selectedMatch!.questions[q.key] = newQ;
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
