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
  BaseMatch(this.match);
}

Widget button(
  BuildContext context,
  final String label, {
  double fontSize = fontSizeMedium,
  bool enableCondition = true,
  void Function()? onPressed,
  String enabledLabel = '',
  String disabledLabel = 'Disabled',
}) {
  final mainButton = OutlinedButton(
    style: ButtonStyle(
      backgroundColor: MaterialStatePropertyAll<Color>(Theme.of(context).colorScheme.background),
      padding: const MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(vertical: 20, horizontal: 15)),
    ),
    onPressed: enableCondition && onPressed != null ? onPressed : null,
    child: Text(label, style: TextStyle(fontSize: fontSize)),
  );

  return Tooltip(
    message: enableCondition && onPressed != null ? enabledLabel : disabledLabel,
    child: mainButton,
  );
}

Widget iconButton(
  BuildContext context,
  Widget icon, {
  bool enableCondition = true,
  void Function()? onPressed,
  String enabledLabel = '',
  String disabledLabel = 'Disabled',
}) {
  final mainButton = IconButton(
    icon: icon,
    onPressed: enableCondition && onPressed != null ? onPressed : null,
  );
  return Tooltip(
    message: enableCondition && onPressed != null ? enabledLabel : disabledLabel,
    child: mainButton,
  );
}
