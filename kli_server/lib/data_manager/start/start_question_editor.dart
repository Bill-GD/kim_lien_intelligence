import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class StartEditorDialog extends StatefulWidget {
  final StartQuestion? question;
  final int playerPos;
  const StartEditorDialog({super.key, required this.question, required this.playerPos});

  @override
  State<StartEditorDialog> createState() => _StartEditorDialogState();
}

class _StartEditorDialogState extends State<StartEditorDialog> {
  final questionController = TextEditingController();
  final answerController = TextEditingController();
  late QuestionSubject type;
  int pos = -1;

  String? qErrorText, aErrorText;

  @override
  void initState() {
    super.initState();
    logger.i('Opened start question editor');
    if (widget.question != null) {
      logger.i('Modify start question');
      questionController.text = widget.question!.question;
      answerController.text = widget.question!.answer;
      type = widget.question!.subject;
      pos = widget.playerPos;
    } else {
      logger.i('Add new start question');
      type = QuestionSubject.math;
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.symmetric(vertical: 32),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownMenu(
              label: const Text('Pos'),
              textStyle: const TextStyle(fontSize: fontSizeMSmall),
              initialSelection: pos,
              dropdownMenuEntries: [
                for (var i = 1; i < 5; i++)
                  DropdownMenuEntry(
                    value: i - 1,
                    label: '$i',
                  )
              ],
              onSelected: (value) async {
                pos = value!;
                setState(() {});
              },
            ),
            DropdownMenu(
              label: const Text('Type'),
              textStyle: const TextStyle(fontSize: fontSizeMSmall),
              initialSelection: type,
              dropdownMenuEntries: [
                for (final s in QuestionSubject.values)
                  DropdownMenuEntry(
                    value: s,
                    label: StartQuestion.mapTypeDisplay(s),
                  )
              ],
              onSelected: (value) async {
                type = value!;
                setState(() {});
              },
            ),
          ],
        ),
        contentPadding: const EdgeInsets.only(bottom: 40, left: 60, right: 60),
        content: Column(
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
              if (pos < 0) {
                showToastMessage(context, 'Position can\'t be empty');
                return;
              }

              bool hasChanged = widget.question == null
                  ? true
                  : questionController.text != widget.question!.question ||
                      answerController.text != widget.question!.answer ||
                      type != widget.question!.subject ||
                      pos != widget.playerPos;

              if (!hasChanged) {
                logger.i('No change, exiting');
                Navigator.of(context).pop();
                return;
              }

              final newQ = StartQuestion(
                type,
                questionController.text,
                answerController.text,
              );

              logger.i(
                '${widget.question == null ? 'Created' : 'Modified'} start question: ${newQ.subject.name}',
              );
              Navigator.of(context).pop((pos, newQ));
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
