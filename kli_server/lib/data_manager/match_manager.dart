import 'package:flutter/material.dart';

class MatchManager extends StatefulWidget {
  const MatchManager({super.key});

  @override
  State<MatchManager> createState() => _MatchManagerState();
}

class _MatchManagerState extends State<MatchManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('Match Manager'),
      ),
    );
  }
}