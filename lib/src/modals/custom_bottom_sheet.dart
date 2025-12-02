import 'dart:async';
import 'dart:math';

import 'package:elegant_spring_animation/elegant_spring_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liqui/src/modals/custom_bottom_sheet_wrapper.dart';
import 'package:liqui/src/modals/menu_option.dart';
import 'package:screen_corner_radius/screen_corner_radius.dart';

/// Configuration constants for the custom bottom sheet
class BottomSheetConfig {
  BottomSheetConfig._(); // Private constructor to prevent instantiation

  // Animation Durations
  /// Duration for the entry animation (spring animation)
  static const Duration entryDuration = Duration(milliseconds: 500);

  /// Duration for the exit animation when in popover mode
  static const Duration exitDurationPopover = Duration(milliseconds: 250);

  /// Duration for the exit animation in normal mode
  static const Duration exitDurationNormal = Duration(milliseconds: 400);

  /// Duration for the animated alignment transition
  static const Duration alignmentDuration = Duration(milliseconds: 750);

  /// Delay before the barrier becomes clickable to prevent accidental dismissals
  static const Duration barrierClickableDelay = Duration(milliseconds: 500);

  // Dimensions
  /// Maximum width for the bottom sheet on larger screens
  static const double maxWidth = 450.0;

  /// Minimum screen width to be considered a tablet for layout purposes
  static const double tabletWidthThreshold = 450.0;

  /// Minimum shortest side to be considered a tablet (for keyboard handling)
  static const double tabletShortestSideThreshold = 600.0;

  /// Default padding around popovers
  static const double popoverPadding = 16.0;

  /// Edge padding for the bottom sheet container
  static const double edgePadding = 8.0;

  /// Adjustment value for corner radius calculations
  static const double cornerRadiusAdjustment = 8.0;

  // Spring Physics
  /// Mass parameter for the spring animation (affects inertia)
  static const double springMass = 1.0;

  /// Stiffness parameter for the spring animation (affects speed)
  static const double springStiffness = 380.0;

  /// Damping parameter for the spring animation (affects bounce)
  static const double springDamping = 32.0;

  /// Initial velocity for the spring animation (affects entry feel)
  static const double springInitialVelocity = 2.5;

  // Visual Effects
  /// Default alpha value for the barrier overlay
  static const double barrierAlpha = 0.32;

  /// Center point for blur calculation in popover animations
  static const double blurCenterPoint = 0.5;

  /// Multiplier for blur intensity calculation
  static const double blurMultiplier = 10.0;

  // Mathematical Constants
  /// Alignment range minimum (-1.0 represents left/top alignment)
  static const double alignmentMin = -1.0;

  /// Alignment range maximum (1.0 represents right/bottom alignment)
  static const double alignmentMax = 1.0;

  /// Anchor to alignment conversion factor
  static const double anchorToAlignmentFactor = 2.0;

  /// Progress clamp minimum value
  static const double progressMin = 0.0;

  /// Progress clamp maximum value
  static const double progressMax = 1.0;
}

/// Data class representing the calculated position of a popover
class PopoverPosition {
  final double? top;
  final double? bottom;
  final double left;
  final Alignment alignment;
  final double maxHeight;

  const PopoverPosition({this.top, this.bottom, required this.left, required this.alignment, required this.maxHeight});
}

/// Calculator for popover positioning logic
class PopoverPositionCalculator {
  final Offset sourcePosition;
  final Size sourceSize;
  final double screenWidth;
  final double screenHeight;
  final double popoverWidth;
  final double padding;

  PopoverPositionCalculator({
    required this.sourcePosition,
    required this.sourceSize,
    required this.screenWidth,
    required this.screenHeight,
    required this.popoverWidth,
    this.padding = BottomSheetConfig.popoverPadding,
  });

