import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class ObstacleQuestionEditorDialog extends StatefulWidget {
  final ObstacleQuestion? question;
  final int index;
  const ObstacleQuestionEditorDialog({super.key, this.question, required this.index});

  @override
  State<ObstacleQuestionEditorDialog> createState() => _ObstacleQuestionEditorDialogState();
}

class _ObstacleQuestionEditorDialogState extends State<ObstacleQuestionEditorDialog> {
  final questionController = TextEditingController();
  final answerController = TextEditingController();
  String? qErrorText, aErrorText;
  bool disableDone = true;

  @override
  void initState() {
    super.initState();
    logger.i('Opened obstacle question editor');
    if (widget.question != null) {
      disableDone = questionController.text.isEmpty || answerController.text.isEmpty;
      questionController.text = widget.question!.question;
      answerController.text = widget.question!.answer;
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
        titlePadding: const EdgeInsets.symmetric(vertical: 40, horizontal: 256),
        contentPadding: const EdgeInsets.only(bottom: 32, left: 60, right: 60),
        title: Text(
          widget.index < 4 ? 'Hàng ngang ${widget.index + 1}' : 'Trung tâm',
          textAlign: TextAlign.center,
        ),
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
                    bool hasChanged = widget.question == null
                        ? true
                        : qTrim != widget.question!.question || aTrim != widget.question!.answer;

                    if (!hasChanged) {
                      logger.i('No change, exiting');
                      Navigator.of(context).pop();
                      return;
                    }

                    final newQ = ObstacleQuestion(
                      id: widget.index,
                      question: qTrim,
                      answer: aTrim,
                      charCount: aTrim.replaceAll(' ', '').length,
                    );

                    logger.i('Modified obstacle question: ${newQ.id}');
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
              logger.i('Cancelled');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
