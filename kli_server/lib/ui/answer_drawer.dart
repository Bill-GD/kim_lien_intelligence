import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

class AnswerDrawer extends StatefulWidget {
  final Iterable<(String, double)> answers;
  final Iterable<String> playerNames;
  final Iterable<int> scores;
  final List<bool?> answerResult;
  final void Function(int, bool?) checkboxOnChanged;
  final bool showTime;
  final bool canCheck;
  final List<Widget> actions;
  const AnswerDrawer({
    super.key,
    required this.answers,
    required this.scores,
    required this.playerNames,
    required this.checkboxOnChanged,
    required this.answerResult,
    this.showTime = false,
    required this.canCheck,
    this.actions = const [],
  });

  @override
  State<AnswerDrawer> createState() => _AnswerDrawerState();
}

class _AnswerDrawerState extends State<AnswerDrawer> {
  bool viewerShowingAnswers = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 800,
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 32, right: 24),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var e in widget.answers.toList().asMap().entries)
                    Container(
                      decoration: BoxDecoration(
                        color: widget.answerResult[e.key] == null
                            ? Theme.of(context).colorScheme.background
                            : widget.answerResult[e.key]!
                                ? Colors.green.withOpacity(0.6)
                                : Colors.red.withOpacity(0.6),
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(bottom: 32),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            if (widget.showTime)
                              Container(
                                constraints: const BoxConstraints(minWidth: 128),
                                decoration: const BoxDecoration(
                                  border: BorderDirectional(end: BorderSide(color: Colors.white)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  e.value.$2 <= 0 ? '0' : '${e.value.$2}',
                                  style: const TextStyle(fontSize: fontSizeMedium),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16, bottom: 6),
                                    child: Text(
                                      '${widget.playerNames.elementAt(e.key)} (${widget.scores.elementAt(e.key)})',
                                      style: const TextStyle(fontSize: fontSizeMedium),
                                    ),
                                  ),
                                  const Divider(color: Colors.white, thickness: 1),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, bottom: 16),
                                    child: Text(
                                      e.value.$1,
                                      style: const TextStyle(fontSize: fontSizeMedium),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 64),
                              decoration: const BoxDecoration(
                                border: BorderDirectional(start: BorderSide(color: Colors.white)),
                              ),
                              alignment: Alignment.center,
                              child: Checkbox.adaptive(
                                value: widget.answerResult[e.key],
                                tristate: true,
                                onChanged: widget.canCheck ? (v) => widget.checkboxOnChanged(e.key, v) : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                KLIButton(
                  '${viewerShowingAnswers ? 'Hide' : 'Show'} answers',
                  // enableCondition: widget.canCheck,
                  onPressed: () {
                    KLIServer.sendToNonPlayer(KLISocketMessage(
                      senderID: ConnectionID.host,
                      type: KLIMessageType.showAnswers,
                      message: viewerShowingAnswers
                          ? ''
                          : jsonEncode({
                              'answers': widget.answers.map((e) => e.$1).toList(),
                              'times': widget.answers.map((e) => max(e.$2, 0.0)).toList(),
                            }),
                    ));
                    viewerShowingAnswers = !viewerShowingAnswers;
                    setState(() {});
                  },
                ),
                KLIButton(
                  'All correct',
                  enableCondition: widget.canCheck,
                  onPressed: () {
                    for (var i = 0; i < widget.answers.length; i++) {
                      widget.checkboxOnChanged(i, true);
                    }
                  },
                ),
                KLIButton(
                  'All wrong',
                  enableCondition: widget.canCheck,
                  onPressed: () {
                    for (var i = 0; i < widget.answers.length; i++) {
                      widget.checkboxOnChanged(i, false);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.actions,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