  /// Calculate the optimal position for the popover
  PopoverPosition calculate() {
    final sourceCenterX = sourcePosition.dx + sourceSize.width / 2;
    final availableTop = sourcePosition.dy - padding;
    final availableBottom = screenHeight - (sourcePosition.dy + sourceSize.height) - padding;

    final showBelow = availableBottom >= availableTop;

    final double? top = showBelow ? sourcePosition.dy + sourceSize.height : null;
    final double? bottom = !showBelow ? screenHeight - sourcePosition.dy : null;
    final double left = _calculateLeft(sourceCenterX);
    final Alignment alignment = _calculateAlignment(sourceCenterX, left, top);

    return PopoverPosition(
      top: top,
      bottom: bottom,
      left: left,
      alignment: alignment,
      maxHeight: showBelow ? availableBottom : availableTop,
    );
  }

  double _calculateLeft(double sourceCenterX) {
    final idealLeft = sourceCenterX - (popoverWidth / 2);
    if (idealLeft < padding) return padding;
    if (idealLeft + popoverWidth > screenWidth - padding) {
      return screenWidth - popoverWidth - padding;
    }
    return idealLeft;
  }

  Alignment _calculateAlignment(double sourceCenterX, double left, double? top) {
    final anchor = (sourceCenterX - left) / popoverWidth;
    final alignX = (anchor * BottomSheetConfig.anchorToAlignmentFactor - BottomSheetConfig.alignmentMax).clamp(
      BottomSheetConfig.alignmentMin,
      BottomSheetConfig.alignmentMax,
    );
    final alignY = top != null ? BottomSheetConfig.alignmentMin : BottomSheetConfig.alignmentMax;
    return Alignment(alignX, alignY);
  }
}

/// Controller to programmatically control the custom bottom sheet
class CustomBottomSheetController {
  final List<VoidCallback> _whenCompleteCallbacks = [];
  bool _isDisposed = false;

  /// Register a callback to be called when the sheet is dismissed
  void whenComplete(VoidCallback callback) {
    if (_isDisposed) return;
    _whenCompleteCallbacks.add(callback);
  }

  void _executeWhenComplete() {
    if (_isDisposed) return;
    for (final callback in _whenCompleteCallbacks) {
      try {
        callback();
      } catch (e) {
        // Log error instead of crashing
        debugPrint('Error in whenComplete callback: $e');
      }
    }
    _whenCompleteCallbacks.clear();
    _isDisposed = true;
  }

  /// Dispose the controller and clear all callbacks
  void dispose() {
    _whenCompleteCallbacks.clear();
    _isDisposed = true;
  }
}

/// Custom ModalRoute for the bottom sheet with full control
class CustomBottomSheetRoute<T> extends ModalRoute<T> {
  final WidgetBuilder builder;
  final Color backgroundColor;
  final Color barrierColorValue;
  final bool enableDrag;
  final double screenCornerRadius;
  final CustomBottomSheetController sheetController;
  final bool enablePopoverEffect;
  BuildContext? sourceContext;
  final double? width;

  CustomBottomSheetRoute({
    required this.builder,
    required this.backgroundColor,
    required this.barrierColorValue,
    required this.enableDrag,
    required this.screenCornerRadius,
    required this.sheetController,
    this.enablePopoverEffect = false,
    this.sourceContext,
    this.width,
  });

  @override
  Duration get transitionDuration => BottomSheetConfig.entryDuration;

  @override
  Duration get reverseTransitionDuration =>
      enablePopoverEffect ? BottomSheetConfig.exitDurationPopover : BottomSheetConfig.exitDurationNormal;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null; // We handle it manually in buildTransitions

  @override
  String? get barrierLabel => 'Dismiss';

  late AnimationController _animationController;
  bool _barrierClickable = false;
  bool _barrierClicked = false;
  Timer? _barrierTimer;
  Offset? _sourcePosition;
  Size? _sourceSize;
  double? _width;
  Alignment _alignment = Alignment.center;
  Size? _lastScreenSize;

  @override
  AnimationController createAnimationController() {
    // Keep the controller unbounded for the spring entry; reverse reads will be
    // clamped via _resolvedProgress to avoid non-finite values.
    return _animationController = AnimationController(
      vsync: navigator!,
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      upperBound: double.infinity, // ← Questo simula "unbounded" solo sopra
    );
  }

  @override
  bool didPop(T? result) {
    _barrierClicked = true;
    return super.didPop(result);
  }

