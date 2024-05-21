import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class ExtraQuestionEditor extends StatefulWidget {
  final ExtraQuestion? question;
  const ExtraQuestionEditor({super.key, this.question});

  @override
  State<ExtraQuestionEditor> createState() => _ExtraQuestionEditorState();
}

class _ExtraQuestionEditorState extends State<ExtraQuestionEditor> {
  final questionController = TextEditingController();
  final answerController = TextEditingController();
  String? qErrorText, aErrorText;

  bool createNew = false, disableDone = true;

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Extra Question Editor', d: 2);
    if (widget.question != null) {
      logHandler.info('Objective: Modify extra question', d: 3);
      questionController.text = widget.question!.question;
      answerController.text = widget.question!.answer;
    } else {
      logHandler.info('Objective: Add new extra question', d: 3);
      createNew = true;
      questionController.text = '';
      answerController.text = '';
    }
    disableDone = questionController.text.isEmpty || answerController.text.isEmpty;
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
        titlePadding: const EdgeInsets.symmetric(vertical: 10),
        title: const Text(''),
        contentPadding: const EdgeInsets.only(bottom: 32, left: 60, right: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextField(
              style: const TextStyle(fontSize: fontSizeMedium),
              onChanged: (value) {
                disableDone = questionController.text.isEmpty || answerController.text.isEmpty;
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
                disableDone = questionController.text.isEmpty || answerController.text.isEmpty;
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
                    bool hasChanged = createNew
                        ? true
                        : qTrim != widget.question!.question || aTrim != widget.question!.answer;

                    if (!hasChanged) {
                      logHandler.info('No change, exiting', d: 3);
                      Navigator.of(context).pop();
                      return;
                    }
                    final newQ = ExtraQuestion(question: qTrim, answer: aTrim);

                    logHandler.info('${createNew ? 'Created' : 'Modified'} extra question', d: 3);
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
              logHandler.info('Cancelled', d: 3);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
