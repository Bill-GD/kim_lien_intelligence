import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import '../match_data.dart';

class Overview extends StatefulWidget {
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgWidget),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Overview', style: TextStyle(fontSize: fontSizeLarge)),
          forceMaterialTransparency: true,
          automaticallyImplyLeading: kDebugMode,
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 4; i++) playerWidget(i),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget playerWidget(int pos) {
    final bool isCurrentPlayer = KLIClient.clientID!.name.contains('player') &&
        int.parse(Networking.getClientDisplayID(KLIClient.clientID!).split(' ').last) == pos;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.onBackground),
              borderRadius: BorderRadius.circular(5),
            ),
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 450, minHeight: 1, minWidth: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.memory(
                Networking.decodeMedia(MatchData().players[pos]['image']),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.onBackground),
              color: isCurrentPlayer
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              MatchData().players[pos]['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: fontSizeMedium),
            ),
          ),
        ],
      ),
    );
  }
}
