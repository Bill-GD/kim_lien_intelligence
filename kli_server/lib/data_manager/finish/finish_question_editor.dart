import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class FinishEditorDialog extends StatefulWidget {
  final FinishQuestion question;
  const FinishEditorDialog({super.key, required this.question});

  @override
  State<FinishEditorDialog> createState() => _FinishEditorDialogState();
}

class _FinishEditorDialogState extends State<FinishEditorDialog> {
  final questionController = TextEditingController(),
      answerController = TextEditingController(),
      explanationController = TextEditingController();
  int point = -1;
  String? qErrorText, aErrorText;

  @override
  void initState() {
    super.initState();
    logger.i('Opened finish question editor');
    questionController.text = widget.question.question;
    answerController.text = widget.question.answer;
    explanationController.text = widget.question.explanation;
    point = widget.question.point;
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
    explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.symmetric(vertical: 32),
        title: Center(
          child: DropdownMenu(
            label: const Text('Point'),
            textStyle: const TextStyle(fontSize: fontSizeMSmall),
            initialSelection: point,
            dropdownMenuEntries: [
              for (final s in [10, 20, 30])
                DropdownMenuEntry(
                  value: s,
                  label: '$s',
                )
            ],
            onSelected: (value) async {
              point = value!;
              setState(() {});
            },
          ),
        ),
        contentPadding: const EdgeInsets.only(bottom: 40, left: 60, right: 60),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextField(
                    style: const TextStyle(fontSize: fontSizeMedium),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        qErrorText = 'Can\'t be empty';
                        setState(() {});
                        return;
                      }
                      setState(() => qErrorText = null);
                    },
                    controller: questionController,
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      errorText: qErrorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(fontSize: fontSizeMedium),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        aErrorText = 'Can\'t be empty';
                        setState(() {});
                        return;
                      }
                      setState(() => aErrorText = null);
                    },
                    controller: answerController,
                    decoration: InputDecoration(
                      labelText: 'Answer',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      errorText: aErrorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(fontSize: fontSizeMedium),
                    controller: explanationController,
                    decoration: InputDecoration(
                      labelText: 'Explanation',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                  ),
                  constraints: const BoxConstraints(maxHeight: 300, maxWidth: 400),
                  child:
                      // widget.question.mediaPath.isEmpty ?
                      const Center(child: Text('No Video'))
                  // : Image.file(
                  //     File('${storageHandler!.parentFolder}\\${selectedMatch!.imagePath}'),
                  //     fit: BoxFit.contain,
                  //   ),
                  ,
                ),
                ElevatedButton(
                  child: const Text('Select Video'),
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
                      widget.question.mediaPath = storageHandler!.getRelative(p);
                      logger.i('Chose ${widget.question.mediaPath}');
                      setState(() {});
                    }
                  },
                ),
              ],
            )
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (questionController.text.isEmpty) {
                showToastMessage(context, 'Question can\'t be empty');
                return;
              }
              if (answerController.text.isEmpty) {
                showToastMessage(context, 'Answer can\'t be empty');
                return;
              }

              bool hasChanged = questionController.text != widget.question.question ||
                  answerController.text != widget.question.answer ||
                  explanationController.text != widget.question.explanation ||
                  point != widget.question.point;

              if (!hasChanged) {
                logger.i('No change, exiting');
                Navigator.of(context).pop();
                return;
              }
              final newQ = FinishQuestion(
                point: point,
                question: questionController.text,
                answer: answerController.text,
                explanation: explanationController.text,
              );

              logger.i('Modified finish question');
              Navigator.of(context).pop(newQ);
            },
            child: const Text('Done', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: fontSizeMedium, color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () {
              logger.i('Cancelled');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
