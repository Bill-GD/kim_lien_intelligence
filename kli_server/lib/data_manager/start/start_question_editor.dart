import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class StartQuestionEditor extends StatefulWidget {
  final StartQuestion? question;
  const StartQuestionEditor({super.key, required this.question});

  @override
  State<StartQuestionEditor> createState() => _StartQuestionEditorState();
}

class _StartQuestionEditorState extends State<StartQuestionEditor> {
  final questionController = TextEditingController();
  final answerController = TextEditingController();
  late StartQuestionSubject type;
  int pos = -1;

  String? qErrorText, aErrorText;

  bool disableDone = true;

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Start Question Editor');

    if (widget.question != null) {
      logHandler.info('Modify start question');
      questionController.text = widget.question!.question;
      answerController.text = widget.question!.answer;
      type = widget.question!.subject;
      pos = widget.question!.pos;
      disableDone = questionController.text.isEmpty || answerController.text.isEmpty || pos < 0;
    } else {
      logHandler.info('Add new start question');
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
                  for (var i = 0; i < 4; i++)
                    DropdownMenuEntry(
                      value: i,
                      label: '${i + 1}',
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
            KLITextField(
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
              labelText: 'Câu hỏi',
              errorText: qErrorText,
            ),
            const SizedBox(height: 30),
            KLITextField(
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
              labelText: 'Đáp án',
              errorText: aErrorText,
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
                            pos != widget.question!.pos;

                    if (!hasChanged) {
                      logHandler.info('No change, exiting');
                      Navigator.of(context).pop();
                      return;
                    }

                    final newQ = StartQuestion(
                      pos: pos,
                      subject: type,
                      question: qTrim,
                      answer: aTrim,
                    );

                    logHandler.info(
                      '${widget.question == null ? 'Created' : 'Modified'} start question: ${newQ.subject.name}',
                    );
                    Navigator.of(context).pop(newQ);
                  },
            child: const Text('Hoàn tất', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          TextButton(
            child: Text(
              'Hủy',
              style: TextStyle(fontSize: fontSizeMedium, color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () {
              logHandler.info('Cancelled');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
