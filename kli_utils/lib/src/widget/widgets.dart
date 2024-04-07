import 'package:flutter/material.dart';

import '../global.dart';
import '../global_export.dart';

void showToastMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: const TextStyle(fontSize: 24))),
  );
}

void showBackDialog(BuildContext context, String confirmMessage, String logMessage) {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Are you sure?'),
        content: Text(confirmMessage),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              logMessageController.add(MapEntry(LogType.info, logMessage));
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
