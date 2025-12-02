import 'package:flutter/material.dart';

import 'package:liqui/src/modals/custom_bottom_sheet.dart';
import 'package:liqui/src/modals/menu_option.dart';

/// A button that opens a Liqui menu when pressed
///
/// This widget provides a builder that receives a context and a showMenu
/// callback, allowing full control over how the menu is triggered.
///
/// Example:
/// ```dart
/// LiquiMenuButton(
///   items: [
///     LiquiMenuItem(
///       title: 'Edit',
///       icon: Icons.edit,
///       onTap: () => print('Edit tapped'),
///     ),
///     LiquiMenuItem(
///       title: 'Delete',
///       icon: Icons.delete,
///       destructive: true,
///       onTap: () => print('Delete tapped'),
///     ),
///   ],
///   builder: (context, showMenu) => GestureDetector(
///     onTap: showMenu,
///     child: Icon(Icons.more_horiz),
///   ),
/// )
/// ```
class LiquiMenuButton extends StatefulWidget {
  const LiquiMenuButton({
    super.key,
    required this.items,
    required this.builder,
    this.backgroundColor,
    this.barrierColor,
    this.width,
    this.useRootNavigator = false,
    this.onMenuOpened,
    this.onMenuClosed,
  });

  /// The list of menu items to display
  final List<LiquiMenuItem> items;

  /// Builder that provides context and showMenu callback
  final Widget Function(BuildContext context, VoidCallback showMenu) builder;

  /// Background color of the menu (defaults to white with 200 alpha)
  final Color? backgroundColor;

  /// Barrier color behind the menu
  final Color? barrierColor;

  /// Width of the menu (defaults to 238)
  final double? width;

  /// Whether to use root navigator
  final bool useRootNavigator;

  /// Callback when menu is opened
  final VoidCallback? onMenuOpened;

  /// Callback when menu is closed
  final VoidCallback? onMenuClosed;

  @override
  State<LiquiMenuButton> createState() => _LiquiMenuButtonState();
}

class _LiquiMenuButtonState extends State<LiquiMenuButton> {
  CustomBottomSheetController? _menuController;

  void _showMenu(BuildContext buttonContext) {
    widget.onMenuOpened?.call();

    _menuController = showLiquiMenu(
      context: context,
      sourceContext: buttonContext,
      items: widget.items,
      backgroundColor: widget.backgroundColor,
      barrierColor: widget.barrierColor ?? Colors.transparent,
      width: widget.width,
      useRootNavigator: widget.useRootNavigator,
    );

    _menuController?.whenComplete(() {
      widget.onMenuClosed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        return widget.builder(buttonContext, () => _showMenu(buttonContext));
      },
    );
  }

  @override
  void dispose() {
    _menuController?.dispose();
    super.dispose();
  }
}
