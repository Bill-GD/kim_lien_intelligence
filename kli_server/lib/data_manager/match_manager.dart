import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class MatchManager extends StatefulWidget {
  const MatchManager({super.key});

  @override
  State<MatchManager> createState() => _MatchManagerState();
}

class _MatchManagerState extends State<MatchManager> {
  List<KLIMatch> matches = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: const Text('Add Match'),
                  onPressed: () {},
                ),
                TextButton(
                  child: const Text('Modify Match'),
                  onPressed: () {},
                ),
                TextButton(
                  child: const Text('Remove Match'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Flexible(
            child: Row(
              children: [
                buildList(context, 'Match 1', matches),
                buildList(context, 'Match 2', matches),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildList(BuildContext context, String title, List<KLIMatch> list) {
  return Flexible(
    child: Column(
      children: [
        Text(title),
        Flexible(
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer),
            child: ListView.builder(
              itemCount: 15,
              itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
            ),
          ),
        ),
      ],
    ),
  );
}
