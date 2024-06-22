import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';

class MatchEditor extends StatefulWidget {
  final KLIMatch? match;
  final Iterable<String> matchNames;
  const MatchEditor({super.key, this.match, required this.matchNames});

  @override
  State<MatchEditor> createState() => _MatchEditorState();
}

class _MatchEditorState extends State<MatchEditor> {
  final TextEditingController matchNameController = TextEditingController();
  final List<TextEditingController> playerNameControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final imagePaths = List<String>.filled(4, '');

  String matchNameError = '';
  bool disableDone = true, setNewMatch = false;

  @override
  void initState() {
    super.initState();
    disableDone = setNewMatch = widget.match == null;
    logHandler.info('Match editor: ${setNewMatch ? 'New match' : 'Modify ${widget.match?.name}'}');
    logHandler.depth = 3;
    if (setNewMatch) return;

    matchNameController.text = widget.match!.name;
    for (int i = 0; i < widget.match!.playerList.length; i++) {
      playerNameControllers[i].text = widget.match!.playerList[i]?.name ?? '';
      imagePaths[i] = widget.match!.playerList[i]?.imagePath ?? '';
    }
  }

  @override
  void dispose() {
    for (var c in [matchNameController, ...playerNameControllers]) {
      c.dispose();
    }
    logHandler.depth = 2;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 256),
        title: KLITextField(
          style: const TextStyle(fontSize: fontSizeSmall),
          onChanged: (value) {
            if (value.isEmpty) {
              matchNameError = 'Không được trống';
              disableDone = true;
              setState(() {});
              return;
            }
            if (value != widget.match?.name && widget.matchNames.contains(value)) {
              matchNameError = 'Bị trùng tên';
              disableDone = true;
              setState(() {});
              return;
            }
            setState(() {
              matchNameError = '';
              disableDone = false;
            });
          },
          controller: matchNameController,
          labelText: 'Tên trận đấu',
          errorText: matchNameError.isEmpty ? null : matchNameError,
        ),
        contentPadding: const EdgeInsets.only(bottom: 40),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [for (int i = 0; i < 4; i++) playerWidget(i)],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: <Widget>[
          TextButton(
            onPressed: disableDone
                ? null
                : () {
                    if (matchNameController.text.isEmpty) {
                      showToastMessage(context, 'Tên trận không được trống');
                      return;
                    }

                    for (var e in playerNameControllers) {
                      if (e.value.text.isNotEmpty && imagePaths[playerNameControllers.indexOf(e)].isEmpty) {
                        showToastMessage(
                          context,
                          'Hãy chọn ảnh cho thí sinh ${playerNameControllers.indexOf(e) + 1}',
                        );
                        return;
                      }
                      if (e.value.text.isEmpty && imagePaths[playerNameControllers.indexOf(e)].isNotEmpty) {
                        showToastMessage(
                          context,
                          'Tên thí sinh ${playerNameControllers.indexOf(e) + 1} không được trống',
                        );
                        return;
                      }
                    }

                    final newMatch = KLIMatch(
                      name: matchNameController.text.trim(),
                      playerList: playerNameControllers.map((c) {
                        return c.text.isEmpty
                            ? null
                            : KLIPlayer(c.text.trim(), imagePaths[playerNameControllers.indexOf(c)]);
                      }).toList(),
                    );

                    logHandler.info('${setNewMatch ? 'New' : 'Modified'} match: ${newMatch.name}');

                    Navigator.of(context).pop(newMatch);
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

  Widget playerWidget(int index) {
    bool imageFound = false;
    String fullPath = '';
    if (imagePaths[index].isNotEmpty) {
      fullPath = '${storageHandler.parentFolder}\\${imagePaths[index]}';
      imageFound = File(fullPath).existsSync();
    }
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Text(
              'Thí sinh ${index + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: fontSizeMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: KLITextField(
                style: const TextStyle(fontSize: fontSizeSmall),
                controller: playerNameControllers[index],
                labelText: 'Tên',
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
              ),
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300, minHeight: 1, minWidth: 260),
              child: imagePaths[index].isEmpty || !imageFound
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      child: Text(imagePaths[index].isEmpty ? 'Không có ảnh' : 'Không thấy ảnh $fullPath'),
                    )
                  : Image.file(File(fullPath), fit: BoxFit.contain),
            ),
            ElevatedButton(
              child: const Text('Chọn ảnh'),
              onPressed: () async {
                logHandler.info('Selecting image at ${StorageHandler.getRelative(storageHandler.mediaDir)}',
                    d: 3);
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: 'Select image',
                  initialDirectory: storageHandler.mediaDir.replaceAll('/', '\\'),
                  type: FileType.image,
                );

                if (result == null) return;

                final p = result.files.single.path!;
                imagePaths[index] = StorageHandler.getRelative(p);
                logHandler.info('Chose ${imagePaths[index]} for player ${index + 1}');
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
