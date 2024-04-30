import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';
import '../import_dialog.dart';
import 'extra_question_editor.dart';

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

  Future<void> getNewQuestion(Map<String, dynamic> data) async {
    final List<ExtraQuestion> allQ = [];
    final sheet = data.values.first;

    for (final r in (sheet as List<Map>)) {
      final v = r.values;
      final q = ExtraQuestion(question: v.elementAt(1), answer: v.elementAt(2));
      allQ.add(q);
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
      appBar: managerAppBar(context, 'Quản lý câu hỏi phụ'),
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
            'Thêm câu hỏi',
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
                  maxColumnCount: 3,
                  maxSheetCount: 1,
                  columnWidths: const [100, 500, 250, 200, 200],
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
                message: 'Bạn có muốn xóa tất cả câu hỏi phụ của trận: ${matchNames[selectedMatchIndex]}?',
                acceptLogMessage: 'Removed all extra questions for match: ${matchNames[selectedMatchIndex]}',
                onAccept: () async {
                  if (mounted) {
                    showToastMessage(context, 'Đã xóa (match: ${matchNames[selectedMatchIndex]})');
                  }
                  await removeMatch(selectedMatch);
                  selectedMatch = ExtraMatch(match: '', questions: []);
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
              (const Text('Câu hỏi'), widthRatios[0]),
              (const Text('Đáp án'), widthRatios[1]),
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
                              await confirmDialog(
                                context,
                                message: 'Bạn có muốn xóa câu hỏi này?\n"${q.question}"',
                                acceptLogMessage: 'Removed an extra question',
                                onAccept: () async {
                                  selectedMatch.questions.removeAt(index);
                                  await updateQuestions(selectedMatch);
                                  logger.i('Deleted extra question of ${selectedMatch.match}');
                                  setState(() {});
                                },
                              );
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
