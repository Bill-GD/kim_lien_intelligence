import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

class BackgroundManager extends StatefulWidget {
  final Function parentSetState;
  const BackgroundManager({super.key, required this.parentSetState});

  @override
  State<BackgroundManager> createState() => _BackgroundManagerState();
}

class _BackgroundManagerState extends State<BackgroundManager> {
  bool hasLocalShared = false;
  String? chosenFilePath;

  @override
  void initState() {
    hasLocalShared =
        File('${Platform.resolvedExecutable.split(Platform.executable).first}\\$backgroundLocalPath')
            .existsSync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                imageContainer(path: 'assets/images/ttkl_bg_new.png', title: 'Default', package: 'kli_lib'),
                imageContainer(path: chosenFilePath, title: 'New'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  constraints: const BoxConstraints(minWidth: 750),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey.shade600),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    chosenFilePath ?? 'No file chosen',
                    style: const TextStyle(fontSize: fontSizeMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                KLIButton(
                  'Reset to Default',
                  enableCondition: !useDefaultBackground,
                  disabledLabel: 'Already using default background',
                  onPressed: () async {
                    useDefaultBackground = true;
                    bgWidget = await getBackgroundWidget(useDefaultBackground);
                    widget.parentSetState(() {});
                  },
                ),
                KLIButton(
                  'Use Shared Background',
                  enableCondition: useDefaultBackground && hasLocalShared,
                  onPressed: () async {
                    useDefaultBackground = false;
                    bgWidget = await getBackgroundWidget(useDefaultBackground);
                    widget.parentSetState(() {});
                  },
                ),
                KLIButton('Select Image', onPressed: () {
                  FilePicker.platform.pickFiles().then((value) {
                    if (value == null) return;
                    chosenFilePath = value.files.single.path;
                    setState(() {});
                  });
                }),
                KLIButton(
                  'Save Image',
                  enableCondition: chosenFilePath != null,
                  enabledLabel: 'Save to shared storage',
                  disabledLabel: 'No file chosen',
                  onPressed: () async {
                    final bytes = await File(chosenFilePath!).readAsBytes();
                    File('${Platform.resolvedExecutable.split(Platform.executable).first}\\$backgroundLocalPath')
                        .writeAsBytesSync(bytes);
                    useDefaultBackground = false;
                    setState(() => hasLocalShared = true);
                    widget.parentSetState(() {});
                    await githubHandler.uploadFile(
                      backgroundGitHubPath,
                      bytes: bytes,
                      message: 'Update background image',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget imageContainer({required String? path, required String title, String? package}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: fontSizeMedium)),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
            color: Theme.of(context).colorScheme.background,
          ),
          constraints: const BoxConstraints(maxHeight: 360, maxWidth: 640),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: path == null
                ? Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'No image selected',
                      style: TextStyle(fontSize: fontSizeMedium),
                    ),
                  )
                : package != null
                    ? Image.asset(
                        path,
                        package: package,
                        fit: BoxFit.fill,
                      )
                    : Image.file(File(path), fit: BoxFit.fill),
          ),
        ),
      ],
    );
  }
}
