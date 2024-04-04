import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class StartQuestionManager extends StatefulWidget {
  const StartQuestionManager({super.key});

  @override
  State<StartQuestionManager> createState() => _StartQuestionManagerState();
}

class _StartQuestionManagerState extends State<StartQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Start Question Manager'),
        titleTextStyle: const TextStyle(fontSize: 30),
        centerTitle: true,
      ),
      body: Center(
        child: TextButton(
          child: const Text('Read Excel'),
          onPressed: () async {
            StorageHandler.writeToFile(
              'D:/Downloads/output.json',
              jsonEncode(await StorageHandler.readFromExcel('D:/Downloads/KĐ trận BK1.xlsx', 3)),
            );
          },
        ),
      ),
    );
  }
}
