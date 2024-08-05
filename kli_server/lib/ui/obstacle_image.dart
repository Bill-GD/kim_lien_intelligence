import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';

class ObstacleImageScreen extends StatefulWidget {
  const ObstacleImageScreen({super.key});

  @override
  State<ObstacleImageScreen> createState() => _ObstacleImageScreenState();
}

class _ObstacleImageScreenState extends State<ObstacleImageScreen> {
  Size imageSize = const Size(0, 0);

  @override
  void initState() {
    super.initState();
    FileImage(
      File(StorageHandler.getFullPath(MatchState().obstacleMatch!.imagePath)),
    ).resolve(const ImageConfiguration()).addListener(ImageStreamListener((image, _) {
      imageSize = Size(image.image.width.toDouble(), image.image.height.toDouble());
      setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      child: Scaffold(
        appBar: managerAppBar(
          context,
          'Obstacle',
          implyLeading: true,
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            constraints: BoxConstraints.loose(const Size(1600, 900)),
            child: Stack(
              children: [
                Image.file(
                  File(StorageHandler.getFullPath(MatchState().obstacleMatch!.imagePath)),
                  fit: BoxFit.contain,
                ),
                Positioned.fill(
                  child: Stack(
                    children: [
                      for (var i = 0; i < 5; i++)
                        if (!MatchState().revealedImageParts[i]) ImageCover(id: i + 1, size: imageSize),
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