  @override
  TickerFuture didPush() {
    super.didPush(); // ✅ DEVI chiamarlo - notifica solo il framework, non avvia animazioni

    // Capture source position once if popover effect is enabled
    if (enablePopoverEffect && sourceContext != null) {
      final RenderBox? renderBox = sourceContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        _sourcePosition = renderBox.localToGlobal(Offset.zero);
        _sourceSize = renderBox.size;
      }
      // Clear reference after capture to prevent memory leak
      sourceContext = null;
    }

    _width = width;

    // Enable barrier click after delay to prevent accidental dismissals
    _barrierTimer = Timer(BottomSheetConfig.barrierClickableDelay, () {
      _barrierClickable = true;
    });

    // iOS-style spring animation: snappier with less bounce
    const spring = SpringDescription(
      mass: BottomSheetConfig.springMass,
      stiffness: BottomSheetConfig.springStiffness,
      damping: BottomSheetConfig.springDamping,
    );
    // Add initial velocity for more natural entry
    final simulation = SpringSimulation(
      spring,
      BottomSheetConfig.progressMin,
      BottomSheetConfig.progressMax,
      BottomSheetConfig.springInitialVelocity,
    );
    return _animationController.animateWith(simulation);
  }

  @override
  void dispose() {
    _barrierTimer?.cancel();
    sheetController._executeWhenComplete();
    super.dispose();
  }

  double _resolvedProgress() {
    final value = _animationController.value;
    // myPrint('Value: $value, Status: ${_animationController.status}');
    if (!value.isFinite) {
      return BottomSheetConfig.progressMin;
    }

    final status = _animationController.status;
    if (status == AnimationStatus.reverse || status == AnimationStatus.dismissed) {
      final clamped = value.clamp(BottomSheetConfig.progressMin, BottomSheetConfig.progressMax);
      return Curves.easeOut.transform(clamped);
    }

    return value;
  }

  PopoverPosition? _popoverPosition;

  void _calculatePopoverPosition(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Use cached source position and size
    if (_sourcePosition == null || _sourceSize == null) return;

    _width = min(screenSize.width, width ?? BottomSheetConfig.maxWidth);
    final popoverWidth = _width ?? BottomSheetConfig.maxWidth;

    // Calculate popover position using the dedicated calculator
    final calculator = PopoverPositionCalculator(
      sourcePosition: _sourcePosition!,
      sourceSize: _sourceSize!,
      screenWidth: screenSize.width,
      screenHeight: screenSize.height,
      popoverWidth: popoverWidth,
    );

    _popoverPosition = calculator.calculate();
    _alignment = _popoverPosition!.alignment;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (enablePopoverEffect && _sourcePosition != null && _sourceSize != null) {
      // For popover: calculate position and alignment from source button
      _calculatePopoverPosition(context);
    } else {
      // For normal bottom sheet: use tablet/mobile logic
      final isTablet = screenWidth > BottomSheetConfig.tabletWidthThreshold;
      _alignment = isTablet ? Alignment.center : Alignment.bottomCenter;
      if (!isTablet) _width = screenWidth;
    }

    final content = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Padding(
        padding: const EdgeInsets.only(
          left: BottomSheetConfig.edgePadding,
          right: BottomSheetConfig.edgePadding,
          bottom: BottomSheetConfig.edgePadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _width ?? BottomSheetConfig.maxWidth),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final value = animation.value;
              final status = animation.status;

              // Applica easeOut solo in reverse
              final progress = (status == AnimationStatus.reverse || status == AnimationStatus.dismissed)
                  ? Curves.fastOutSlowIn.transform(
                      value.clamp(BottomSheetConfig.progressMin, BottomSheetConfig.progressMax),
                    )
                  : value; // Forward: valore grezzo (può essere > 1.0)

              // Popover effect: scale ancorato in alto a destra
              if (enablePopoverEffect && _sourcePosition != null && _sourceSize != null) {
                return Transform.scale(scale: progress, alignment: _alignment, child: child);
              }

              // Default bottom sheet animation - translate to bottom of screen
              final screenHeight = MediaQuery.of(context).size.height;
              final translateY = (BottomSheetConfig.progressMax - progress) * screenHeight;

              return Transform.translate(
                offset: Offset(0, translateY),
                child: RepaintBoundary(child: child),
              );
            },
            child: Builder(
              builder: (context) {
                final mediaQuery = MediaQuery.of(context);
                final viewInsets = mediaQuery.viewInsets;
                final viewPadding = mediaQuery.viewPadding;

                // Su tablet/iPad il contenuto è centrato, quindi non serve
                // aggiungere padding per la tastiera
                final isTablet = mediaQuery.size.shortestSide >= BottomSheetConfig.tabletShortestSideThreshold;

                final bottomPadding = !enablePopoverEffect
                    ? (isTablet
                          ? viewPadding.bottom
                          : (viewInsets.bottom > 0 ? max(viewPadding.bottom, viewInsets.bottom) : viewPadding.bottom))
                    : 0;
                return CustomBottomSheetWrapper(
                  enableDrag: enableDrag,
                  enablePopoverEffect: enablePopoverEffect,
                  screenCornerRadius: screenCornerRadius,
                  backgroundColor: backgroundColor,
                  routeAnimation: animation,
                  onDismiss: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Material(
                    color: backgroundColor,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomPadding.toDouble()),
                      child: RepaintBoundary(child: builder(context)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // If popover, don't use AnimatedAlign (Positioned will be used in buildTransitions)
    if (enablePopoverEffect && _popoverPosition != null) {
      return content;
    }

    // Default: use AnimatedAlign
    return AnimatedAlign(
      alignment: _alignment,
      duration: BottomSheetConfig.alignmentDuration,
      curve: ElegantSpring.gentleBounce,
      child: content,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Recalculate popover position if screen size changes
    if (enablePopoverEffect && _sourcePosition != null && _sourceSize != null) {
      final currentScreenSize = MediaQuery.of(context).size;

      // Recalculate only if screen size changed
      if (_lastScreenSize == null || _lastScreenSize != currentScreenSize) {
        _lastScreenSize = currentScreenSize;
        _calculatePopoverPosition(context);
      }
    }

    // Wrap child with Positioned if popover effect is enabled (using calculated values)
    Widget content = child;
    if (enablePopoverEffect && _popoverPosition != null) {
      content = Positioned(
        top: _popoverPosition!.top,
        left: _popoverPosition!.left,
        bottom: _popoverPosition!.bottom,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: _popoverPosition!.maxHeight),
          child: RepaintBoundary(child: child),
        ),
      );
    }

    // Barrier fade: use animation controller value (0.0 -> 1.0)
    return Stack(
      fit: StackFit.expand,
      children: [
        // Barrier with tap to dismiss (disabled during initial delay and after first click)
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final progress = _resolvedProgress().clamp(BottomSheetConfig.progressMin, BottomSheetConfig.progressMax);
            return GestureDetector(
              onTap: (barrierDismissible && _barrierClickable && !_barrierClicked)
                  ? () {
                      _barrierClicked = true;
                      Navigator.of(context).maybePop();
                    }
                  : null,
              child: ColoredBox(color: barrierColorValue.withValues(alpha: barrierColorValue.a * progress)),
            );
          },
        ),
        content,
      ],
    );
  }
}

