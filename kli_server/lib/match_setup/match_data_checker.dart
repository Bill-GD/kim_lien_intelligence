import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/data_manager.dart';
import '../data_manager/match_state.dart';
import '../global.dart';
import 'server_setup.dart';

class MatchDataChecker extends StatefulWidget {
  const MatchDataChecker({super.key});

  @override
  State<MatchDataChecker> createState() => _MatchDataCheckerState();
}

class _MatchDataCheckerState extends State<MatchDataChecker> {
  List<String> matchNames = [];
  int selectedMatchIndex = -1;
  bool isLoading = true, disableServerSetup = true;
  List<(bool, List<String>)> questionCheckResults = [];

  final roundNames = <String>[
    'Thí sinh',
    'Khởi động',
    'Chướng ngại vật',
    'Tăng tốc',
    'Về đích',
    'Câu hỏi phụ',
  ];

  @override
  void initState() {
    super.initState();
    logHandler.info('Opening Match Data Checker');

    final value = DataManager.getMatchNames();
    if (value.isEmpty) showToastMessage(context, 'No match found');
    if (value.isNotEmpty) matchNames = value;
    setState(() => isLoading = false);
  }

  void exitHandler() {
    logHandler.info('Closed match data checker');
    logHandler.empty();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{const SingleActivator(LogicalKeyboardKey.escape): exitHandler},
      child: Focus(
        autofocus: true,
        child: Container(
          decoration: BoxDecoration(image: bgDecorationImage),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text('Kiểm tra dữ liệu trận đấu', style: TextStyle(fontSize: fontSizeLarge)),
              centerTitle: true,
              forceMaterialTransparency: true,
              leading: BackButton(onPressed: exitHandler),
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.only(left: 512, right: 512, top: 80, bottom: 128),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            matchSelector(matchNames, (value) async {
                              selectedMatchIndex = matchNames.indexOf(value!);
                              logHandler.info('Selected match: ${matchNames[selectedMatchIndex]}');
                              questionCheckResults = checkMatchQuestions();
                              disableServerSetup = !questionCheckResults.every((e) => e.$1 == true);
                              setState(() {});
                            }),
                            KLIButton(
                              'Mở phần thiết lập Server',
                              enableCondition: !disableServerSetup,
                              disabledLabel: 'Trận đấu chưa đủ thông tin',
                              onPressed: () async {
                                MatchState.instantiate(matchNames[selectedMatchIndex]);
                                if (context.mounted) {
                                  await Navigator.of(context).pushReplacement(MaterialPageRoute(
                                    builder: (context) => ServerSetup(matchNames[selectedMatchIndex]),
                                  ));
                                  MatchState.reset();
                                }
                              },
                            ),
                          ],
                        ),
                        matchQuestionChecker(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget matchQuestionChecker() {
    if (selectedMatchIndex < 0) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.onBackground),
          color: Theme.of(context).colorScheme.background,
        ),
        height: 600,
        alignment: Alignment.center,
        child: const Text('Chưa chọn trận đấu'),
      );
    }
    return Expanded(
      child: ListView.separated(
        itemCount: questionCheckResults.length,
        separatorBuilder: (_, index) {
          return SizedBox(height: index < 5 ? 20 : 0);
        },
        itemBuilder: (context, index) {
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            tileColor: Theme.of(context).colorScheme.background,
            // tileColor: Colors.amber,
            leading: Text('${index + 1}'),
            leadingAndTrailingTextStyle: const TextStyle(fontSize: fontSizeMedium),
            title: Text(roundNames[index]),
            titleTextStyle: const TextStyle(fontSize: fontSizeLarge),
            trailing: Text(questionCheckResults[index].$1 ? '🟢' : '🔴'),
            onTap: () async {
              final errorList = questionCheckResults[index].$2;
              await showDialog(
                context: context,
                builder: (context) {
                  final joinedErrorList = errorList.map((e) => e.contains('+') ? e : '- $e').join('\n');
                  return AlertDialog(
                    title: Text(roundNames[index], textAlign: TextAlign.center),
                    titleTextStyle: const TextStyle(fontSize: fontSizeMedium),
                    content: Text(
                      errorList.isEmpty ? 'Đã hoàn thiện' : joinedErrorList,
                      textAlign: errorList.isEmpty ? TextAlign.center : null,
                    ),
                    contentTextStyle: const TextStyle(fontSize: fontSizeMSmall),
                    contentPadding: const EdgeInsets.only(top: 20, bottom: 30, left: 20, right: 20),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<(bool, List<String>)> checkMatchQuestions() {
    return <(bool, List<String>)>[
      checkMatch(),
      checkStartQuestions(),
      checkObstacleQuestions(),
      checkAccelQuestions(),
      checkFinishQuestions(),
      checkExtraQuestions(),
    ];
  }

  (bool, List<String>) checkMatch() {
    final errorList = <String>[];

    // final match = (jsonDecode(storageHandler.readFromFile(storageHandler.matchSaveFile)) as List)
    //     .map((e) => KLIMatch.fromJson(e))
    //     .firstWhere((e) => e.name == matchNames[selectedMatchIndex]);
    final match = DataManager.getMatch(matchNames[selectedMatchIndex]);

    if (!match.playerList.every((e) => e != null)) {
      errorList.add('Không đủ thông tin 4 thí sinh');
    } else if (!match.playerList.every(
      (e) => File(StorageHandler.getFullPath(e!.imagePath)).existsSync(),
    )) {
      errorList.add('Không tìm thấy ảnh thí sinh');
    }

    return (errorList.isEmpty, errorList);
  }

  (bool, List<String>) checkStartQuestions() {
    final errorList = <String>[];

    final savedMatch = DataManager.getSectionQuestionsOfMatch<StartSection>(matchNames[selectedMatchIndex]);

    try {
      if (savedMatch.isEmpty) return (false, ['Chưa có câu hỏi']);

      for (int i = 0; i < 4; i++) {
        try {
          final qList = savedMatch.questions.where((v) => v.pos == i);
          final misingSubjects = <String>[];
          for (final qType in StartQuestionSubject.values) {
            if (qList.where((e) => e.subject == qType).isEmpty) {
              misingSubjects.add(StartQuestion.mapTypeDisplay(qType));
            }
          }

          if (misingSubjects.isNotEmpty) {
            errorList.add('Thí sinh $i:');
            errorList.add('  + Chưa có ${misingSubjects.join(', ')}');
          }
          if (qList.length < 20) {
            if (misingSubjects.isEmpty) errorList.add('Thí sinh $i:');
            errorList.add('  + Ít hơn 20 câu hỏi: ${qList.length}');
          }
        } on RangeError {
          errorList.add('Thí sinh $i: chưa có câu hỏi');
        }
      }
    } on StateError {
      return (false, ['Chưa có dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }

  (bool, List<String>) checkObstacleQuestions() {
    final errorList = <String>[];

    final savedMatch = DataManager.getSectionQuestionsOfMatch<ObstacleSection>(matchNames[selectedMatchIndex]);
    if (savedMatch.isEmpty) return (false, ['Chưa có dữ liệu']);

    try {
      if (savedMatch.keyword.isEmpty) errorList.add('Không có đáp án CNV');
      if (savedMatch.imagePath.isEmpty) errorList.add('Không có ảnh CNV');
      if (!File(StorageHandler.getFullPath(savedMatch.imagePath)).existsSync()) {
        errorList.add('Không tìm thấy ảnh CNV');
      }
      if (savedMatch.hintQuestions.length < 5) errorList.add('Không đủ số câu hỏi');
    } on StateError {
      return (false, ['Chưa có dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }

  (bool, List<String>) checkAccelQuestions() {
    final errorList = <String>[];

    final savedMatch = DataManager.getSectionQuestionsOfMatch<AccelSection>(matchNames[selectedMatchIndex]);
    if (savedMatch.isEmpty) return (false, ['Chưa có dữ liệu']);

    try {
      if (!savedMatch.questions.every((e) => !e.isNull)) errorList.add('Không đủ 4 câu hỏi');

      for (int i = 1; i <= 4; i++) {
        final q = savedMatch.questions[i - 1];
        if (q.isNull) continue;

        if (q.imagePaths.isEmpty) errorList.add('Câu $i: không có ảnh');

        final missing = q.imagePaths.where((e) => !File(StorageHandler.getFullPath(e)).existsSync());
        if (missing.isNotEmpty) {
          errorList.add('Câu $i (${AccelQuestion.mapTypeDisplay(q.type)}): Không tìm thấy ${missing.join(', ')}');
        }
      }
    } on StateError {
      return (false, ['Chưa có dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }

  (bool, List<String>) checkFinishQuestions() {
    final errorList = <String>[];

    final savedMatch = DataManager.getSectionQuestionsOfMatch<FinishSection>(matchNames[selectedMatchIndex]);
    if (savedMatch.isEmpty) return (false, ['Chưa có dữ liệu']);

    try {
      for (int i = 1; i <= 3; i++) {
        final qCount = savedMatch.questions.where((e) => e.point == i * 10).length;
        if (qCount < 12) {
          errorList.add('Mức điểm ${i * 10}: $qCount/12');
        }
      }
      for (final q in savedMatch.questions) {
        if (q.mediaPath.isNotEmpty && !File(StorageHandler.getFullPath(q.mediaPath)).existsSync()) {
          errorList.add('Không tìm thấy video ${q.mediaPath}');
        }
      }
    } on StateError {
      return (false, ['Chưa có dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }

  (bool, List<String>) checkExtraQuestions() {
    final errorList = <String>[];

    final savedMatch = DataManager.getSectionQuestionsOfMatch<ExtraSection>(matchNames[selectedMatchIndex]);

    try {
      if (savedMatch.isEmpty) errorList.add('Chưa có câu hỏi');
      if (savedMatch.questions.length < 3) errorList.add('Không đủ 3 câu hỏi');
    } on StateError {
      return (false, ['Chưa có dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }
}
