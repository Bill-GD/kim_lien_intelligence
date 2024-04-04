import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kli_server/global.dart';
import 'package:kli_utils/kli_utils.dart';

class MatchManager extends StatefulWidget {
  const MatchManager({super.key});

  @override
  State<MatchManager> createState() => _MatchManagerState();
}

class _MatchManagerState extends State<MatchManager> {
  bool _isLoading = true;
  List<KLIMatch> _matches = [];
  List<KLIPlayer> _players = [];

  @override
  void initState() {
    super.initState();
    StorageHandler.readFromFile('$parentFolder/${StorageHandler.matchSaveFile}').then((value) {
      if (value.isNotEmpty) {
        // final List list = jsonDecode(value);
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
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    child: const Text('Add Match'),
                    onPressed: () {
                      showDataManagerDialog(
                        context,
                        title: 'Add Match',
                        content: matchEditor(context),
                        acceptText: 'Add',
                        onAccept: () {},
                        cancelText: 'Cancel',
                        onCancel: () {},
                      );
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Modify Match'),
                    onPressed: () {},
                  ),
                  ElevatedButton(
                    child: const Text('Remove Match'),
                    onPressed: () {},
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
                        buildList(
                          context,
                          'Match',
                          ListView.builder(
                            itemCount: _matches.length,
                            itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
                          ),
                        ),
                        buildList(
                          context,
                          'Player',
                          ListView.builder(
                            itemCount: _players.length,
                            itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget matchEditor(BuildContext context) {
  return Container(
    child: textFieldWithLabel(
      context,
      'Match Name',
    ),
  );
}

Widget buildList(BuildContext context, String title, ListView listView) {
  return Flexible(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer),
              child: listView,
            ),
          ),
        ],
      ),
    ),
  );
}
