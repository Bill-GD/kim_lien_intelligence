import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:kli_server/global.dart';

import '../data_manager/match_state.dart';

class ObstacleImageScreen extends StatefulWidget {
  const ObstacleImageScreen({super.key});

  @override
  State<ObstacleImageScreen> createState() => _ObstacleImageScreenState();
}

class _ObstacleImageScreenState extends State<ObstacleImageScreen> {
  Size imageSize = const Size(0, 0);

  @override
  void initState() {
    FileImage(
      File(StorageHandler.getFullPath(MatchState().obstacleMatch!.imagePath)),
    ).resolve(const ImageConfiguration()).addListener(ImageStreamListener((image, _) {
      imageSize = Size(image.image.width.toDouble(), image.image.height.toDouble());
      setState(() {});
    }));
    super.initState();
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
                        if (!MatchState().revealedImageParts[i]) _ImageCover(id: i + 1, size: imageSize),
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

class _ImageCover extends StatelessWidget {
  final int id;
  final Size size;
  const _ImageCover({required this.id, required this.size});

  @override
  Widget build(BuildContext context) {
    final (start, end, top, bottom) = switch (id) {
      1 => (0, 0.5, 0, 0.5),
      2 => (0.5, 0, 0, 0.5),
      3 => (0, 0.5, 0.5, 0),
      4 => (0.5, 0, 0.5, 0),
      5 => (0.3, 0.3, 0.3, 0.3),
      _ => throw Exception('Invalid id: $id'),
    };

    return Positioned.fill(
      left: size.width * start,
      right: size.width * end,
      top: size.height * top,
      bottom: size.height * bottom,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          '$id',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: fontSizeLarge),
        ),
      ),
    );
  }
}
