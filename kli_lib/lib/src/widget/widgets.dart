import 'dart:async';

import 'package:flutter/material.dart';

import '../global.dart';
import '../global_export.dart';

void showToastMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: const TextStyle(fontSize: 24))),
  );
}

Future<bool?> confirmDialog(
  BuildContext context, {
  required String message,
  required String acceptLogMessage,
  required Future<void> Function() onAccept,
  Future<void> Function()? onCancel,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: Icon(Icons.warning_rounded, color: Colors.redAccent.shade200),
        title: const Text('Xác nhận', textAlign: TextAlign.center),
        titleTextStyle: const TextStyle(fontSize: fontSizeMedium),
        content: Text(message, textAlign: TextAlign.center),
        contentTextStyle: const TextStyle(fontSize: fontSizeMSmall),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            child: const Text('Có', style: TextStyle(fontSize: fontSizeMSmall)),
            onPressed: () async {
              logMessageController.add((LogType.info, acceptLogMessage));
              await onAccept();
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
          TextButton(
            child: const Text('Không', style: TextStyle(fontSize: fontSizeMSmall)),
            onPressed: () async {
              if (onCancel != null) await onCancel();
              if (context.mounted) Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );
}
