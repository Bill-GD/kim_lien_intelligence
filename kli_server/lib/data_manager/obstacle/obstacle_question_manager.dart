import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';
import 'obstacle_question_editor.dart';

class ObstacleQuestionManager extends StatefulWidget {
  const ObstacleQuestionManager({super.key});

  @override
  State<ObstacleQuestionManager> createState() => _ObstacleQuestionManagerState();
}

class _ObstacleQuestionManagerState extends State<ObstacleQuestionManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  int selectedMatchIndex = -1;
  ObstacleMatch? selectedMatch;
  final obstacleController = TextEditingController();

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

  @override
  void dispose() {
    obstacleController.dispose();
    super.dispose();
  }

  Future<List<ObstacleMatch>> getAllSavedQuestions() async {
    logger.i('Getting all saved questions');
    final saved = await storageHandler!.readFromFile(storageHandler!.obstacleSaveFile);
    if (saved.isEmpty) return [];
    final q = (jsonDecode(saved) as List).map((e) => ObstacleMatch.fromJson(e)).toList();
    return q;
  }

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler!.readFromExcel(path, 5);

    logger.i('Extracting data from excel');
    final sheet = data.values.first;

    List<ObstacleQuestion> qL = [];
    for (int i = 0; i < sheet.length - 1; i++) {
      qL.add(ObstacleQuestion(
        i,
        sheet[i].values.elementAt(2),
        sheet[i].values.elementAt(3),
        int.parse(sheet[i].values.elementAt(1)),
      ));
    }

    selectedMatch = ObstacleMatch(
      match: matchNames[selectedMatchIndex],
      keyword: sheet[5].values.elementAt(3),
      imagePath: '',
      charCount: int.parse(sheet[5].values.elementAt(1)),
      explanation: sheet[5].values.elementAt(4),
      hintQuestions: qL,
    );
    logger.i('Loaded ${selectedMatch!.match} (${selectedMatch!.keyword})');
    await updateQuestions(selectedMatch!);
  }

  Future<void> saveNewQuestions() async {
    logger.i('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await getAllSavedQuestions();
    saved.add(selectedMatch!);
    await overwriteSave(saved);
  }

  Future<void> updateQuestions(ObstacleMatch oMatch) async {
    logger.i('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await getAllSavedQuestions();
    saved.removeWhere((e) => e.match == oMatch.match);
    saved.add(oMatch);
    await overwriteSave(saved);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await getAllSavedQuestions();
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logger.i('Loaded Obstacle (${selectedMatch!.keyword}) of $match');
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

  Future<void> removeMatch(ObstacleMatch oMatch) async {
    logger.i('Removing questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await getAllSavedQuestions();
    saved.removeWhere((e) => e.match == oMatch.match);
    await overwriteSave(saved);
  }

  Future<void> overwriteSave(List<ObstacleMatch> q) async {
    logger.i('Overwriting save');
    await storageHandler!.writeToFile(storageHandler!.obstacleSaveFile, jsonEncode(q));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obstacle Question Manager'),
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
          Tooltip(message: 'Not available yet', child: button(context, 'Export Excel', null)),
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
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('Questions', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  selectedMatchIndex < 0
                      ? Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                          ),
                          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
                          child: const Center(child: Text('No match selected')),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: 5,
                          separatorBuilder: (_, index) => const SizedBox(height: 20),
                          itemBuilder: (_, index) {
                            return ListTile(
                              leading: Text("${index + 1}"),
                              leadingAndTrailingTextStyle: const TextStyle(fontSize: fontSizeMedium),
                              title: Text(
                                '${selectedMatch?.hintQuestions[index].question}',
                                style: const TextStyle(fontSize: fontSizeMedium),
                              ),
                              subtitle: Text('${selectedMatch?.hintQuestions[index].charCount} kí tự'),
                              subtitleTextStyle: const TextStyle(fontSize: fontSizeSmall),
                              trailing: Text('${selectedMatch?.hintQuestions[index].answer}'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  width: 2,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              onTap: selectedMatch == null
                                  ? null
                                  : () async {
                                      final nQ = await Navigator.of(context).push<ObstacleQuestion>(
                                        DialogRoute<ObstacleQuestion>(
                                          context: context,
                                          builder: (_) => ObstacleEditorDialog(
                                            question: selectedMatch!.hintQuestions[index],
                                          ),
                                        ),
                                      );

                                      if (nQ == null) return;
                                      selectedMatch!.hintQuestions[index] = nQ;
                                      await updateQuestions(selectedMatch!);
                                      setState(() {});
                                    },
                            );
                          },
                        ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('Chướng ngại vật', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  selectedMatchIndex < 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 128, vertical: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    style: const TextStyle(fontSize: fontSizeMedium),
                                    controller: obstacleController..text = '${selectedMatch?.keyword}',
                                    maxLines: 5,
                                    minLines: 1,
                                    decoration: InputDecoration(
                                      labelText: 'Đáp án',
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ),
                              button(context, 'Save', () async {
                                selectedMatch!.keyword = obstacleController.text;
                                selectedMatch!.charCount = obstacleController.text.replaceAll(' ', '').length;
                                logger.i('Modified keyword of match: ${matchNames[selectedMatchIndex]}');
                                showToastMessage(context, 'Saved');
                                await updateQuestions(selectedMatch!);
                              }),
                            ],
                          ),
                        ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                    ),
                    constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
                    child: selectedMatch == null || selectedMatch!.imagePath.isEmpty
                        ? Container(
                            alignment: Alignment.center,
                            child: Text(selectedMatchIndex < 0 ? 'No match selected' : 'No Image'),
                          )
                        : Image.file(
                            File('${storageHandler!.parentFolder}\\${selectedMatch!.imagePath}'),
                            fit: BoxFit.contain,
                          ),
                  ),
                  selectedMatchIndex < 0
                      ? const SizedBox.shrink()
                      : ElevatedButton(
                          child: const Text('Select Image'),
                          onPressed: () async {
                            logger.i(
                              'Selecting image at ${storageHandler!.getRelative(storageHandler!.mediaDir)}',
                            );
                            final result = await FilePicker.platform.pickFiles(
                              dialogTitle: 'Select image',
                              initialDirectory: storageHandler!.mediaDir.replaceAll('/', '\\'),
                              type: FileType.image,
                            );

                            if (result != null) {
                              final p = result.files.single.path!;
                              selectedMatch!.imagePath = storageHandler!.getRelative(p);
                              await updateQuestions(selectedMatch!);
                              logger.i('Chose ${selectedMatch!.imagePath}');
                              setState(() {});
                            }
                          },
                        ),
                  // ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
