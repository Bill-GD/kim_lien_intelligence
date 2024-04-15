import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_server/data_manager/extra/extra_question_editor.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class ExtraQuestionManager extends StatefulWidget {
  const ExtraQuestionManager({super.key});

  @override
  State<ExtraQuestionManager> createState() => _ExtraQuestionManagerState();
}

class _ExtraQuestionManagerState extends State<ExtraQuestionManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  int selectedMatchIndex = -1;
  late ExtraMatch selectedMatch;

  @override
  void initState() {
    super.initState();
    logger.i('Extra question manager init');
    selectedMatch = ExtraMatch(match: '', questions: []);
    getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await removeDeletedMatchQuestions();
    });
  }

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler!.readFromExcel(path, 3, 1);

    logger.i('Extracting data from excel');

    final List<ExtraQuestion> allQ = [];
    for (var name in data.keys) {
      for (final r in (data[name] as List<Map>)) {
        final v = r.values;
        final q = ExtraQuestion(question: v.elementAt(1), answer: v.elementAt(2));
        allQ.add(q);
      }
    }
    selectedMatch = ExtraMatch(match: matchNames[selectedMatchIndex], questions: allQ);
    logger.i('Loaded ${selectedMatch.questions.length} questions from excel');
  }

  Future<void> saveNewQuestions() async {
    logger.i('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    saved.removeWhere((e) => e.match == selectedMatch.match);
    saved.add(selectedMatch);
    await DataManager.overwriteSave(saved, storageHandler!.extraSaveFile);
  }

  Future<void> updateQuestions(ExtraMatch eMatch) async {
    logger.i('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    saved.removeWhere((e) => e.match == eMatch.match);
    saved.add(eMatch);
    await DataManager.overwriteSave(saved, storageHandler!.extraSaveFile);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logger.i('Loaded ${selectedMatch.questions.length} extra questions of match ${selectedMatch.match}');
    } on StateError {
      logger.i('Extra match $match not found, temp empty match created');
      selectedMatch = ExtraMatch(match: match, questions: []);
    }
  }

  Future<void> removeDeletedMatchQuestions() async {
    logger.i('Removing questions of deleted matches');
    var saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    saved = saved.where((e) => matchNames.contains(e.match)).toList();
    await DataManager.overwriteSave(saved, storageHandler!.extraSaveFile);
  }

  Future<void> removeMatch(ExtraMatch eMatch) async {
    logger.i('Removing questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    saved.removeWhere((e) => e.match == eMatch.match);
    await DataManager.overwriteSave(saved, storageHandler!.extraSaveFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Extra Question Manager'),
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
          button(
            context,
            'Add Question',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              final newQ = await Navigator.of(context).push<ExtraQuestion>(DialogRoute<ExtraQuestion>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => const ExtraEditorDialog(),
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
          button(
            context,
            'Remove Questions',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              final ret = await confirmDeleteDialog(
                context,
                'Are you sure you want to delete questions for match: ${matchNames[selectedMatchIndex]}?',
                'Removed all extra questions for match: ${matchNames[selectedMatchIndex]}',
              );
              if (ret == true) {
                if (mounted) {
                  showToastMessage(context, 'Removed questions for match: ${matchNames[selectedMatchIndex]}');
                }
                await removeMatch(selectedMatch);
                selectedMatch = ExtraMatch(match: '', questions: []);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget questionList() {
    List<double> widthRatios = [0.4, 0.25, 0.03];

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
              (const Text('Question'), widthRatios[0]),
              (const Text('Answer'), widthRatios[1]),
              (const Text(''), widthRatios[2]),
            ]),
            Flexible(
              child: Material(
                borderRadius: BorderRadius.circular(10),
                child: ListView.builder(
                  itemCount: selectedMatch.questions.length,
                  itemBuilder: (_, index) {
                    final q = selectedMatch.questions[index];

                    return customListTile(
                      context,
                      columns: [
                        (Text(q.question), widthRatios[0]),
                        (Text(q.answer), widthRatios[1]),
                        (
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              final ret = await confirmDeleteDialog(
                                context,
                                'Do you want to delete this question?\n"${q.question}"',
                                'Removed an extra question',
                              );
                              if (ret == true) {
                                selectedMatch.questions.removeAt(index);
                                await updateQuestions(selectedMatch);
                                logger.i('Deleted extra question of ${selectedMatch.match}');
                                setState(() {});
                              }
                            },
                          ),
                          widthRatios[2]
                        )
                      ],
                      onTap: () async {
                        final newQ =
                            await Navigator.of(context).push<ExtraQuestion>(DialogRoute<ExtraQuestion>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => ExtraEditorDialog(question: q),
                        ));
                        if (newQ != null) {
                          selectedMatch.questions[index] = newQ;
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
