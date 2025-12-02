import 'package:flutter/cupertino.dart';
import 'package:liqui/src/buttons/circle_button.dart';

class LiquiCloseButton extends StatelessWidget {
  const LiquiCloseButton({super.key, this.onPressed, double? size}) : size = size ?? 32;

  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return LiquiCircleButton(icon: CupertinoIcons.xmark, size: size, onPressed: onPressed);
  }
}
