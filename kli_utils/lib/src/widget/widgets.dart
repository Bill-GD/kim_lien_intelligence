import 'package:flutter/material.dart';

import '../global.dart';

void showToastMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void showDataManagerDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  required String acceptText,
  required Function onAccept,
  required String cancelText,
  required Function onCancel,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          textAlign: TextAlign.center,
        ),
        content: content,
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            child: Text(acceptText),
            onPressed: () {
              onAccept();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(cancelText),
            onPressed: () {
              onCancel();
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

void showBackDialog(BuildContext context, String confirmMessage, String logMessage) {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Are you sure?'),
        content: Text(
          confirmMessage,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              logger.i(logMessage);
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

Widget textFieldWithLabel(BuildContext context, String labelText) {
  return Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: leadingText(context, labelText),
      ),
      Expanded(
        child: TextField(
          // controller: _songController..text = song.trackName,
          decoration: textFieldDecoration(
            context,
            fillColor: Theme.of(context).colorScheme.background,
            border: InputBorder.none,
            suffixIcon: const Icon(Icons.edit_rounded),
          ),
        ),
      ),
    ],
  );
}

Text leadingText(BuildContext context, String text, [bool bold = true, double size = 14]) => Text(
      text,
      style: TextStyle(
        fontSize: size,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );

InputDecoration textFieldDecoration(
  BuildContext context, {
  Color? fillColor,
  String? hintText,
  String? labelText,
  String? errorText,
  InputBorder? border,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) =>
    InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hintText,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
      labelText: labelText,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minHeight: 2, minWidth: 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      border: border,
    );
