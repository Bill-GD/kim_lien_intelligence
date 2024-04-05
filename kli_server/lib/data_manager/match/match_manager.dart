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
    super.initState();
    storageHandler.readFromFile(storageHandler.matchSaveFile).then((value) {
      if (value.isNotEmpty) {
        _matches = (jsonDecode(value) as List).map((e) => KLIMatch.fromJson(e)).toList();
        _currentMatchIndex = -1;
        setState(() {});
      }
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        title: const Text('Match Manager'),
        titleTextStyle: const TextStyle(fontSize: 30),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: const ButtonStyle(
                      padding: MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.all(20.0)),
                    ),
                    onPressed: () async {
                      final newMatch = await Navigator.of(context).push<KLIMatch>(
                        DialogRoute<KLIMatch>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => const MatchEditorDialog(),
                        ),
                      );

                      if (newMatch != null) {
                        _matches.add(newMatch);
                        setState(() {});
                      }
                    },
                    child: const Text('Add Match', style: TextStyle(fontSize: 24)),
                  ),
                  ElevatedButton(
                    style: const ButtonStyle(
                      padding: MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.all(20.0)),
                    ),
                    onPressed: () async {
                      if (_currentMatchIndex < 0) {
                        showToastMessage(context, 'Please select a match');
                        return;
                      }
                      final newMatch = await Navigator.of(context).push<KLIMatch>(
                        DialogRoute<KLIMatch>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => MatchEditorDialog(match: _matches[_currentMatchIndex]),
                        ),
                      );

                      if (newMatch != null) {
                        _matches[_currentMatchIndex] = newMatch;
                        setState(() {});
                      }
                    },
                    child: Text(
                      'Modify Match${_currentMatchIndex < 0 ? '' : ': ${_matches[_currentMatchIndex].name}'}',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  ElevatedButton(
                    style: const ButtonStyle(
                      padding: MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.all(20.0)),
                    ),
                    onPressed: () {
                      if (_currentMatchIndex < 0) {
                        showToastMessage(context, 'Please select a match');
                        return;
                      }
                      _matches.removeAt(_currentMatchIndex);
                      setState(() {});
                    },
                    child: const Text('Remove Match', style: TextStyle(fontSize: 24)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
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

  Widget playerShowcase() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text('Players', style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1),
                ),
                child: _currentMatchIndex < 0 ? const Center(child: Text('No match selected')) : playerGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  GridView playerGrid() {
    return GridView.builder(
      itemCount: 4,
      itemBuilder: (_, index) {
        List<KLIPlayer?> p = _matches[_currentMatchIndex].playerList;
        return p[index] == null
            ? const GridTile(
                child: Center(
                  child: Text('No player'),
                ),
              )
            : GridTile(
                footer: Center(child: Text('${index + 1}: ${p[index]?.name}')),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 0),
                  child: Image.file(
                    fit: BoxFit.cover,
                    File(
                      '${storageHandler.parentFolder}\\${p[index]?.imagePath}',
                    ),
                  ),
                ),
              );
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    );
  }

  Widget matchList() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text('Matches', style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1),
                ),
                child: ListView.builder(
                  itemCount: _matches.length,
                  itemBuilder: (_, index) => ListTile(
                    title: Text(_matches[index].name),
                    onTap: () {
                      _currentMatchIndex = index;
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