/// Show a Liqui modal (bottom sheet, dialog, or popover)
///
/// This is the base function that handles all modal types.
/// Use [showLiquiSheet] or [showLiquiPopover] for specific implementations.
///
/// Returns a [CustomBottomSheetController] that can be used to register
/// callbacks for when the modal is dismissed.
///
/// Example:
/// ```dart
/// showLiquiModal(
///   context: context,
///   child: MyContent(),
/// ).whenComplete(() {
///   print('Modal dismissed');
/// });
/// ```
CustomBottomSheetController showLiquiModal({
  required BuildContext context,
  required Widget child,
  Color? backgroundColor,
  Color? barrierColor,
  bool enableDrag = true,
  bool useRootNavigator = false,
  bool enablePopoverEffect = false,
  double? width,
  double? borderRadius,
  BuildContext? sourceContext,
}) {
  final controller = CustomBottomSheetController();

  // Get screen corner radius asynchronously
  ScreenCornerRadius.get().then((corner) {
    if (!context.mounted) return;

    final route = CustomBottomSheetRoute(
      builder: (context) => child,
      backgroundColor: backgroundColor ?? Colors.white,
      barrierColorValue: barrierColor ?? Colors.black.withValues(alpha: BottomSheetConfig.barrierAlpha),
      enableDrag: enableDrag,
      screenCornerRadius:
          borderRadius ??
          (corner != null
              ? corner.bottomLeft - BottomSheetConfig.cornerRadiusAdjustment
              : BottomSheetConfig.progressMin),
      sheetController: controller,
      enablePopoverEffect: enablePopoverEffect,
      sourceContext: sourceContext,
      width: width,
    );

    Navigator.of(context, rootNavigator: useRootNavigator).push(route);
  });

  return controller;
}

