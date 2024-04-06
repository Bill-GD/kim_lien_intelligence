import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class StartQuestionManager extends StatefulWidget {
  const StartQuestionManager({super.key});

  @override
  State<StartQuestionManager> createState() => _StartQuestionManagerState();
}

class _StartQuestionManagerState extends State<StartQuestionManager> {
  bool _isLoading = true;
  List<String> _matchNames = [];
  int _selectedMatchIndex = -1;
  List<StartQuestion> _questions = [];
  int _sortPlayerPos = -1;
  QuestionSubject? _sortType;

  @override
  void initState() {
    super.initState();
    logger.i('Start question manager init');
    storageHandler.readFromFile(storageHandler.matchSaveFile).then((value) {
      if (value.isNotEmpty) {
        _matchNames = (jsonDecode(value) as Iterable).map((e) => e['name'] as String).toList();
      }
      setState(() => _isLoading = false);
    });
  }

  Future<void> getSavedQuestion() async {
    logger.i('Getting saved question');
    final saved = await storageHandler.readFromFile(storageHandler.startSaveFile);
    if (saved.isNotEmpty) {
      _questions = (jsonDecode(saved) as List).map((e) => StartQuestion.fromJson(e)).toList();
      setState(() {});
    }
    logger.i('Loaded ${_questions.length} questions from saved');
  }

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler.readFromExcel(path, 3);
    _questions = [];

    logger.i('Extracting data from excel');
    int idx = 0;
    for (var name in data.keys) {
      _questions.addAll((data[name] as List<Map>).map((e) {
        final v = e.values;
        final q = StartQuestion(
          StartQuestion.mapType(v.elementAt(0)),
          v.elementAt(1),
          v.elementAt(2),
          _matchNames[_selectedMatchIndex],
          idx,
        );
        return q;
      }));
      idx++;
    }
    logger.i('Loaded ${_questions.length} questions from excel');
  }

  Future<void> overwriteSave() async {
    logger.i('Overwriting save');
    final saved = await storageHandler.readFromFile(storageHandler.startSaveFile);
    List<StartQuestion> savedList;

    if (saved.isEmpty) {
      savedList = _questions.map((e) => e).toList();
    } else {
      savedList = (jsonDecode(saved) as List).map((e) => StartQuestion.fromJson(e)).toList();
    }

    savedList.removeWhere((e) => e.match == _matchNames[_selectedMatchIndex]);
    savedList.addAll(_questions);

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // select match
          DropdownMenu(
            label: const Text('Match'),
            dropdownMenuEntries: [
              for (var i = 0; i < _matchNames.length; i++)
                DropdownMenuEntry(
                  value: _matchNames[i],
                  label: _matchNames[i],
                )
            ],
            onSelected: (value) async {
              _selectedMatchIndex = _matchNames.indexOf(value!);
              logger.i('Selected match: ${_matchNames[_selectedMatchIndex]}');
              await getSavedQuestion();
              setState(() {});
            },
          ),
          // sort player pos
          DropdownMenu(
            label: const Text('Sort'),
            initialSelection: -1,
            enabled: _selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: -1, label: 'None'),
              for (var i = 0; i < 4; i++)
                DropdownMenuEntry(
                  value: i,
                  label: '${i + 1}',
                )
            ],
            onSelected: (value) async {
              _sortPlayerPos = value!;
              setState(() {});
            },
          ),
          // sort subject
          DropdownMenu(
            label: const Text('Sort'),
            initialSelection: null,
            enabled: _selectedMatchIndex >= 0,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: null, label: 'None'),
              for (final s in QuestionSubject.values)
                DropdownMenuEntry(
                  value: s,
                  label: StartQuestion.mapTypeDisplay(s),
                )
            ],
            onSelected: (value) async {
              _sortType = value!;
              setState(() {});
            },
          ),
          button(
            'Add Question',
            _selectedMatchIndex < 0
                ? null
                : () async {
                    logger.i(
                      'Selecting Start Question (.xlsx) at ${storageHandler.getRelative(storageHandler.newDataDir)}',
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
                        'Chose ${storageHandler.getRelative(p)} for match ${_matchNames[_selectedMatchIndex]}',
                      );
                      await getNewQuestion(p);
                      await overwriteSave();
                      setState(() {});
                      return;
                    }
                    logger.i('No file selected');
                  },
          ),
        ],
      ),
    );
  }

  Widget questionList() {
    List<StartQuestion> filtered = _questions.where((e) {
      bool res = true;
      if (_sortType != null) res = res && e.subject == _sortType;
      if (_sortPlayerPos >= 0) res = res && e.playerPos == _sortPlayerPos;
      return res;
    }).toList();

    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Theme.of(context).colorScheme.primaryContainer),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          children: [
            customListTile('Thí sinh', 'Subject', 'Question', 'Answer'),
            Flexible(
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
                      // open dialog to modify question
                      setState(() {});
                    },
                  );
                },
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
      child: GestureDetector(
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
