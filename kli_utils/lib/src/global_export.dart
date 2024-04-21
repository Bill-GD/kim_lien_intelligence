import 'package:flutter/material.dart';

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

abstract class BaseMatch {
  String match;
  BaseMatch(this.match);
}
