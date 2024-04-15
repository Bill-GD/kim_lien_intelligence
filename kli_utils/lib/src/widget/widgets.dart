import 'package:flutter/material.dart';

import '../global.dart';
import '../global_export.dart';

void showToastMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: const TextStyle(fontSize: 24))),
  );
}

void showBackDialog(BuildContext context, String message, String acceptLogMessage) {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Are you sure?', textAlign: TextAlign.center),
        titleTextStyle: const TextStyle(fontSize: fontSizeMedium),
        content: Text(message, textAlign: TextAlign.center),
        contentTextStyle: const TextStyle(fontSize: fontSizeMedium),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            child: const Text('Yes', style: TextStyle(fontSize: fontSizeMSmall)),
            onPressed: () {
              logMessageController.add((LogType.info, acceptLogMessage));
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('No', style: TextStyle(fontSize: fontSizeMSmall)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

Future<bool?> confirmDeleteDialog(BuildContext context, String message, String acceptLogMessage) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: Icon(Icons.warning_rounded, color: Colors.redAccent.shade200),
        title: const Text('Are you sure?', textAlign: TextAlign.center),
        titleTextStyle: const TextStyle(fontSize: fontSizeMedium),
        content: Text(message, textAlign: TextAlign.center),
        contentTextStyle: const TextStyle(fontSize: fontSizeMSmall),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            child: const Text('Yes', style: TextStyle(fontSize: fontSizeMSmall)),
            onPressed: () {
              logMessageController.add((LogType.info, acceptLogMessage));
              Navigator.pop(context, true);
            },
          ),
          TextButton(
            child: const Text('No', style: TextStyle(fontSize: fontSizeMSmall)),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );
}
