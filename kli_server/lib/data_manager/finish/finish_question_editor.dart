import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';
import 'package:video_player/video_player.dart';

import '../../global.dart';

class FinishEditorDialog extends StatefulWidget {
  final FinishQuestion question;
  const FinishEditorDialog({super.key, required this.question});

  @override
  State<FinishEditorDialog> createState() => _FinishEditorDialogState();
}

class _FinishEditorDialogState extends State<FinishEditorDialog> {
  final questionController = TextEditingController(),
      answerController = TextEditingController(),
      explanationController = TextEditingController();
  String? qErrorText, aErrorText;

  late final VideoPlayerController vidController;

  bool changedMedia = false;
  int selectedPointValue = -1;

  @override
  void initState() {
    super.initState();
    logger.i('Opened finish question editor');
    if (widget.question.mediaPath.isNotEmpty) {
      changeVideoSource(widget.question.mediaPath);
    }
    questionController.text = widget.question.question;
    answerController.text = widget.question.answer;
    explanationController.text = widget.question.explanation;
    selectedPointValue = widget.question.point;
    setState(() {});
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
    explanationController.dispose();
    vidController.dispose();
    super.dispose();
  }

  Future<void> changeVideoSource(String relativePath) async {
    vidController = VideoPlayerController.file(File(storageHandler!.parentFolder + relativePath));
    await vidController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.symmetric(vertical: 32),
        title: Center(
          child: DropdownMenu(
            label: const Text('Point'),
            textStyle: const TextStyle(fontSize: fontSizeMSmall),
            initialSelection: selectedPointValue,
            dropdownMenuEntries: [
              for (final s in [10, 20, 30])
                DropdownMenuEntry(
                  value: s,
                  label: '$s',
                )
            ],
            onSelected: (value) async {
              selectedPointValue = value!;
              setState(() {});
            },
          ),
        ),
        contentPadding: const EdgeInsets.only(bottom: 40, left: 60, right: 60),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextField(
                    style: const TextStyle(fontSize: fontSizeMedium),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        qErrorText = 'Can\'t be empty';
                        setState(() {});
                        return;
                      }
                      setState(() => qErrorText = null);
                    },
                    controller: questionController,
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      errorText: qErrorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(fontSize: fontSizeMedium),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        aErrorText = 'Can\'t be empty';
                        setState(() {});
                        return;
                      }
                      setState(() => aErrorText = null);
                    },
                    controller: answerController,
                    decoration: InputDecoration(
                      labelText: 'Answer',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      errorText: aErrorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(fontSize: fontSizeMedium),
                    controller: explanationController,
                    decoration: InputDecoration(
                      labelText: 'Explanation',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 32, bottom: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                    ),
                    constraints: const BoxConstraints(maxHeight: 400, maxWidth: 710),
                    child: widget.question.mediaPath.isEmpty
                        ? const Center(child: Text('No Video'))
                        : ColoredBox(
                            color: Colors.black38,
                            child: Stack(
                              children: [
                                VideoPlayer(vidController),
                                Positioned(
                                  bottom: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ValueListenableBuilder(
                                        valueListenable: vidController,
                                        builder: (_, v, ___) => IconButton(
                                          icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow_rounded),
                                          onPressed: () {
                                            v.isPlaying ? vidController.pause() : vidController.play();
                                          },
                                        ),
                                      ),
                                      ValueListenableBuilder(
                                        valueListenable: vidController,
                                        builder: ((_, __, ___) {
                                          int min = vidController.value.position.inMinutes;
                                          int sec = (vidController.value.position.inSeconds % 60);
                                          return Text(
                                            "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}",
                                          );
                                        }),
                                      ),
                                      ValueListenableBuilder(
                                        valueListenable: vidController,
                                        builder: (_, __, ___) => Slider(
                                          value: vidController.value.position.inMilliseconds * 1.0,
                                          min: 0,
                                          max: vidController.value.duration.inMilliseconds * 1.0,
                                          onChanged: (_) {},
                                          onChangeEnd: (value) {
                                            vidController.seekTo(Duration(milliseconds: value.toInt()));
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: const Text('Select Video'),
                        onPressed: () async {
                          logger.i(
                            'Selecting video at ${storageHandler!.getRelative(storageHandler!.mediaDir)}',
                          );
                          final result = await FilePicker.platform.pickFiles(
                            dialogTitle: 'Select image',
                            initialDirectory: storageHandler!.mediaDir.replaceAll('/', '\\'),
                            type: FileType.video,
                          );

                          if (result != null) {
                            final p = result.files.single.path!;
                            widget.question.mediaPath = storageHandler!.getRelative(p);
                            await changeVideoSource(widget.question.mediaPath);
                            logger.i('Chose ${widget.question.mediaPath}');
                            changedMedia = true;
                            setState(() {});
                          }
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Remove Video'),
                        onPressed: () {
                          logger.i('Removing video');

                          widget.question.mediaPath = '';
                          changedMedia = true;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (questionController.text.isEmpty) {
                showToastMessage(context, 'Question can\'t be empty');
                return;
              }
              if (answerController.text.isEmpty) {
                showToastMessage(context, 'Answer can\'t be empty');
                return;
              }

              bool hasChanged = questionController.text != widget.question.question ||
                  answerController.text != widget.question.answer ||
                  explanationController.text != widget.question.explanation ||
                  selectedPointValue != widget.question.point ||
                  changedMedia;

              if (!hasChanged) {
                logger.i('No change, exiting');
                Navigator.of(context).pop();
                return;
              }
              final newQ = FinishQuestion(
                point: selectedPointValue,
                question: questionController.text,
                answer: answerController.text,
                explanation: explanationController.text,
                mediaPath: widget.question.mediaPath,
              );

              logger.i('Modified finish question');
              Navigator.of(context).pop(newQ);
            },
            child: const Text('Done', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          TextButton(
            child: Text(
              'Cancel',
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
