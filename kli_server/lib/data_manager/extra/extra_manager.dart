import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../import_dialog.dart';
import 'extra_question_editor.dart';

class ExtraManager extends StatefulWidget {
  const ExtraManager({super.key});

  @override
  State<ExtraManager> createState() => _ExtraManagerState();
}

class _ExtraManagerState extends State<ExtraManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  int selectedMatchIndex = -1;
  late ExtraMatch selectedMatch;

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Extra Manager', d: 1);
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
    logHandler.info('Loaded ${selectedMatch.questions.length} questions from excel', d: 2);
  }

  Future<void> saveNewQuestions() async {
    logHandler.info('Saving new questions of match: ${matchNames[selectedMatchIndex]}', d: 2);
    final saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    saved.removeWhere((e) => e.match == selectedMatch.match);
    saved.add(selectedMatch);
    await DataManager.overwriteSave(saved, storageHandler!.extraSaveFile);
  }

  Future<void> updateQuestions(ExtraMatch eMatch) async {
    logHandler.info('Updating questions of match: ${matchNames[selectedMatchIndex]}', d: 2);
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
      logHandler.info(
        'Loaded ${selectedMatch.questions.length} extra questions of match ${selectedMatch.match}',
        d: 2,
      );
    } on StateError {
      logHandler.info('Extra match $match not found, temp empty match created', d: 2);
      selectedMatch = ExtraMatch(match: match, questions: []);
    }
  }

  Future<void> removeDeletedMatchQuestions() async {
    logHandler.info('Removing questions of deleted matches', d: 2);
    var saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    saved = saved.where((e) => matchNames.contains(e.match)).toList();
    await DataManager.overwriteSave(saved, storageHandler!.extraSaveFile);
  }

  Future<void> removeMatch(ExtraMatch eMatch) async {
    logHandler.info('Removing questions of match: ${matchNames[selectedMatchIndex]}', d: 2);
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
            logHandler.info('Selected match: ${matchNames[selectedMatchIndex]}', d: 2);
            await loadMatchQuestions(matchNames[selectedMatchIndex]);
            setState(() {});
          }),
          KLIButton(
            'Thêm câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
            enabledLabel: 'Thêm 1 câu hỏi cho phần thi',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              final newQ = await Navigator.of(context).push<ExtraQuestion>(DialogRoute<ExtraQuestion>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => const ExtraQuestionEditor(),
              ));
              if (newQ != null) {
                selectedMatch.questions.add(newQ);
                await updateQuestions(selectedMatch);
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
          KLIButton(
            'Xóa câu hỏi',
            enableCondition: selectedMatchIndex >= 0,
            enabledLabel: 'Xóa toàn bộ câu hỏi của phần thi hiện tại',
            disabledLabel: 'Chưa chọn trận đấu',
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
                                  logHandler.info('Deleted extra question of ${selectedMatch.match}', d: 2);
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
                          builder: (_) => ExtraQuestionEditor(question: q),
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
