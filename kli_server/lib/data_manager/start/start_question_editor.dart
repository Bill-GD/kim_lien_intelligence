import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class StartEditorDialog extends StatefulWidget {
  final StartQuestion question;
  const StartEditorDialog({super.key, required this.question});

  @override
  State<StartEditorDialog> createState() => _StartEditorDialogState();
}

class _StartEditorDialogState extends State<StartEditorDialog> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  late QuestionSubject _type;
  String? _qErrorText, _aErrorText;

  @override
  void initState() {
    super.initState();
    logger.i('Opened start question editor');
    _questionController.text = widget.question.question;
    _answerController.text = widget.question.answer;
    _type = widget.question.subject;
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
        titlePadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 256),
        title: DropdownMenu(
          label: const Text('Type'),
          initialSelection: _type,
          dropdownMenuEntries: [
            for (final s in QuestionSubject.values)
              DropdownMenuEntry(
                value: s,
                label: StartQuestion.mapTypeDisplay(s),
              )
          ],
          onSelected: (value) async {
            _type = value!;
            setState(() {});
          },
        ),
        contentPadding: const EdgeInsets.only(bottom: 40, left: 60, right: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextField(
              onChanged: (value) {
                if (value.isEmpty) {
                  _qErrorText = 'Can\'t be empty';
                  setState(() {});
                  return;
                }
                setState(() => _qErrorText = null);
              },
              controller: _questionController,
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
                  _answerController.text != widget.question.answer ||
                  _type != widget.question.subject;

              if (!hasChanged) {
                logger.i('No change, exiting');
                Navigator.of(context).pop();
                return;
              }
              final newQ = StartQuestion(
                _type,
                _questionController.text,
                _answerController.text,
                widget.question.match,
                widget.question.playerPos,
              );

              logger.i('Modified question: ${newQ.subject.name}, ${newQ.match}, pos=${newQ.playerPos}');
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
