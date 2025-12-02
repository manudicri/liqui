import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A widget that scales its child with elastic spring animations on tap.
///
/// When pressed, the child scales up with a quick spring effect.
/// When released, it scales back down with a slower spring effect and triggers [onPressed].
class LiquiScaleTap extends StatefulWidget {
  /// The widget to display and scale on tap
  final Widget child;

  /// Callback triggered when the tap is released
  final VoidCallback? onPressed;

  /// Callback triggered when the tap is held for a long duration
  final VoidCallback? onLongPress;

  /// Scale factor when pressed (default: 1.1)
  /// Ignored if [autoScaleBySize] is true
  final double scaleOnPress;

  /// Duration to wait before triggering long press (default: 500ms)
  final Duration longPressDuration;

  /// If true, automatically calculates scale based on widget size
  /// to maintain consistent pixel increase regardless of size
  final bool autoScaleBySize;

  /// Base pixel increase when [autoScaleBySize] is true (default: 10.0)
  /// For example, a 50x50 widget will scale to ~60x60, a 200x200 to ~210x210
  final double basePixelIncrease;

  /// Damping value for the stretch spring animation (default: 10.0)
  /// Lower values = more bounce, higher values = less bounce
  /// Range: 5.0 (very bouncy) to 30.0 (minimal bounce)
  final double stretchSpringDamping;

  /// Sensitivity multiplier for the stretch effect (default: 1.0)
  /// Higher values = more responsive to drag (more stretch)
  /// Lower values = less sensitive to drag (less stretch)
  /// Range: 0.5 (less sensitive) to 2.0 (more sensitive)
  final double stretchSensitivity;

  /// Sensitivity multiplier for the translate effect (default: 1.0)
  /// Higher values = element moves more when dragged
  /// Lower values = element moves less when dragged
  /// Range: 0.0 (no movement) to 2.0 (double movement)
  final double translateSensitivity;

  final bool enableBrightness;

  const LiquiScaleTap({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.scaleOnPress = 1.1,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.autoScaleBySize = true,
    this.basePixelIncrease = 10.0,
    this.stretchSpringDamping = 10.0,
    this.stretchSensitivity = 1.0,
    this.translateSensitivity = 1.0,
    this.enableBrightness = false,
  });

  @override
  State<LiquiScaleTap> createState() => _LiquiScaleTapState();
}

