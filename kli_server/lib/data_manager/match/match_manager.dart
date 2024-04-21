import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';
import 'match_editor.dart';

class MatchManager extends StatefulWidget {
  const MatchManager({super.key});

  @override
  State<MatchManager> createState() => _MatchManagerState();
}

class _MatchManagerState extends State<MatchManager> {
  bool isLoading = true;
  int currentMatchIndex = -1;
  List<KLIMatch> matches = [];

  @override
  void initState() {
    logger.i('Match manager init');
    storageHandler!.readFromFile(storageHandler!.matchSaveFile).then((value) {
      if (value.isNotEmpty) {
        matches = (jsonDecode(value) as List).map((e) => KLIMatch.fromJson(e)).toList();
        currentMatchIndex = -1;
        setState(() {});
      }
      setState(() => isLoading = false);
      logger.i('Loaded ${matches.length} matches');
    });
    super.initState();
  }

  Future<void> overwriteSave() async {
    await storageHandler!.writeToFile(storageHandler!.matchSaveFile, jsonEncode(matches));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Match Manager'),
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  managementButtons(),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        matchList(),
                        playerShowcase(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget managementButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          button(
            context,
            'Add Match',
            onPressed: () async {
              final newMatch = await Navigator.of(context).push<KLIMatch>(
                DialogRoute<KLIMatch>(
                  context: context,
                  barrierDismissible: false,
                  barrierLabel: '',
                  builder: (_) => MatchEditorDialog(matchNames: matches.map((e) => e.name)),
                ),
              );

              if (newMatch != null) {
                matches.add(newMatch);
                await overwriteSave();
                // logPanelController!.addText('Added match: ${newMatch.name}');
                if (mounted) showToastMessage(context, 'Added match: ${newMatch.name}');
                setState(() {});
              }
            },
          ),
          button(
            context,
            'Modify Match${currentMatchIndex < 0 ? '' : ': ${matches[currentMatchIndex].name}'}',
            enableCondition: currentMatchIndex >= 0,
            onPressed: () async {
              final newMatch = await Navigator.of(context).push<KLIMatch>(
                DialogRoute<KLIMatch>(
                  context: context,
                  barrierDismissible: false,
                  barrierLabel: '',
                  builder: (_) => MatchEditorDialog(
                    match: matches[currentMatchIndex],
                    matchNames: matches.map((e) => e.name),
                  ),
                ),
              );

              if (newMatch != null) {
                matches[currentMatchIndex] = newMatch;
                await overwriteSave();
                setState(() {});
              }
            },
          ),
          button(
            context,
            'Remove Match${currentMatchIndex < 0 ? '' : ': ${matches[currentMatchIndex].name}'}',
            enableCondition: currentMatchIndex >= 0,
            onPressed: () async {
              showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: Text(
                      'Are you sure you want to delete match: ${matches[currentMatchIndex].name}?',
                    ),
                    actionsAlignment: MainAxisAlignment.spaceEvenly,
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Yes', style: TextStyle(fontSize: fontSizeMedium)),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                      TextButton(
                        child: const Text('No', style: TextStyle(fontSize: fontSizeMedium)),
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                      ),
                    ],
                  );
                },
              ).then((value) async {
                if (value != true) return;
                logger.i('Removed match: ${matches[currentMatchIndex].name}');
                if (mounted) showToastMessage(context, 'Removed match: ${matches[currentMatchIndex].name}');
                // logPanelController!.addText('Removed match: ${matches[currentMatchIndex].name}');
                matches.removeAt(currentMatchIndex);
                await overwriteSave();
                setState(() => currentMatchIndex = -1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget matchList() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text('Matches', style: Theme.of(context).textTheme.titleLarge),
            ),
            Flexible(
              child: matches.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                        color: Theme.of(context).colorScheme.background,
                      ),
                      alignment: Alignment.center,
                      child: const Text('No match'),
                    )
                  : ListView.separated(
                      itemCount: matches.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 20),
                      itemBuilder: (_, index) => ListTile(
                        title: Text(matches[index].name, style: const TextStyle(fontSize: fontSizeMedium)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
                        ),
                        onTap: () {
                          currentMatchIndex = index;
                          setState(() {});
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget playerShowcase() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text('Players', style: Theme.of(context).textTheme.titleLarge),
            ),
            Flexible(
              child: currentMatchIndex < 0
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                      ),
                      child: const Material(child: Center(child: Text('No match selected'))),
                    )
                  : playerGrid(),
            ),
          ],
        ),
      ),
    );
  }

  GridView playerGrid() {
    return GridView.builder(
      itemCount: 4,
      padding: const EdgeInsets.symmetric(vertical: 40),
      itemBuilder: (_, index) {
        final p = matches[currentMatchIndex].playerList;

        String fullImagePath = '${storageHandler!.parentFolder}\\${p[index]?.imagePath}';

        bool hasPlayer = p[index] != null, imageFound = false;
        if (hasPlayer) {
          imageFound = File(fullImagePath).existsSync();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: GridTile(
            footer: hasPlayer
                ? Text(
                    '${p[index]?.name}',
                    style: const TextStyle(fontSize: fontSizeSmall, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  )
                : null,
            child: !hasPlayer || !imageFound
                ? Container(
                    margin: const EdgeInsets.only(bottom: 35),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                      color: Theme.of(context).colorScheme.background,
                    ),
                    alignment: Alignment.center,
                    child: Text(!hasPlayer ? 'No player' : 'Image at $fullImagePath not found'),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: Image.file(File(fullImagePath), fit: BoxFit.cover),
                  ),
          ),
        );
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    );
  }
}
