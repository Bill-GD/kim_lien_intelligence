import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class AccelQuestionEditor extends StatefulWidget {
  final AccelQuestion? question;
  const AccelQuestionEditor({super.key, this.question});

  @override
  State<AccelQuestionEditor> createState() => _AccelQuestionEditorState();
}

class _AccelQuestionEditorState extends State<AccelQuestionEditor> {
  final questionController = TextEditingController(),
      answerController = TextEditingController(),
      explanationController = TextEditingController();
  AccelQuestionType type = AccelQuestionType.none;
  String? qErrorText, aErrorText;

  bool createNew = false, disableDone = true;

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Accel Question Editor');

    if (widget.question != null) {
      logHandler.info('Objective: Modify accel question');
      questionController.text = widget.question!.question;
      answerController.text = widget.question!.answer;
      explanationController.text = widget.question!.explanation;
      type = widget.question!.type;
      disableDone = questionController.text.isEmpty || answerController.text.isEmpty;
    } else {
      logHandler.info('Objective: Add new accel question');
      createNew = true;
      questionController.text = '';
      answerController.text = '';
      explanationController.text = '';
    }
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
        titlePadding: const EdgeInsets.symmetric(vertical: 15),
        title: const Text(''),
        contentPadding: const EdgeInsets.only(bottom: 32, left: 60, right: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            KLITextField(
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
              labelText: 'Câu hỏi',
              errorText: qErrorText,
            ),
            const SizedBox(height: 30),
            KLITextField(
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
              labelText: 'Đáp án',
              errorText: aErrorText,
            ),
            const SizedBox(height: 30),
            KLITextField(
              controller: explanationController,
              maxLines: 3,
              minLines: 1,
              labelText: 'Giải thích',
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: <Widget>[
          TextButton(
            onPressed: disableDone
                ? null
                : () {
                    final qTrim = questionController.text.trim(),
                        aTrim = answerController.text.trim(),
                        eTrim = explanationController.text.trim();
                    bool hasChanged = createNew
                        ? true
                        : qTrim != widget.question!.question ||
                            aTrim != widget.question!.answer ||
                            eTrim != widget.question!.explanation ||
                            type != widget.question!.type;

                    if (!hasChanged) {
                      logHandler.info('No change, exiting');
                      Navigator.of(context).pop();
                      return;
                    }
                    final newQ = AccelQuestion(
                      type: type,
                      question: qTrim,
                      answer: aTrim,
                      explanation: eTrim,
                      imagePaths: createNew ? [] : widget.question!.imagePaths,
                    );

                    logHandler.info('${createNew ? 'Created' : 'Modified'} accel question');
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
