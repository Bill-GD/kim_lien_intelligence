import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class ExtraEditorDialog extends StatefulWidget {
  final ExtraQuestion? question;
  const ExtraEditorDialog({super.key, this.question});

  @override
  State<ExtraEditorDialog> createState() => _ExtraEditorDialogState();
}

class _ExtraEditorDialogState extends State<ExtraEditorDialog> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  String? _qErrorText, _aErrorText;

  bool createNew = false;

  @override
  void initState() {
    super.initState();
    logger.i('Opened obstacle question editor');
    if (widget.question != null) {
      logger.i('Modify extra question');
      _questionController.text = widget.question!.question;
      _answerController.text = widget.question!.answer;
    } else {
      logger.i('Add new extra question');
      createNew = true;
      _questionController.text = '';
      _answerController.text = '';
    }
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
                  _qErrorText = 'Không được trống';
                  setState(() {});
                  return;
                }
                setState(() => _qErrorText = null);
              },
              controller: _questionController,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Câu hỏi',
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
                  _aErrorText = 'Không được trống';
                  setState(() {});
                  return;
                }
                setState(() => _aErrorText = null);
              },
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Đáp án',
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

              bool hasChanged = createNew
                  ? true
                  : _questionController.text != widget.question!.question ||
                      _answerController.text != widget.question!.answer;

              if (!hasChanged) {
                logger.i('No change, exiting');
                Navigator.of(context).pop();
                return;
              }
              final newQ = ExtraQuestion(
                question: _questionController.text,
                answer: _answerController.text,
              );

              logger.i('${createNew ? 'Created' : 'Modified'} extra question');
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
