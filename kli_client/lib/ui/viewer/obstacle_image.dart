import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class ViewerObstacleImageScreen extends StatefulWidget {
  final String imagePath;
  final List<bool> revealedImageParts;
  const ViewerObstacleImageScreen({super.key, required this.imagePath, required this.revealedImageParts});

  @override
  State<ViewerObstacleImageScreen> createState() => _ViewerObstacleImageScreenState();
}

class _ViewerObstacleImageScreenState extends State<ViewerObstacleImageScreen> {
  Size imageSize = const Size(0, 0);
  late StreamSubscription<KLISocketMessage> sub;

  @override
  void initState() {
    super.initState();
    FileImage(
      File(widget.imagePath),
    ).resolve(const ImageConfiguration()).addListener(ImageStreamListener((image, _) {
      imageSize = Size(image.image.width.toDouble(), image.image.height.toDouble());
      setState(() {});
    }));
    sub = KLIClient.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.pop) {
        Navigator.of(context).pop();
      }
    });
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: isTesting,
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            constraints: BoxConstraints.loose(const Size(1600, 900)),
            child: Stack(
              children: [
                Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                ),
                Positioned.fill(
                  child: Stack(
                    children: [
                      for (var i = 0; i < 5; i++)
                        if (!widget.revealedImageParts[i]) ImageCover(id: i + 1, size: imageSize),
                    ],
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
