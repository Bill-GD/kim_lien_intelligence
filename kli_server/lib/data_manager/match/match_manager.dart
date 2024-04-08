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
  bool _isLoading = true;
  int _currentMatchIndex = -1;
  List<KLIMatch> _matches = [];

  @override
  void initState() {
    logger.i('Match manager init');
    storageHandler!.readFromFile(storageHandler!.matchSaveFile).then((value) {
      if (value.isNotEmpty) {
        _matches = (jsonDecode(value) as List).map((e) => KLIMatch.fromJson(e)).toList();
        _currentMatchIndex = -1;
        setState(() {});
      }
      setState(() => _isLoading = false);
      logger.i('Loaded ${_matches.length} matches');
    });
    super.initState();
  }

  Future<void> overwriteSave() async {
    await storageHandler!.writeToFile(storageHandler!.matchSaveFile, jsonEncode(_matches));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Match Manager'),
      body: _isLoading
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
            () async {
              final newMatch = await Navigator.of(context).push<KLIMatch>(
                DialogRoute<KLIMatch>(
                  context: context,
                  barrierDismissible: false,
                  barrierLabel: '',
                  builder: (_) => MatchEditorDialog(matchNames: _matches.map((e) => e.name)),
                ),
              );

              if (newMatch != null) {
                _matches.add(newMatch);
                await overwriteSave();
                setState(() {});
              }
            },
          ),
          button(
            context,
            'Modify Match${_currentMatchIndex < 0 ? '' : ': ${_matches[_currentMatchIndex].name}'}',
            _currentMatchIndex < 0
                ? null
                : () async {
                    final newMatch = await Navigator.of(context).push<KLIMatch>(
                      DialogRoute<KLIMatch>(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: '',
                        builder: (_) => MatchEditorDialog(
                          match: _matches[_currentMatchIndex],
                          matchNames: _matches.map((e) => e.name),
                        ),
                      ),
                    );

                    if (newMatch != null) {
                      _matches[_currentMatchIndex] = newMatch;
                      await overwriteSave();
                      setState(() {});
                    }
                  },
          ),
          button(
            context,
            'Remove Match',
            _currentMatchIndex < 0
                ? null
                : () async {
                    showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: Text(
                            'Are you sure you want to delete match: ${_matches[_currentMatchIndex].name}?',
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
                      logger.i('Remove match: ${_matches[_currentMatchIndex].name}');
                      _matches.removeAt(_currentMatchIndex);
                      await overwriteSave();
                      setState(() => _currentMatchIndex = -1);
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
              child: _matches.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                      ),
                      alignment: Alignment.center,
                      child: const Text('No match'),
                    )
                  : ListView.separated(
                      itemCount: _matches.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 20),
                      itemBuilder: (_, index) => ListTile(
                        title: Text(_matches[index].name, style: const TextStyle(fontSize: fontSizeMedium)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
                        ),
                        onTap: () {
                          _currentMatchIndex = index;
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
              child: _currentMatchIndex < 0
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                      ),
                      child: const Center(child: Text('No match selected')),
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
        final p = _matches[_currentMatchIndex].playerList;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: p[index] == null
              ? GridTile(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Theme.of(context).colorScheme.onBackground),
                    ),
                    alignment: Alignment.center,
                    child: const Text('No player'),
                  ),
                )
              : GridTile(
                  footer: Text(
                    '${p[index]?.name}',
                    style: const TextStyle(fontSize: fontSizeSmall, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: Image.file(
                      File('${storageHandler!.parentFolder}\\${p[index]?.imagePath}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
        );
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    );
  }
}
