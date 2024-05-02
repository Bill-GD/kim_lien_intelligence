import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:kli_server/server_setup/server_setup.dart';

import '../global.dart';

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
    logger.i('Match Data Checker');
    getMatchNames().then((value) async {
      if (value.isEmpty) showToastMessage(context, 'No match found');
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
          title: const Text('Kiểm tra dữ liệu trận đấu', style: TextStyle(fontSize: fontSizeLarge)),
          centerTitle: true,
          forceMaterialTransparency: true,
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 512, right: 512, top: 80, bottom: 128),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  matchSelector(matchNames, (value) async {
                    selectedMatchIndex = matchNames.indexOf(value!);
                    logger.i('Selected match: ${matchNames[selectedMatchIndex]}');
                    questionCheckResults = await checkMatchQuestions();
                    disableServerSetup = !questionCheckResults.every((e) => e.$1 == true);
                    setState(() {});
                  }),
                  button(
                    context,
                    'Mở phần thiết lập Server',
                    enableCondition: !disableServerSetup,
                    disabledLabel: 'Trận đấu chưa đủ thông tin',
                    onPressed: () async {
                      logger.i('Opening Server Setup page...');
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ServerSetup()),
                      );
                      await KLIServer.stop();
                    },
                  ),
                ],
              ),
              matchQuestionChecker(),
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
                      errorList.isEmpty ? 'Đã hoàn thiện' : '- ${errorList.join('\n- ')}',
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

    if (!match.playerList.every((e) => e != null)) errorList.add('Không đủ thông tin 4 thí sinh');

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkStartQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<StartMatch>(
      StartMatch.fromJson,
      storageHandler!.startSaveFile,
    );
    if (saved.isEmpty) return (false, ['Thiếu dữ liệu']);

    try {
      StartMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);

      if (match.questions.isEmpty) return (false, ['Chưa có câu hỏi']);
      if (match.questions.keys.length < 4) errorList.add('Thiếu câu hỏi cho ít nhất 1 thí sinh');

      for (int i = 1; i <= 4; i++) {
        try {
          final qList = match.questions.values.elementAt(i - 1);
          if (qList.length < 20) errorList.add('Thí sinh $i: ít hơn 20 câu hỏi');
          for (final qType in StartQuestionSubject.values) {
            if (qList.where((e) => e.subject == qType).isEmpty) {
              errorList.add('Thí sinh $i: chưa có lĩnh vực ${StartQuestion.mapTypeDisplay(qType)}');
            }
          }
        } on RangeError {
          errorList.add('Thí sinh $i: chưa có câu hỏi');
        }
      }
    } on StateError {
      return (false, ['Thiếu dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkObstacleQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    if (saved.isEmpty) return (false, ['Thiếu dữ liệu']);

    try {
      ObstacleMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);

      if (match.keyword.isEmpty) errorList.add('Không có đáp án CNV');
      if (match.imagePath.isEmpty) errorList.add('Không có ảnh CNV');
      if (match.hintQuestions.length < 5) errorList.add('Không đủ số câu hỏi');
    } on StateError {
      return (false, ['Thiếu dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkAccelQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<AccelMatch>(
      AccelMatch.fromJson,
      storageHandler!.accelSaveFile,
    );
    if (saved.isEmpty) return (false, ['Thiếu dữ liệu']);

    try {
      AccelMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);

      if (!match.questions.every((e) => e != null)) errorList.add('Không đủ 4 câu hỏi');

      for (int i = 1; i <= 4; i++) {
        final q = match.questions[i - 1];
        if (q == null) continue;

        if (q.type == AccelQuestionType.none) {
          errorList.add('Câu $i: không có ảnh');
        }
        if (q.type == AccelQuestionType.iq && q.imagePaths.isEmpty) {
          errorList.add('Câu $i (IQ): không có ảnh');
        }
        if (q.type == AccelQuestionType.arrange && q.imagePaths.length < 2) {
          errorList.add('Câu $i (sắp xếp): không đủ 2 ảnh');
        }
        if (q.type == AccelQuestionType.sequence && q.imagePaths.length < 3) {
          errorList.add('Câu $i (chuỗi hình ảnh): không đủ ít nhất 3 ảnh');
        }
      }
    } on StateError {
      return (false, ['Thiếu dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkFinishQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<FinishMatch>(
      FinishMatch.fromJson,
      storageHandler!.finishSaveFile,
    );
    if (saved.isEmpty) return (false, ['Thiếu dữ liệu']);

    try {
      FinishMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);
      for (int i = 1; i <= 3; i++) {
        final qCount = match.questions.where((e) => e.point == i * 10).length;
        if (qCount < 12) {
          errorList.add('Mức điểm ${i * 10} chưa đủ câu hỏi ($qCount/12)');
        }
      }
    } on StateError {
      return (false, ['Thiếu dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }

  Future<(bool, List<String>)> checkExtraQuestions() async {
    final errorList = <String>[];

    final saved = await DataManager.getAllSavedQuestions<ExtraMatch>(
      ExtraMatch.fromJson,
      storageHandler!.extraSaveFile,
    );
    if (saved.isEmpty) return (false, ['Thiếu dữ liệu']);

    try {
      ExtraMatch match = saved.firstWhere((e) => e.match == matchNames[selectedMatchIndex]);

      if (match.questions.isEmpty) errorList.add('Chưa có câu hỏi');
    } on StateError {
      return (false, ['Thiếu dữ liệu']);
    }

    return (errorList.isEmpty, errorList);
  }
}
