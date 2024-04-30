import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

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
  late StartQuestionSubject type;
  int pos = -1;

  String? qErrorText, aErrorText;

  bool disableDone = true;

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
      disableDone = questionController.text.isEmpty || answerController.text.isEmpty || pos < 0;
    } else {
      logger.i('Add new start question');
      type = StartQuestionSubject.math;
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
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownMenu(
                label: const Text('Vị trí'),
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
                  disableDone = questionController.text.isEmpty || answerController.text.isEmpty || pos < 0;
                  setState(() {});
                },
              ),
              DropdownMenu(
                label: const Text('Lĩnh vực'),
                textStyle: const TextStyle(fontSize: fontSizeMSmall),
                initialSelection: type,
                dropdownMenuEntries: [
                  for (final s in StartQuestionSubject.values)
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
        ),
        contentPadding: const EdgeInsets.only(bottom: 40, left: 32, right: 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextField(
              style: const TextStyle(fontSize: fontSizeMedium),
              onChanged: (value) {
                disableDone = questionController.text.isEmpty || answerController.text.isEmpty || pos < 0;
                if (value.isEmpty) {
                  qErrorText = 'Không được trống';
                  setState(() {});
                  return;
                }
                setState(() => qErrorText = null);
              },
              controller: questionController,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Câu hỏi',
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
                disableDone = questionController.text.isEmpty || answerController.text.isEmpty || pos < 0;
                if (value.isEmpty) {
                  aErrorText = 'Không được trống';
                  setState(() {});
                  return;
                }
                setState(() => aErrorText = null);
              },
              controller: answerController,
              decoration: InputDecoration(
                labelText: 'Đáp án',
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
            onPressed: disableDone
                ? null
                : () {
                    final qTrim = questionController.text.trim(), aTrim = answerController.text.trim();
                    bool hasChanged = widget.question == null
                        ? true
                        : qTrim != widget.question!.question ||
                            aTrim != widget.question!.answer ||
                            type != widget.question!.subject ||
                            pos != widget.playerPos;

                    if (!hasChanged) {
                      logger.i('No change, exiting');
                      Navigator.of(context).pop();
                      return;
                    }

                    final newQ = StartQuestion(subject: type, question: qTrim, answer: aTrim);

                    logger.i(
                      '${widget.question == null ? 'Created' : 'Modified'} start question: ${newQ.subject.name}',
                    );
                    Navigator.of(context).pop((pos, newQ));
                  },
            child: const Text('Hoàn tất', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          TextButton(
            child: Text(
              'Hủy',
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