/// Show a Liqui popover anchored to a source widget
///
/// A popover is a small modal that appears near a button or widget,
/// with an arrow pointing to the source. It automatically positions
/// itself above or below the source based on available space.
///
/// Returns a [CustomBottomSheetController] that can be used to register
/// callbacks for when the popover is dismissed.
///
/// Example:
/// ```dart
/// showLiquiPopover(
///   context: context,
///   sourceContext: buttonContext,
///   child: PopoverContent(),
/// ).whenComplete(() {
///   print('Popover dismissed');
/// });
/// ```
CustomBottomSheetController showLiquiPopover({
  required BuildContext context,
  required BuildContext sourceContext,
  required Widget child,
  Color? backgroundColor,
  Color? barrierColor,
  double? width,
  double? borderRadius,
  bool useRootNavigator = false,
}) {
  return showLiquiModal(
    context: context,
    child: child,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    enableDrag: false,
    useRootNavigator: useRootNavigator,
    enablePopoverEffect: true,
    sourceContext: sourceContext,
    width: width,
    borderRadius: borderRadius,
  );
}

/// Show a Liqui bottom sheet
///
/// A bottom sheet slides up from the bottom of the screen on mobile devices,
/// or appears as a centered dialog on tablets. It can be dragged to dismiss.
///
/// Returns a [CustomBottomSheetController] that can be used to register
/// callbacks for when the sheet is dismissed.
///
/// Example:
/// ```dart
/// showLiquiSheet(
///   context: context,
///   child: SheetContent(),
/// ).whenComplete(() {
///   print('Sheet dismissed');
/// });
/// ```
CustomBottomSheetController showLiquiSheet({
  required BuildContext context,
  required Widget child,
  Color? backgroundColor,
  Color? barrierColor,
  bool enableDrag = true,
  double? width,
  double? borderRadius,
  bool useRootNavigator = false,
}) {
  return showLiquiModal(
    context: context,
    child: child,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    width: width,
    borderRadius: borderRadius,
  );
}

/// Show a Liqui menu popover with a list of menu items
///
/// A menu is a popover that displays a list of selectable options.
/// It appears near the source widget and automatically positions itself.
///
/// Returns a [CustomBottomSheetController] that can be used to register
/// callbacks for when the menu is dismissed.
///
/// Example:
/// ```dart
/// showLiquiMenu(
///   context: context,
///   sourceContext: buttonContext,
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
/// );
/// ```
CustomBottomSheetController showLiquiMenu({
  required BuildContext context,
  required BuildContext sourceContext,
  required List<LiquiMenuItem> items,
  Color? backgroundColor,
  Color? barrierColor,
  double? width,
  bool useRootNavigator = false,
}) {
  return showLiquiPopover(
    context: context,
    sourceContext: sourceContext,
    backgroundColor: backgroundColor ?? Colors.white.withAlpha(200),
    barrierColor: barrierColor,
    width: width ?? 238,
    borderRadius: 20,
    useRootNavigator: useRootNavigator,
    child: SizedBox(
      width: double.maxFinite,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: LiquiMenuOptionGroup(items: items),
      ),
    ),
  );
}
