import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class ObstacleEditor extends StatefulWidget {
  final String keyword, explanation;
  const ObstacleEditor({super.key, required this.keyword, required this.explanation});

  @override
  State<ObstacleEditor> createState() => _ObstacleEditorState();
}

class _ObstacleEditorState extends State<ObstacleEditor> {
  final keywordController = TextEditingController(), explanationController = TextEditingController();
  String? kErrorText, eErrorText;
  bool disableDone = true;

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Obstacle Editor');

    disableDone = keywordController.text.isEmpty || explanationController.text.isEmpty;
    keywordController.text = widget.keyword;
    explanationController.text = widget.explanation;
  }

  @override
  void dispose() {
    keywordController.dispose();
    explanationController.dispose();
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
        title: const Text('Chướng ngại vật', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            KLITextField(
              onChanged: (value) {
                disableDone = keywordController.text.isEmpty || explanationController.text.isEmpty;
                if (value.isEmpty) {
                  kErrorText = 'Không được trống';
                  setState(() {});
                  return;
                }
                setState(() => kErrorText = null);
              },
              controller: keywordController,
              labelText: 'Keyword',
              maxLines: 1,
              errorText: kErrorText,
            ),
            const SizedBox(height: 30),
            KLITextField(
              onChanged: (value) {
                disableDone = keywordController.text.isEmpty || explanationController.text.isEmpty;
                if (value.isEmpty) {
                  eErrorText = 'Không được trống';
                  setState(() {});
                  return;
                }
                setState(() => eErrorText = null);
              },
              controller: explanationController,
              maxLines: 5,
              minLines: 1,
              labelText: 'Explanation',
              errorText: eErrorText,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: <Widget>[
          TextButton(
            onPressed: disableDone
                ? null
                : () {
                    final kTrim = keywordController.text.trim(), eTrim = explanationController.text.trim();
                    bool hasChanged = kTrim != widget.keyword || eTrim != widget.explanation;

                    if (!hasChanged) {
                      logHandler.info('No change, exiting');
                      Navigator.of(context).pop();
                      return;
                    }

                    logHandler.info('Modified obstacle: ${widget.keyword} -> ${keywordController.text}');
                    Navigator.of(context).pop((kTrim, eTrim));
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
