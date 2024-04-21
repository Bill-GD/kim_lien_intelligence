import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';
import 'accel_question_editor.dart';

class AccelQuestionManager extends StatefulWidget {
  const AccelQuestionManager({super.key});

  @override
  State<AccelQuestionManager> createState() => _AccelQuestionManagerState();
}

class _AccelQuestionManagerState extends State<AccelQuestionManager> {
  bool isLoading = true;
  List<String> matchNames = [];
  int selectedMatchIndex = -1, selectedQuestionIndex = -1, selectedImageIndex = -1;
  late AccelMatch selectedMatch;
  late AccelQuestion selectedQuestion;

  @override
  void initState() {
    super.initState();
    logger.i('Accel question manager init');
    selectedMatch = AccelMatch(match: '', questions: List.filled(4, null));
    selectedQuestion = AccelQuestion(question: '', answer: '', explanation: '', imagePaths: []);
    getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await removeDeletedMatchQuestions();
    });
  }

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler!.readFromExcel(path, 4, 1);

    final List<AccelQuestion> allQ = [];
    for (var name in data.keys) {
      for (final r in (data[name] as List<Map>)) {
        final v = r.values;
        final q = AccelQuestion(
          question: v.elementAt(1),
          answer: v.elementAt(2),
          explanation: v.elementAt(3),
          imagePaths: [],
        );
        allQ.add(q);
      }
    }
    selectedMatch = AccelMatch(match: matchNames[selectedMatchIndex], questions: allQ);
    logger.i('Loaded ${selectedMatch.questions.length} questions from excel');
  }

  Future<void> saveNewQuestions() async {
    logger.i('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<AccelMatch>(
      AccelMatch.fromJson,
      storageHandler!.accelSaveFile,
    );
    saved.removeWhere((e) => e.match == selectedMatch.match);
    saved.add(selectedMatch);
    await DataManager.overwriteSave(saved, storageHandler!.accelSaveFile);
  }

  Future<void> updateQuestions(AccelMatch aMatch) async {
    logger.i('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<AccelMatch>(
      AccelMatch.fromJson,
      storageHandler!.accelSaveFile,
    );
    saved.removeWhere((e) => e.match == aMatch.match);
    saved.add(aMatch);
    await DataManager.overwriteSave(saved, storageHandler!.accelSaveFile);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await DataManager.getAllSavedQuestions<AccelMatch>(
      AccelMatch.fromJson,
      storageHandler!.accelSaveFile,
    );
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logger.i('Loaded ${selectedMatch.questions.length} accel questions of match ${selectedMatch.match}');
    } on StateError {
      logger.i('Accel match $match not found, temp empty match created');
      selectedMatch = AccelMatch(match: match, questions: List.filled(4, null));
    }
  }

  Future<void> removeDeletedMatchQuestions() async {
    logger.i('Removing questions of deleted matches');
    var saved = await DataManager.getAllSavedQuestions<AccelMatch>(
      AccelMatch.fromJson,
      storageHandler!.accelSaveFile,
    );
    saved = saved.where((e) => matchNames.contains(e.match)).toList();
    await DataManager.overwriteSave(saved, storageHandler!.accelSaveFile);
  }

  Future<void> removeMatch(AccelMatch aMatch) async {
    logger.i('Removing questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await DataManager.getAllSavedQuestions<AccelMatch>(
      AccelMatch.fromJson,
      storageHandler!.accelSaveFile,
    );
    saved.removeWhere((e) => e.match == aMatch.match);
    await DataManager.overwriteSave(saved, storageHandler!.accelSaveFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Acceleration Question Manager'),
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                managementButtons(),
                matchContent(),
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
            selectedQuestionIndex = -1;
            selectedImageIndex = -1;
            setState(() {});
          }),
          button(
            context,
            'Edit Question${selectedQuestionIndex >= 0 ? ' ${selectedQuestionIndex + 1}' : ''}',
            enableCondition: selectedQuestionIndex >= 0,
            onPressed: () async {
              final newQ = await Navigator.of(context).push<AccelQuestion>(DialogRoute<AccelQuestion>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => AccelEditorDialog(question: selectedQuestion),
              ));
              if (newQ != null) {
                selectedMatch.questions[selectedQuestionIndex] = newQ;
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

              if (result == null) {
                logger.i('No file selected');
                return;
              }

              final p = result.files.single.path!;
              logPanelController!.addText('Imported from ${storageHandler!.getRelative(p)}');
              logger.i('Import: ${storageHandler!.getRelative(p)}, match: ${matchNames[selectedMatchIndex]}');
              await getNewQuestion(p);
              await saveNewQuestions();
              selectedQuestionIndex = -1;
              selectedImageIndex = -1;
              setState(() {});
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
                'Removed all accel questions for match: ${matchNames[selectedMatchIndex]}',
              );
              if (ret != true) return;

              if (mounted) {
                showToastMessage(context, 'Removed questions (match: ${matchNames[selectedMatchIndex]})');
              }
              // logPanelController!.addText('Removed questions (match: ${matchNames[selectedMatchIndex]})');
              await removeMatch(selectedMatch);
              selectedMatch = AccelMatch(
                match: matchNames[selectedMatchIndex],
                questions: List.filled(4, null),
              );
              selectedQuestionIndex = -1;
              selectedImageIndex = -1;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget matchContent() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 75),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            questionList(),
            imageManager(),
          ],
        ),
      ),
    );
  }

  Widget questionList() {
    return Flexible(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 32, bottom: 64),
            child: Text('Questions', style: TextStyle(fontSize: fontSizeLarge)),
          ),
          if (selectedMatchIndex < 0)
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
              ),
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 700),
              child: const Material(child: Center(child: Text('No match selected'))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              itemCount: 4,
              separatorBuilder: (_, index) => const SizedBox(height: 20),
              itemBuilder: (_, index) {
                final q = selectedMatch.questions[index];

                return ListTile(
                  leading: Text("${index + 1}"),
                  tileColor: Theme.of(context).colorScheme.background,
                  leadingAndTrailingTextStyle: const TextStyle(fontSize: fontSizeMedium),
                  title: Text(
                    q?.question ?? '',
                    style: const TextStyle(fontSize: fontSizeMedium),
                  ),
                  // subtitle: Text(q?.type != null ? AccelQuestion.mapTypeDisplay(q!.type) : ''),
                  // subtitleTextStyle: const TextStyle(fontSize: fontSizeSmall),
                  trailing: Text(q?.answer ?? ''),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      width: 2,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  onTap: () async {
                    selectedQuestionIndex = index;
                    if (q == null) {
                      logger.i('Selected question is null, creating new question');
                      selectedQuestion =
                          AccelQuestion(question: '', answer: '', explanation: '', imagePaths: []);
                      selectedMatch.questions[index] = selectedQuestion;
                      await updateQuestions(selectedMatch);
                    } else {
                      selectedQuestion = q;
                    }
                    selectedImageIndex = selectedQuestion.imagePaths.isNotEmpty ? 0 : -1;
                    setState(() {});
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget imageManager() {
    bool imageFound = false;
    String fullImagePath = '';
    if (selectedQuestion.imagePaths.isNotEmpty && selectedImageIndex >= 0) {
      fullImagePath = '${storageHandler!.parentFolder}\\${selectedQuestion.imagePaths[selectedImageIndex]}';
      imageFound = File(fullImagePath).existsSync();
    }

    return Flexible(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 32, bottom: 16),
            child: Text('Images', style: TextStyle(fontSize: fontSizeLarge)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              button(
                context,
                'Add Image',
                enableCondition: selectedQuestionIndex >= 0,
                fontSize: fontSizeSmall,
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
                    selectedQuestion.imagePaths.add(storageHandler!.getRelative(p));
                    if (selectedImageIndex < 0) selectedImageIndex = 0;
                    await updateQuestions(selectedMatch);
                    logger.i('Chose ${storageHandler!.getRelative(p)}');
                    setState(() {});
                  }
                },
              ),
              button(
                context,
                'Remove Image: $selectedImageIndex',
                enableCondition: selectedQuestionIndex >= 0 && selectedImageIndex >= 0,
                fontSize: fontSizeSmall,
                onPressed: () async {
                  logger.i('Removing image $selectedImageIndex');
                  selectedQuestion.imagePaths.removeAt(selectedImageIndex);
                  if (selectedQuestion.imagePaths.isNotEmpty) {
                    if (selectedImageIndex > 0) selectedImageIndex--;
                  } else {
                    selectedImageIndex = -1;
                  }
                  await updateQuestions(selectedMatch);
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
            ),
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
            child: selectedMatchIndex < 0 || selectedQuestionIndex < 0 || !imageFound
                ? Material(
                    child: Center(
                      child: Text(selectedMatchIndex < 0
                          ? 'No match selected'
                          : selectedQuestionIndex < 0
                              ? 'No question selected'
                              : selectedQuestion.imagePaths.isEmpty
                                  ? 'No image selected'
                                  : 'Image $fullImagePath not found'),
                    ),
                  )
                : Image.file(File(fullImagePath)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: selectedQuestionIndex >= 0 && selectedImageIndex > 0
                    ? () {
                        setState(() => selectedImageIndex--);
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                onPressed:
                    selectedQuestionIndex >= 0 && selectedImageIndex < selectedQuestion.imagePaths.length - 1
                        ? () {
                            setState(() => selectedImageIndex++);
                          }
                        : null,
              )
            ],
          )
        ],
      ),
    );
  }
}
