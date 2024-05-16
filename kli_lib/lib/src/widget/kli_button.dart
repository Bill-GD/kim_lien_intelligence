import 'package:flutter/material.dart';

import '../global_export.dart';

class KLIButton extends StatefulWidget {
  final String label;
  final void Function()? onPressed;
  final double fontSize;
  final bool enableCondition;
  final String enabledLabel;
  final String disabledLabel;

  const KLIButton(
    this.label, {
    this.onPressed,
    this.fontSize = fontSizeMedium,
    this.enableCondition = true,
    this.enabledLabel = '',
    this.disabledLabel = 'Disabled',
    super.key,
  });

  @override
  _KLIButtonState createState() => _KLIButtonState();
}

class _KLIButtonState extends State<KLIButton> {
  @override
  Widget build(BuildContext context) {
    final mainButton = OutlinedButton(
      style: ButtonStyle(
        shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        backgroundColor: MaterialStatePropertyAll<Color>(Theme.of(context).colorScheme.background),
        padding:
            const MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(vertical: 20, horizontal: 15)),
      ),
      onPressed: widget.enableCondition && widget.onPressed != null ? widget.onPressed : null,
      child: Text(widget.label, style: TextStyle(fontSize: widget.fontSize)),
    );

    return Tooltip(
      message:
          widget.enableCondition && widget.onPressed != null ? widget.enabledLabel : widget.disabledLabel,
      child: mainButton,
    );
  }
}
