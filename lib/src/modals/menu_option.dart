import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Icon alignment for menu options
enum LiquiMenuIconAlignment { left, right }

/// Data class representing a menu item
class LiquiMenuItem {
  final VoidCallback onTap;
  final String title;
  final IconData? icon;
  final String? imageAsset;
  final bool destructive;
  final bool selected;

  const LiquiMenuItem({
    required this.onTap,
    required this.title,
    this.icon,
    this.destructive = false,
    this.selected = false,
    this.imageAsset,
  });
}

/// Group of menu options with interactive highlighting
class LiquiMenuOptionGroup extends StatefulWidget {
  const LiquiMenuOptionGroup({super.key, required this.items});

  final List<LiquiMenuItem> items;

  @override
  State<LiquiMenuOptionGroup> createState() => _LiquiMenuOptionGroupState();
}

class _LiquiMenuOptionGroupState extends State<LiquiMenuOptionGroup> {
  int? highlightedIndex;
  final highlightedRect = ValueNotifier<Rect?>(null);
  List<GlobalKey> keys = [];
  bool _isDragging = false;

  List<LiquiMenuItem> get items => widget.items;

  /// Check if parent ScrollView is scrollable
  bool get _isScrollable {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return false;
    return scrollable.position.maxScrollExtent > 0;
  }

  @override
  void initState() {
    super.initState();
    keys.addAll(List.generate(items.length, (index) => GlobalKey()));
  }

  int? getItemIndexAtPosition(Offset globalPosition) {
    for (int i = 0; i < keys.length; i++) {
      final box = keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final localPosition = box.globalToLocal(globalPosition);
        if (box.paintBounds.contains(localPosition)) {
          return i;
        }
      }
    }
    return null;
  }

  void _updateHighlightedRect(int index) {
    final box = keys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final stackBox = context.findRenderObject() as RenderBox?;
      if (stackBox != null) {
        final boxPositionInStack = stackBox.globalToLocal(box.localToGlobal(Offset.zero));
        highlightedRect.value = boxPositionInStack & box.size;
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final index = getItemIndexAtPosition(event.position);
    if (index != null) {
      HapticFeedback.mediumImpact();
      _isDragging = true;
      highlightedIndex = index;
      _updateHighlightedRect(index);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isDragging) return;
    if (_isScrollable) return;

    final index = getItemIndexAtPosition(event.position);
    if (index != highlightedIndex) {
      highlightedIndex = index;
      if (index != null) _updateHighlightedRect(index);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isDragging) return;

    final index = getItemIndexAtPosition(event.position);
    if (index != null && index == highlightedIndex) {
      items[index].onTap();
      Navigator.of(context).pop();
    }
    deselectHighlighting();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    deselectHighlighting();
  }

  void deselectHighlighting() {
    if (!context.mounted) return;
    _isDragging = false;
    highlightedIndex = null;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    highlightedRect.notifyListeners();
    Future.delayed(Durations.long1).then((_) {
      if (!mounted) return;
      if (!context.mounted) return;
      highlightedRect.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          ValueListenableBuilder(
            valueListenable: highlightedRect,
            builder: (context, value, child) {
              if (value == null) return const SizedBox.shrink();
              return AnimatedPositioned.fromRect(
                rect: value,
                duration: Durations.long1,
                curve: Curves.fastLinearToSlowEaseIn,
                child: AnimatedContainer(
                  duration: Durations.long1,
                  curve: Curves.fastLinearToSlowEaseIn,
                  decoration: ShapeDecoration(
                    color: highlightedIndex != null ? Colors.black.withAlpha(20) : Colors.black.withAlpha(0),
                    shape: RoundedSuperellipseBorder(borderRadius: .circular(20)),
                  ),
                ),
              );
            },
          ),
          Column(
            mainAxisSize: .min,
            children: [
              for (var i = 0; i < items.length; i++)
                Container(
                  key: keys[i],
                  child: LiquiMenuOption(
                    icon: items[i].icon,
                    text: items[i].title,
                    selected: items[i].selected,
                    destructive: items[i].destructive,
                    grouped: true,
                    imageAsset: items[i].imageAsset,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual menu option widget
class LiquiMenuOption extends StatelessWidget {
  const LiquiMenuOption({
    super.key,
    this.icon,
    required this.text,
    this.destructive = false,
    this.selected = false,
    this.grouped = false,
    this.iconAlignment = LiquiMenuIconAlignment.left,
    this.imageAsset,
  });

  final IconData? icon;
  final String text;
  final bool destructive;
  final bool selected;
  final bool grouped;
  final LiquiMenuIconAlignment iconAlignment;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    Widget buildIconWidget() {
      if (icon == null && imageAsset == null) {
        return const SizedBox.shrink();
      }
      return SizedBox(
        width: 28,
        child: Align(
          child: imageAsset != null
              ? Image.asset(
                  imageAsset!,
                  width: 15,
                  height: 18,
                  color: destructive ? CupertinoColors.destructiveRed : null,
                )
              : Icon(icon, size: 15, color: destructive ? CupertinoColors.destructiveRed : CupertinoColors.label),
        ),
      );
    }

    final iconWidget = buildIconWidget();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          if (selected) ...[
            const SizedBox(
              width: 24,
              child: Align(
                child: Icon(
                  CupertinoIcons.check_mark,
                  size: 17,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (iconAlignment == LiquiMenuIconAlignment.left) ...[iconWidget, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.25,
                color: destructive ? CupertinoColors.destructiveRed : Colors.black,
              ),
            ),
          ),
          if (iconAlignment == LiquiMenuIconAlignment.right) ...[const SizedBox(width: 8), iconWidget],
        ],
      ),
    );
  }
}
