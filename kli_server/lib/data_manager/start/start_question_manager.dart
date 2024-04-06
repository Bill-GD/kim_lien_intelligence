import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

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
        title: const Text('Start Question Manager'),
        surfaceTintColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(fontSize: fontSizeXL),
        centerTitle: true,
        toolbarHeight: kToolbarHeight * 1.1,
      ),
      body: Center(
        child: TextButton(
          child: const Text('Read Excel'),
          onPressed: () async {
            storageHandler.writeToFile(
              'D:/Downloads/output.json',
              jsonEncode(await storageHandler.readFromExcel('D:/Downloads/KĐ trận BK1.xlsx', 3)),
            );
          },
        ),
      ),
    );
  }
}
