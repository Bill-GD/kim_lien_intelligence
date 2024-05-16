import 'package:flutter/material.dart';

class KLIIconButton extends StatefulWidget {
  final Widget icon;
  final bool enableCondition;
  final void Function()? onPressed;
  final String enabledLabel;
  final String disabledLabel;

  const KLIIconButton(
    this.icon, {
    this.enableCondition = true,
    this.onPressed,
    this.enabledLabel = '',
    this.disabledLabel = 'Disabled',
    super.key,
  });

  @override
  _KLIIconButtonState createState() => _KLIIconButtonState();
}

class _KLIIconButtonState extends State<KLIIconButton> {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          widget.enableCondition && widget.onPressed != null ? widget.enabledLabel : widget.disabledLabel,
      child: IconButton(
        icon: widget.icon,
        onPressed: widget.enableCondition && widget.onPressed != null ? widget.onPressed : null,
      ),
    );
  }
}
