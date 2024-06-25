import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:kli_server/global.dart';

import '../data_manager/match_state.dart';

class ObstacleImageScreen extends StatefulWidget {
  final DecorationImage background;

  const ObstacleImageScreen({super.key, required this.background});

  @override
  State<ObstacleImageScreen> createState() => _ObstacleImageScreenState();
}

class _ObstacleImageScreenState extends State<ObstacleImageScreen> {
  final image = Image.file(
    File(StorageHandler.getFullPath(MatchState.i.obstacleMatch!.imagePath)),
    fit: BoxFit.contain,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: widget.background),
      child: Scaffold(
        appBar: managerAppBar(
          context,
          'Obstacle',
          implyLeading: true,
        ),
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.white54,
              ),
              image,
            ],
          ),
        ),
      ),
    );
  }
}
