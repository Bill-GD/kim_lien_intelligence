import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
  static const horizontalPadding = 216.0, offScreenOffset = 1.1;
  late final StreamSubscription<KLISocketMessage> sub;
  Offset offset = const Offset(offScreenOffset, 0);
  bool showAnswers = false;
  Iterable<bool?> answerResult = Iterable.generate(4, (_) => null);
  double answerContainerWidth = 1;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});

    Future.delayed(300.ms, () {
      offset = Offset(0, offset.dy);
      audioHandler.play(assetHandler.accelShowAnswer);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      answerContainerWidth = MediaQuery.of(context).size.width - (horizontalPadding * 2);
      if (widget.showTime) answerContainerWidth -= 160;
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
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: AnimatedSlide(
            offset: offset,
            duration: 1.seconds,
            curve: Curves.linear,
            onEnd: () => Future.delayed(500.ms, () => setState(() => showAnswers = offset.dx == 0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final i in range(0, 3))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          if (widget.showTime)
                            Container(
                              constraints: const BoxConstraints(maxWidth: 160),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                color: containerColor(i),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  topLeft: Radius.circular(10),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                showAnswers ? max(0, widget.times.elementAt(i)).toString() : '',
                                style: const TextStyle(fontSize: fontSizeLarge),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // player name
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                  decoration: BoxDecoration(
                                    color: containerColor(i),
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.only(
                                      topRight: const Radius.circular(10),
                                      topLeft: widget.showTime ? Radius.zero : const Radius.circular(10),
                                    ),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 80),
                                  child: Text(
                                    !widget.showTime || showAnswers ? widget.playerNames.elementAt(i) : '',
                                    style: const TextStyle(fontSize: fontSizeLarge),
                                  ),
                                ),
                                // player answer
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                                  decoration: BoxDecoration(
                                    color: containerColor(i),
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.only(
                                      bottomRight: const Radius.circular(10),
                                      topRight: const Radius.circular(10),
                                      bottomLeft: widget.showTime ? Radius.zero : const Radius.circular(10),
                                    ),
                                  ),
                                  constraints: BoxConstraints(maxWidth: answerContainerWidth),
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

  Color containerColor(int i) {
    if (answerResult.elementAt(i) == null) return Theme.of(context).colorScheme.background;
    return answerResult.elementAt(i)! ? Colors.green.withOpacity(0.6) : Colors.red.withOpacity(0.6);
  }
}
