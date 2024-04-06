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
  int selectedMatchIndex = -1;
  List<StartQuestion> questions = [];
  int sortPlayerPos = -1;
  QuestionSubject? sortType;

  @override
  void initState() {
    super.initState();
    logger.i('Start question manager init');
    storageHandler.readFromFile(storageHandler.matchSaveFile).then((value) {
      if (value.isNotEmpty) {
        matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
      }
      setState(() => isLoading = false);
    });
  }

  Future<void> getSavedQuestion() async {
    logger.i('Getting saved question');
    final saved = await storageHandler.readFromFile(storageHandler.startSaveFile);
    if (saved.isNotEmpty) {
      questions = (jsonDecode(saved) as List)
          .map((e) => StartQuestion.fromJson(e))
          .where((e) => e.match == matchNames[selectedMatchIndex])
          .toList();
      setState(() {});
    }
    logger.i('Loaded ${questions.length} questions from saved');
  }

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler.readFromExcel(path, 3);
    questions = [];

    logger.i('Extracting data from excel');
    int idx = 0;
    for (var name in data.keys) {
      questions.addAll((data[name] as List<Map>).map((e) {
        final v = e.values;
        final q = StartQuestion(
          StartQuestion.mapType(v.elementAt(0)),
          v.elementAt(1),
          v.elementAt(2),
          matchNames[selectedMatchIndex],
          idx,
        );
        return q;
      }));
      idx++;
    }
    logger.i('Loaded ${questions.length} questions from excel');
  }

  Future<void> overwriteSave() async {
    logger.i('Overwriting save');
    final saved = await storageHandler.readFromFile(storageHandler.startSaveFile);
    List<StartQuestion> savedList;

    if (saved.isEmpty) {
      savedList = questions.map((e) => e).toList();
    } else {
      savedList = (jsonDecode(saved) as List).map((e) => StartQuestion.fromJson(e)).toList();
    }

    savedList.removeWhere((e) => e.match == matchNames[selectedMatchIndex]);
    savedList.addAll(questions);

    await storageHandler.writeToFile(storageHandler.startSaveFile, jsonEncode(savedList));
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
              await getSavedQuestion();
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
              setState(() {});
            },
          ),
          // sort subject
          DropdownMenu(
            label: const Text('Filter subject'),
            initialSelection: null,
            enabled: selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: null, label: 'None'),
              for (final s in QuestionSubject.values)
                DropdownMenuEntry(
                  value: s,
                  label: StartQuestion.mapTypeDisplay(s),
                )
            ],
            onSelected: (value) async {
              sortType = value;
              setState(() {});
            },
          ),
          button(
            'Import Questions',
            selectedMatchIndex < 0
                ? null
                : () async {
                    logger.i(
                      'Selecting Start Questions (.xlsx) at ${storageHandler.getRelative(storageHandler.newDataDir)}',
                    );

                    final result = await FilePicker.platform.pickFiles(
                      dialogTitle: 'Select File',
                      initialDirectory: storageHandler.newDataDir.replaceAll('/', '\\'),
                      type: FileType.custom,
                      allowedExtensions: ['xlsx'],
                    );

                    if (result != null) {
                      final p = result.files.single.path!;
                      logger.i(
                        'Chose ${storageHandler.getRelative(p)} for match ${matchNames[selectedMatchIndex]}',
                      );
                      await getNewQuestion(p);
                      await overwriteSave();
                      setState(() {});
                      return;
                    }
                    logger.i('No file selected');
                  },
          ),
          button(
            'Export Excel',
            selectedMatchIndex < 0
                ? null
                : () async {
                    String fileName =
                        'KĐ_${matchNames[selectedMatchIndex]}_${DateTime.now().toString().split('.').first.replaceAll(RegExp('[:-]'), '_')}.xlsx';
                    logger.i('Exporting ${matchNames[selectedMatchIndex]} start questions to $fileName');

                    final data =
                        jsonDecode(await storageHandler.readFromFile(storageHandler.startSaveFile)) as List;

                    final newData = <String, List>{};

                    for (final Map<String, dynamic> q in data) {
                      final kName = 'Thí sinh ${q['playerPos'] + 1}';
                      final qMap = {
                        'Loại câu hỏi':
                            StartQuestion.mapTypeDisplay(QuestionSubject.values.byName(q['subject'])),
                        'Nội dung': q['question'],
                        'Đáp án': q['answer'],
                      };

                      if (newData[kName] == null) {
                        newData[kName] = [qMap];
                      } else {
                        newData[kName]!.add(qMap);
                      }
                    }

                    await storageHandler.writeToExcel(fileName, newData);
                    if (mounted) {
                      showToastMessage(
                        context,
                        'Saved to ${storageHandler.getRelative(storageHandler.excelOutput)}/$fileName',
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget questionList() {
    List<StartQuestion> filtered = questions.where((e) {
      bool res = true;
      if (sortType != null) res = res && e.subject == sortType;
      if (sortPlayerPos >= 0) res = res && e.playerPos == sortPlayerPos;
      return res;
    }).toList();

    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Theme.of(context).colorScheme.primaryContainer),
          borderRadius: BorderRadius.circular(20),
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
                      '${q.playerPos + 1}',
                      StartQuestion.mapTypeDisplay(q.subject),
                      q.question,
                      q.answer,
                      onTap: () async {
                        final newQ =
                            await Navigator.of(context).push<StartQuestion>(DialogRoute<StartQuestion>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => StartEditorDialog(question: q),
                        ));
                        if (newQ != null) {
                          questions[index] = newQ;
                          await overwriteSave();
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
              bottom: BorderSide(width: 2, color: Theme.of(context).colorScheme.primaryContainer),
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
