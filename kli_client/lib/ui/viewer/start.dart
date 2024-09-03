import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:kli_client/global.dart';
import 'package:kli_lib/kli_lib.dart';

class ViewerStartScreen extends StatefulWidget {
  const ViewerStartScreen({super.key});

  @override
  State<ViewerStartScreen> createState() => _ViewerStartScreenState();
}

class _ViewerStartScreenState extends State<ViewerStartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isPlaying = false;
  int maxDuration = 15;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    Window.setEffect(effect: WindowEffect.transparent);

    _controller = AnimationController(vsync: this, duration: Duration(seconds: maxDuration))
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          isPlaying = false;
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, automaticallyImplyLeading: isTesting),
      extendBodyBehindAppBar: true,
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              (maxDuration - _controller.value * maxDuration).toInt().toString(),
              style: const TextStyle(color: Colors.white, fontSize: 50),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            child: Text(
                              'Câu hỏi questionNum',
                              style: TextStyle(fontSize: fontSizeLarge),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              border: BorderDirectional(
                                top: BorderSide(color: Colors.white),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 128),
                            alignment: Alignment.center,
                            child: const Text(
                              'canShowQuestion ? currentQuestion.question : ' '',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: fontSizeLarge),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      width: 300,
                      child: CustomPaint(
                        painter: RRectProgressPainter(
                          value: maxDuration - _controller.value * maxDuration,
                          minValue: 0,
                          maxValue: maxDuration.toDouble(),
                          foregroundColor: Colors.green,
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            KLIButton(
              isPlaying ? 'Reset' : 'Play',
              onPressed: () {
                if (isPlaying) {
                  _controller.reset();
                } else {
                  _controller.reset();
                  _controller.forward();
                }
                isPlaying = !isPlaying;
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
