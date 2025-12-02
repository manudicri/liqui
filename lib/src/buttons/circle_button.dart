import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liqui/liqui.dart';

class LiquiCircleButtonGroup extends StatelessWidget {
  const LiquiCircleButtonGroup({super.key, required this.buttons, this.backgroundColor});

  final Color? backgroundColor;
  final List<LiquiCircleButton> buttons;

  @override
  Widget build(BuildContext context) {
    const buttonSize = 32 * 1.375;
    return LiquiScaleTap(
      onPressed: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const .all(.circular(99)),
          color: backgroundColor ?? CupertinoColors.label.withAlpha(8),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            for (final button in buttons)
              SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: CupertinoButton(
                  onPressed: button.onPressed,
                  padding: EdgeInsets.zero,
                  child: Icon(button.icon, color: button.dark ? Colors.white : Colors.black, size: buttonSize * 0.55),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LiquiCircleButton extends StatelessWidget {
  const LiquiCircleButton({
    super.key,
    this.onPressed,
    double? size,
    required this.icon,
    this.dark = false,
    this.backgroundColor,
  }) : size = size ?? 32;

  final Color? backgroundColor;

  final VoidCallback? onPressed;
  final double size;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    assert(size > 0);

    final buttonSize = size * 1.375;
    return LiquiScaleTap(
      onPressed: onPressed,
      autoScaleBySize: false,
      scaleOnPress: 1.4,
      child: Container(
        decoration: const ShapeDecoration(
          shape: CircleBorder(),
          shadows: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 12, offset: Offset(0, 4))],
        ),

        child: CircleAvatar(
          radius: buttonSize / 2 + 0.5,
          backgroundColor: CupertinoColors.transparent,
          child: CircleAvatar(
            backgroundColor: backgroundColor ?? CupertinoColors.label.withAlpha(8),
            radius: buttonSize / 2,
            child: CupertinoButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              child: Icon(icon, color: dark ? Colors.white : Colors.black, size: buttonSize * 0.55),
            ),
          ),
        ),
      ),
    );
  }
}
