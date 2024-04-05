import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class MatchEditorDialog extends StatefulWidget {
  final KLIMatch? match;
  const MatchEditorDialog({super.key, this.match});

  @override
  State<MatchEditorDialog> createState() => _MatchEditorDialogState();
}

class _MatchEditorDialogState extends State<MatchEditorDialog> {
  final TextEditingController _matchNameController = TextEditingController();
  final List<TextEditingController> _playerNameControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _imagePaths = List<String>.filled(4, '');

  @override
  void initState() {
    super.initState();
    if (widget.match == null) return;

    _matchNameController.text = widget.match!.name;
    for (int i = 0; i < widget.match!.playerList.length; i++) {
      _playerNameControllers[i].text = widget.match!.playerList[i]?.name ?? '';
      _imagePaths[i] = widget.match!.playerList[i]?.imagePath ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 256),
        title: TextField(
          controller: _matchNameController,
          decoration: InputDecoration(
            labelText: 'Match Name',
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: const OutlineInputBorder(),
          ),
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
            child: const Text('Done', style: TextStyle(fontSize: fontSizeMedium)),
            onPressed: () {
              if (_matchNameController.text.isEmpty) {
                showToastMessage(context, 'Match name can\'t be empty');
                return;
              }

              for (var e in _playerNameControllers) {
                if (e.value.text.isNotEmpty && _imagePaths[_playerNameControllers.indexOf(e)].isEmpty) {
                  showToastMessage(
                    context,
                    'Please select an image for player ${_playerNameControllers.indexOf(e) + 1}',
                  );
                  return;
                }

                if (e.value.text.isEmpty && _imagePaths[_playerNameControllers.indexOf(e)].isNotEmpty) {
                  showToastMessage(
                    context,
                    'Player ${_playerNameControllers.indexOf(e) + 1} name can\'t be empty',
                  );
                  return;
                }
              }

              final newMatch = KLIMatch(
                _matchNameController.text,
                _playerNameControllers.map((c) {
                  return c.text.isEmpty
                      ? null
                      : KLIPlayer(c.text, _imagePaths[_playerNameControllers.indexOf(c)]);
                }).toList(),
              );

              Navigator.of(context).pop(newMatch);
            },
          ),
          TextButton(
            child: Text('Cancel', style: TextStyle(fontSize: fontSizeMedium, color: Theme.of(context).colorScheme.error)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget playerWidget(int index) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Text('Player ${index + 1}', textAlign: TextAlign.center),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: _playerNameControllers[index],
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border.all(width: 1, color: Colors.black54)),
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300, minHeight: 1, minWidth: 260),
              child: _imagePaths[index].isEmpty
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      child: const Text('No Image'),
                    )
                  : Image.file(
                      File('${storageHandler.parentFolder}\\${_imagePaths[index]}'),
                      fit: BoxFit.contain,
                    ),
            ),
            ElevatedButton(
              child: const Text('Select Image'),
              onPressed: () async {
                logger.i('Selecting image from ${storageHandler.mediaDir}');
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: 'Select image',
                  initialDirectory: storageHandler.mediaDir.replaceAll('/', '\\'),
                );

                if (result != null) {
                  final p = result.files.single.path!;
                  _imagePaths[index] = p.split(storageHandler.parentFolder).last;
                  logger.i('Chose $p for player ${index + 1}');
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
