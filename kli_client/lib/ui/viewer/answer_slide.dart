import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class ViewerAnswerSlide extends StatefulWidget {
  final bool showTime;
  final Iterable<String> playerNames, answers;
  final Iterable<double> times;
  const ViewerAnswerSlide({
    super.key,
    this.showTime = true,
    required this.playerNames,
    required this.answers,
    required this.times,
  });

  @override
  State<ViewerAnswerSlide> createState() => _ViewerAnswerSlideState();
}

class _ViewerAnswerSlideState extends State<ViewerAnswerSlide> {
  static const offScreenOffset = 1.1;
  late final StreamSubscription<KLISocketMessage> sub;
  Offset offset = const Offset(offScreenOffset, 0);
  bool showAnswers = false;
  Iterable<bool?> answerResult = Iterable.generate(4, (_) => null);

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    Future.delayed(300.ms, () {
      offset = Offset(0, offset.dy);
      setState(() {});
    });
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.revealAnswerResults) {
        answerResult = (jsonDecode(m.message) as List).map((e) => e as bool?);
        setState(() {});
      }
      if (m.type == KLIMessageType.showAnswers) {
        Navigator.pop(context);
      }
      if (m.type == KLIMessageType.pop) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ViewerAnswerSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateChild = () => setState(() {});
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: isTesting,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 160),
          child: AnimatedSlide(
            offset: offset,
            duration: 1.seconds,
            curve: Curves.linear,
            onEnd: () => Future.delayed(500.ms, () => setState(() => showAnswers = offset.dx == 0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final i in range(0, 3))
                  Container(
                    decoration: BoxDecoration(
                      color: answerResult.elementAt(i) == null
                          ? Theme.of(context).colorScheme.background
                          : answerResult.elementAt(i)!
                              ? Colors.green.withOpacity(0.6)
                              : Colors.red.withOpacity(0.6),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          if (widget.showTime)
                            Container(
                              constraints: const BoxConstraints(minWidth: 160),
                              decoration: const BoxDecoration(
                                border: BorderDirectional(end: BorderSide(color: Colors.white)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                showAnswers
                                    ? widget.times.elementAt(i) == 0
                                        ? '0'
                                        : widget.times.elementAt(i).toString()
                                    : '',
                                style: const TextStyle(fontSize: fontSizeLarge),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 16, bottom: 12, left: 32),
                                  child: Text(
                                    showAnswers ? widget.playerNames.elementAt(i) : '',
                                    style: const TextStyle(fontSize: fontSizeLarge),
                                  ),
                                ),
                                const Divider(color: Colors.white, thickness: 1),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 16, left: 32),
                                  child: Text(
                                    showAnswers ? widget.answers.elementAt(i) : '',
                                    style: const TextStyle(fontSize: fontSizeLarge),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