class _LiquiScaleTapState extends State<LiquiScaleTap> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _stretchXController;
  late AnimationController _stretchYController;
  late AnimationController _offsetXController;
  late AnimationController _offsetYController;
  double _scale = 1.0;
  double _targetScale = 1.0;
  double _stretchX = 1.0;
  double _stretchY = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  bool _isPointerInside = false;
  Offset? _initialPosition;
  Offset? _cursorPosition;
  Timer? _longPressTimer;
  bool _longPressTriggered = false;
  bool _isDisposed = false; // ✅ AGGIUNGI QUESTA FLAG

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!_isDisposed && mounted && _controller.value.isFinite) {
          // ✅ Check _isDisposed
          setState(() {
            _scale = _controller.value;
          });
        }
      });

    _stretchXController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!_isDisposed && mounted && _stretchXController.value.isFinite) {
          setState(() {
            _stretchX = _stretchXController.value;
          });
        }
      });

    _stretchYController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!_isDisposed && mounted && _stretchYController.value.isFinite) {
          setState(() {
            _stretchY = _stretchYController.value;
          });
        }
      });

    _offsetXController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!_isDisposed && mounted && _offsetXController.value.isFinite) {
          setState(() {
            _offsetX = _offsetXController.value;
          });
        }
      });

    _offsetYController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!_isDisposed && mounted && _offsetYController.value.isFinite) {
          setState(() {
            _offsetY = _offsetYController.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ Setta la flag PRIMA di tutto
    _longPressTimer?.cancel();

    // Resetta i valori a valori sicuri
    _scale = 1.0;
    _stretchX = 1.0;
    _stretchY = 1.0;
    _offsetX = 0.0;
    _offsetY = 0.0;

    // Ferma le animazioni
    _controller.stop();
    _stretchXController.stop();
    _stretchYController.stop();
    _offsetXController.stop();
    _offsetYController.stop();

    _controller.dispose();
    _stretchXController.dispose();
    _stretchYController.dispose();
    _offsetXController.dispose();
    _offsetYController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_isDisposed) return;
    _isPointerInside = true;
    _initialPosition = event.localPosition;
    _cursorPosition = event.localPosition;
    _longPressTriggered = false;

    _controller.stop();
    _stretchXController.stop();
    _stretchYController.stop();
    _offsetXController.stop();
    _offsetYController.stop();

    // Calculate target scale
    _targetScale = widget.scaleOnPress;

    if (widget.autoScaleBySize) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        // Use the smaller dimension to ensure consistent behavior
        final hypotenuse = sqrt(pow(size.width, 2) + pow(size.height, 2));

        // Calculate scale: smaller elements = larger scale factor
        _targetScale = 1.0 + (widget.basePixelIncrease / hypotenuse);
      }
    }

    // Fast and elastic spring for tap down - high stiffness, low damping
    // const spring = SpringDescription(mass: 1.0, stiffness: 600.0, damping: 8.0);
    const spring = SpringDescription(mass: 1.2, stiffness: 500.0, damping: 15.0);
    final simulation = SpringSimulation(spring, _scale, _targetScale, 0.0);
    _controller.animateWith(simulation);

    // Start long press timer
    if (widget.onLongPress != null) {
      _longPressTimer?.cancel();
      _longPressTimer = Timer(widget.longPressDuration, _handleLongPress);
    }
  }

  void _handlePointerMove(PointerEvent event) {
    if (_isDisposed) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || _initialPosition == null) return;

    final position = event.localPosition;
    final size = renderBox.size;

    _cursorPosition = position;
    _isPointerInside = position.dx >= 0 && position.dx <= size.width && position.dy >= 0 && position.dy <= size.height;

    // Calculate drag offset from initial position
    final newOffset = position - _initialPosition!;

    // Liquid glass effect: stretch in the direction of movement
    const baseStretchFactor = 5000.0; // Base sensitivity (higher = less sensitive)
    const baseMaxStretch = 0.15; // Base maximum stretch amount
    const baseTranslateFactor = 0.02; // Base movement amount

    // Apply sensitivity multipliers
    final stretchFactor = baseStretchFactor / widget.stretchSensitivity;
    final maxStretch = baseMaxStretch * widget.stretchSensitivity;
    final translateFactor = baseTranslateFactor * widget.translateSensitivity;

    // Calculate raw stretch amount for each axis
    final rawStretchX = (newOffset.dx.abs() / stretchFactor).clamp(0.0, maxStretch);
    final rawStretchY = (newOffset.dy.abs() / stretchFactor).clamp(0.0, maxStretch);

    // Perfect area conservation: when one axis stretches, the other compresses by the same amount
    // The difference determines which direction dominates
    // - If moving horizontally: diff > 0, so X increases and Y decreases
    // - If moving vertically: diff < 0, so Y increases and X decreases
    // - If moving diagonally: diff ~ 0, so both stay at 1.0
    final diff = (rawStretchX - rawStretchY).clamp(-maxStretch, maxStretch);
    final finalStretchX = 1.0 + diff;
    final finalStretchY = 1.0 - diff;

    // Apply stretch and offset immediately (no spring delay during drag)
    setState(() {
      _stretchX = finalStretchX;
      _stretchY = finalStretchY;
      _offsetX = newOffset.dx * translateFactor;
      _offsetY = newOffset.dy * translateFactor;
    });
  }

  Future<void> _handlePointerUp(PointerUpEvent event) async {
    _longPressTimer?.cancel();

    // Check if scale-up animation is complete
    const scaleThreshold = 0.02; // 2% tolerance
    final isScaleUpComplete = (_scale - _targetScale).abs() < scaleThreshold;

    if (!isScaleUpComplete) {
      // Wait a bit for the scale-up animation to be visible
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _animateBack();

    // Only call onPressed if the pointer was released inside the widget and long press wasn't triggered
    if (_isPointerInside && !_longPressTriggered) {
      widget.onPressed?.call();
    }

    _isPointerInside = false;
    _initialPosition = null;
    _cursorPosition = null;
    _longPressTriggered = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isDisposed) return;
    _longPressTimer?.cancel();
    _animateBack();
    _isPointerInside = false;
    _initialPosition = null;
    _cursorPosition = null;
    _longPressTriggered = false;
  }

  void _handleLongPress() {
    if (_isDisposed) return;
    if (_isPointerInside && widget.onLongPress != null) {
      _longPressTriggered = true;
      widget.onLongPress!.call();
    }
  }

  void _animateBack() {
    if (_isDisposed) return;

    _controller.stop();
    _stretchXController.stop();
    _stretchYController.stop();
    _offsetXController.stop();
    _offsetYController.stop();

    // Slower, smoother spring for release - lower stiffness, higher damping
    const spring = SpringDescription(mass: 1.0, stiffness: 180.0, damping: 24.0);

    final simulation = SpringSimulation(spring, _scale, 1.0, 0.0);

    _controller.animateWith(simulation);

    // Elastic spring for stretch reset - bouncy
    final stretchSpring = SpringDescription(mass: 1.0, stiffness: 250.0, damping: widget.stretchSpringDamping);

    final stretchSimX = SpringSimulation(stretchSpring, _stretchX, 1.0, 0.0);

    final stretchSimY = SpringSimulation(stretchSpring, _stretchY, 1.0, 0.0);

    final offsetSimX = SpringSimulation(stretchSpring, _offsetX, 0.0, 0.0);

    final offsetSimY = SpringSimulation(stretchSpring, _offsetY, 0.0, 0.0);

    _stretchXController.animateWith(stretchSimX);
    _stretchYController.animateWith(stretchSimY);
    _offsetXController.animateWith(offsetSimX);
    _offsetYController.animateWith(offsetSimY);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Protezione extra
    if (_isDisposed) {
      return widget.child;
    }
    // ✅ Valida TUTTI i valori
    final safeScale = (_scale.isFinite && _scale > 0) ? _scale : 1.0;
    final safeStretchX = (_stretchX.isFinite && _stretchX > 0) ? _stretchX : 1.0;
    final safeStretchY = (_stretchY.isFinite && _stretchY > 0) ? _stretchY : 1.0;
    final safeOffsetX = _offsetX.isFinite ? _offsetX : 0.0;
    final safeOffsetY = _offsetY.isFinite ? _offsetY : 0.0;

    // ✅ Costruisci la matrice in modo più sicuro
    final scaleX = safeScale * safeStretchX;
    final scaleY = safeScale * safeStretchY;

    // Verifica finale che tutto sia finito
    if (!scaleX.isFinite || !scaleY.isFinite || !safeOffsetX.isFinite || !safeOffsetY.isFinite) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: widget.child,
      );
    }

    // ✅ Usa i metodi NON deprecati con i parametri corretti
    final matrix = Matrix4.identity()
      ..translateByDouble(safeOffsetX, safeOffsetY, 0.0, 1.0) // tw = 1.0
      ..scaleByDouble(scaleX, scaleY, 1.0, 1.0); // sw = 1.0

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: Transform(
        transform: matrix,
        alignment: Alignment.center,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            if (_cursorPosition != null && widget.enableBrightness)
              Positioned.fill(
                child: ClipRect(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _RadialGradientPainter(position: _cursorPosition!)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadialGradientPainter extends CustomPainter {
  final Offset position;

  _RadialGradientPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Colors.white, // Lower opacity
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: position, radius: 250.0))
      ..blendMode = BlendMode.overlay; // Try overlay or softLight instead

    canvas.drawCircle(position, 250.0, paint);
  }

  @override
  bool shouldRepaint(_RadialGradientPainter oldDelegate) {
    return oldDelegate.position != position;
  }
}
