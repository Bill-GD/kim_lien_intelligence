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
  late ObstacleMatch selectedMatch;
  final obstacleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logger.i('Obstacle question manager init');
    selectedMatch = ObstacleMatch(
      match: '',
      charCount: 0,
      explanation: '',
      hintQuestions: List<ObstacleQuestion?>.filled(5, null),
      imagePath: '',
      keyword: '',
    );
    getMatchNames().then((value) async {
      if (value.isNotEmpty) matchNames = value;
      setState(() => isLoading = false);
      await removeDeletedMatchQuestions();
    });
  }

  @override
  void dispose() {
    obstacleController.dispose();
    super.dispose();
  }

  Future<void> getNewQuestion(String path) async {
    Map<String, List> data = await storageHandler!.readFromExcel(path, 5, 1);

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
    logger.i('Loaded ${selectedMatch.match} (${selectedMatch.keyword})');
  }

  Future<void> saveNewQuestions() async {
    logger.i('Saving new questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    saved.removeWhere((e) => e.match == selectedMatch.match);
    saved.add(selectedMatch);
    await DataManager.overwriteSave(saved, storageHandler!.obstacleSaveFile);
  }

  Future<void> updateQuestions(ObstacleMatch oMatch) async {
    logger.i('Updating questions of match: ${matchNames[selectedMatchIndex]}');
    final saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    saved.removeWhere((e) => e.match == oMatch.match);
    saved.add(oMatch);
    await DataManager.overwriteSave(saved, storageHandler!.obstacleSaveFile);
  }

  Future<void> loadMatchQuestions(String match) async {
    final saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    if (saved.isEmpty) return;

    try {
      selectedMatch = saved.firstWhere((e) => e.match == match);
      setState(() {});
      logger.i('Loaded Obstacle (${selectedMatch.keyword}) of $match');
    } on StateError {
      logger.i('Obstacle match $match not found, temp empty match created');
      selectedMatch = ObstacleMatch(
        match: matchNames[selectedMatchIndex],
        keyword: '',
        imagePath: '',
        charCount: 0,
        explanation: '',
        hintQuestions: List<ObstacleQuestion?>.filled(5, null),
      );
    }
  }

  Future<void> removeDeletedMatchQuestions() async {
    logger.i('Removing questions of deleted matches');
    var saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    saved = saved.where((e) => matchNames.contains(e.match)).toList();
    await DataManager.overwriteSave(saved, storageHandler!.obstacleSaveFile);
  }

  Future<void> removeMatch(ObstacleMatch oMatch) async {
    logger.i('Removing questions of match: ${matchNames[selectedMatchIndex]}');
    var saved = await DataManager.getAllSavedQuestions<ObstacleMatch>(
      ObstacleMatch.fromJson,
      storageHandler!.obstacleSaveFile,
    );
    saved.removeWhere((e) => e.match == oMatch.match);
    await DataManager.overwriteSave(saved, storageHandler!.obstacleSaveFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Obstacle Question Manager'),
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
            setState(() {});
          }),
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
          Tooltip(
              message: 'Not available yet', child: button(context, 'Export Excel', enableCondition: false)),
          button(
            context,
            'Remove Questions',
            enableCondition: selectedMatchIndex >= 0,
            onPressed: () async {
              final ret = await confirmDeleteDialog(
                context,
                'Are you sure you want to delete questions for match: ${matchNames[selectedMatchIndex]}?',
                'Removed all obstacle questions for match: ${matchNames[selectedMatchIndex]}',
              );
              if (ret == true) {
                if (mounted) {
                  showToastMessage(context, 'Removed questions for match: ${matchNames[selectedMatchIndex]}');
                }
                await removeMatch(selectedMatch);
                selectedMatch = ObstacleMatch(
                  match: matchNames[selectedMatchIndex],
                  keyword: '',
                  imagePath: '',
                  charCount: 0,
                  explanation: '',
                  hintQuestions: List<ObstacleQuestion?>.filled(5, null),
                );
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget matchContent() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            questionList(),
            obstaclePreview(),
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
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Questions', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          if (selectedMatchIndex < 0)
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
              ),
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
              child: const Material(child: Center(child: Text('No match selected'))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              itemCount: 5,
              separatorBuilder: (_, index) => const SizedBox(height: 20),
              itemBuilder: (_, index) {
                final q = selectedMatch.hintQuestions[index];

                return ListTile(
                  leading: Text("${index + 1}"),
                  tileColor: Theme.of(context).colorScheme.background,
                  leadingAndTrailingTextStyle: const TextStyle(fontSize: fontSizeMedium),
                  title: Text(q?.question ?? '', style: const TextStyle(fontSize: fontSizeMedium)),
                  subtitle: Text('${q?.charCount ?? 0} kí tự'),
                  subtitleTextStyle: const TextStyle(fontSize: fontSizeSmall),
                  trailing: Text(q?.answer ?? ''),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
                  ),
                  onTap: () async {
                    final nQ = await Navigator.of(context).push<ObstacleQuestion>(
                      DialogRoute<ObstacleQuestion>(
                        context: context,
                        builder: (_) => ObstacleEditorDialog(question: q, index: index),
                      ),
                    );

                    if (nQ == null) return;
                    selectedMatch.hintQuestions[index] = nQ;
                    await updateQuestions(selectedMatch);
                    setState(() {});
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget obstaclePreview() {
    bool imageFound = false;
    String fullImagePath = '';
    fullImagePath = '${storageHandler!.parentFolder}\\${selectedMatch.imagePath}';
    imageFound = File(fullImagePath).existsSync();

    return Flexible(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Chướng ngại vật', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          if (selectedMatchIndex < 0)
            const SizedBox.shrink()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 128, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        style: const TextStyle(fontSize: fontSizeMedium),
                        controller: obstacleController..text = selectedMatch.keyword,
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
                  button(context, 'Save', enableCondition: true, onPressed: () async {
                    selectedMatch.keyword = obstacleController.text;
                    selectedMatch.charCount = obstacleController.text.replaceAll(' ', '').length;
                    logger.i('Modified keyword of match: ${matchNames[selectedMatchIndex]}');
                    showToastMessage(context, 'Saved');
                    await updateQuestions(selectedMatch);
                  }),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
            ),
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
            child: selectedMatchIndex >= 0 && fullImagePath.isNotEmpty && imageFound
                ? Image.file(File(fullImagePath), fit: BoxFit.contain)
                : Material(
                    child: Center(
                    child: Text(
                      selectedMatchIndex < 0
                          ? 'No match selected'
                          : selectedMatch.imagePath.isEmpty
                              ? 'No image'
                              : 'Image $fullImagePath not found',
                    ),
                  )),
          ),
          if (selectedMatchIndex < 0)
            const SizedBox.shrink()
          else
            ElevatedButton(
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
                  selectedMatch.imagePath = storageHandler!.getRelative(p);
                  await updateQuestions(selectedMatch);
                  logger.i('Chose ${selectedMatch.imagePath}');
                  setState(() {});
                }
              },
            ),
        ],
      ),
    );
  }
}
