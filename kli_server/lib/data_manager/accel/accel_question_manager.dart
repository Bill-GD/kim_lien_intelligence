import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

import '../../global.dart';

class AccelQuestionManager extends StatefulWidget {
  const AccelQuestionManager({super.key});

  @override
  State<AccelQuestionManager> createState() => _AccelQuestionManagerState();
}

class _AccelQuestionManagerState extends State<AccelQuestionManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(context, 'Acceleration Question Manager'),
      backgroundColor: Colors.transparent,
      body: const Center(),
    );
  }
}
