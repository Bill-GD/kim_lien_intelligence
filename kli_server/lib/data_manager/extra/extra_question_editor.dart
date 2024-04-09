import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class ExtraEditorDialog extends StatefulWidget {
  final ExtraQuestion question;
  const ExtraEditorDialog({super.key, required this.question});

  @override
  State<ExtraEditorDialog> createState() => _ExtraEditorDialogState();
}

class _ExtraEditorDialogState extends State<ExtraEditorDialog> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  String? _qErrorText, _aErrorText;

  @override
  void initState() {
    super.initState();
    logger.i('Opened obstacle question editor');
    _questionController.text = widget.question.question;
    _answerController.text = widget.question.answer;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
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
                if (value.isEmpty) {
                  _qErrorText = 'Can\'t be empty';
                  setState(() {});
                  return;
                }
                setState(() => _qErrorText = null);
              },
              controller: _questionController,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Question',
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
                errorText: _qErrorText,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              style: const TextStyle(fontSize: fontSizeMedium),
              onChanged: (value) {
                if (value.isEmpty) {
                  _aErrorText = 'Can\'t be empty';
                  setState(() {});
                  return;
                }
                setState(() => _aErrorText = null);
              },
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Answer',
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
                errorText: _aErrorText,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (_questionController.text.isEmpty) {
                showToastMessage(context, 'Question can\'t be empty');
                return;
              }
              if (_answerController.text.isEmpty) {
                showToastMessage(context, 'Answer can\'t be empty');
                return;
              }

              bool hasChanged = _questionController.text != widget.question.question ||
                  _answerController.text != widget.question.answer;

              if (!hasChanged) {
                logger.i('No change, exiting');
                Navigator.of(context).pop();
                return;
              }
              final newQ = ExtraQuestion(
                question: _questionController.text,
                answer: _answerController.text,
              );

              logger.i('Modified extra question');
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
