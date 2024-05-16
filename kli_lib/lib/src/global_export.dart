import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'global.dart';

enum LogType { info, warn, error }

final logMessageStream = logMessageController.stream;

extension NumDurationExtensions on num {
  Duration get microseconds => Duration(microseconds: round());
  Duration get ms => (this * 1000).microseconds;
  Duration get milliseconds => (this * 1000).microseconds;
  Duration get seconds => (this * 1000 * 1000).microseconds;
  Duration get minutes => (this * 1000 * 1000 * 60).microseconds;
  Duration get hours => (this * 1000 * 1000 * 60 * 60).microseconds;
  Duration get days => (this * 1000 * 1000 * 60 * 60 * 24).microseconds;
}

class AlwaysLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

extension AddText on TextEditingController {
  void addText(String text) {
    value = value.copyWith(
      text: '${value.text}${value.text.isEmpty ? '' : '\n'}$text',
      selection: TextSelection.collapsed(offset: value.text.length),
    );
  }
}

const double fontSizeXL = 48;
const double fontSizeLarge = 32;
const double fontSizeMedium = 24;
const double fontSizeMSmall = 20;
const double fontSizeSmall = 16;
const double fontSizeXS = 12;

abstract class BaseMatch {
  String match;
  BaseMatch({required this.match});
}

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
