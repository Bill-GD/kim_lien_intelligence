import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:kli_server/global.dart';

class MatchSetup extends StatefulWidget {
  const MatchSetup({super.key});

  @override
  State<MatchSetup> createState() => _MatchSetupState();
}

class _MatchSetupState extends State<MatchSetup> {
  List<String> matchNames = [];
  int selectedMatchIndex = -1;
  bool isLoading = true;
  List<(bool, List<String>)> questionCheckResults = [];
  bool disableContinue = true;

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
    logger.i('Match setup');
    getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/ttkl_bg_new.png'),
          fit: BoxFit.fill,
          opacity: 0.8,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Match Setup', style: TextStyle(fontSize: fontSizeLarge)),
          centerTitle: true,
          forceMaterialTransparency: true,
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 512, right: 512, top: 80, bottom: 128),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              matchSelector(matchNames, (value) async {
                selectedMatchIndex = matchNames.indexOf(value!);
                logger.i('Selected match: ${matchNames[selectedMatchIndex]}');
                questionCheckResults = await checkMatchQuestions();
                setState(() {});
              }),
              matchQuestionChecker(),
              button(context, 'Continue', enableCondition: !disableContinue, onPressed: () async {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget matchQuestionChecker() {
    if (selectedMatchIndex < 0) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
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
                  return AlertDialog(
                    title: Text(roundNames[index], textAlign: TextAlign.center),
                    titleTextStyle: const TextStyle(fontSize: fontSizeMedium),
                    content: Text(
                      errorList.isEmpty ? 'Ready to go' : '- ${errorList.join('\n- ')}',
                      textAlign: errorList.isEmpty ? TextAlign.center : null,
                    ),
                    contentTextStyle: const TextStyle(fontSize: fontSizeMSmall),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<(bool, List<String>)>> checkMatchQuestions() async {
    return <(bool, List<String>)>[
      await checkMatch(),
      await checkStartQuestions(),
      await checkObstacleQuestions(),
      await checkAccelQuestions(),
      await checkFinishQuestions(),
      await checkExtraQuestions(),
    ];
  }

  Future<(bool, List<String>)> checkMatch() async {
    final errorList = <String>[];

    final match = (jsonDecode(await storageHandler!.readFromFile(storageHandler!.matchSaveFile)) as List)
        .map((e) => KLIMatch.fromJson(e))
        .firstWhere((e) => e.name == matchNames[selectedMatchIndex]);

    if (!match.playerList.every((e) => e != null)) errorList.add('Not enough player');

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkStartQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<StartMatch>(
      StartMatch.fromJson,
      storageHandler!.startSaveFile,
    );
    if (saved.isEmpty) {
      errorList.add('Not found');
      return (false, errorList);
    }

    try {
      StartMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);

      if (match.questions.keys.length < 4) errorList.add('Missing player questions');

      for (int i = 1; i <= 4; i++) {
        final qList = match.questions.values.elementAt(i - 1);
        if (qList.length < 20) errorList.add('Player $i: less than 20 questions');
        for (final qType in StartQuestionSubject.values) {
          if (qList.where((e) => e.subject == qType).isEmpty) {
            errorList.add('Player $i: ${qType.name} not found');
          }
        }
      }
    } on StateError {
      errorList.add('Not found');
      return (false, errorList);
    }

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkObstacleQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    if (saved.isEmpty) {
      errorList.add('Not found');
      return (false, errorList);
    }

    try {
      ObstacleMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);

      if (match.keyword.isEmpty) errorList.add('Keyword not found');
      if (match.imagePath.isEmpty) errorList.add('Image not found');
      if (match.hintQuestions.length < 5) errorList.add('Not enough question');
    } on StateError {
      errorList.add('Not found');
      return (false, errorList);
    }

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkAccelQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<AccelMatch>(
      AccelMatch.fromJson,
      storageHandler!.accelSaveFile,
    );
    if (saved.isEmpty) {
      errorList.add('Not found');
      return (false, errorList);
    }

    try {
      AccelMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);

      if (!match.questions.every((e) => e != null)) errorList.add('Not enough question');

      for (int i = 1; i <= 4; i++) {
        final q = match.questions[i - 1];
        if (q == null) continue;

        if (q.type == AccelQuestionType.none) {
          errorList.add('Question $i: no image');
        }
        if (q.type == AccelQuestionType.iq && q.imagePaths.isEmpty) {
          errorList.add('Question $i (IQ): no image');
        }
        if (q.type == AccelQuestionType.arrange && q.imagePaths.length < 2) {
          errorList.add('Question $i (Arrange): not enough images (2)');
        }
        if (q.type == AccelQuestionType.sequence && q.imagePaths.length < 3) {
          errorList.add('Question $i: not enough images (3)');
        }
      }
    } on StateError {
      errorList.add('Not found');
      return (false, errorList);
    }

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkFinishQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<FinishMatch>(
      FinishMatch.fromJson,
      storageHandler!.finishSaveFile,
    );
    if (saved.isEmpty) {
      errorList.add('Not found');
      return (false, errorList);
    }

    try {
      FinishMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);
      for (int i = 1; i <= 3; i++) {
        final qCount = match.questions.where((e) => e.point == i * 10).length;
        if (qCount < 12) {
          errorList.add('Not enough ${i * 10} point question ($qCount/12)');
        }
      }
    } on StateError {
      errorList.add('Not found');
      return (false, errorList);
    }

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkExtraQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    if (saved.isEmpty) {
      errorList.add('Not found');
      return (false, errorList);
    }

    try {
      ExtraMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);

      if (match.questions.isEmpty) errorList.add('No question');
    } on StateError {
      errorList.add('Not found');
      return (false, errorList);
    }

    return (errorList.isEmpty, errorList);
  }
}
