import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import 'package:liqui/src/buttons/scale_tap.dart';

/// Info sullo scrollable trovato al punto toccato
typedef ScrollableInfo = ({bool isOnScrollable, bool isAtTop});

/// Custom gesture recognizer that wins in the gesture arena when scroll is at top
class _SheetDragGestureRecognizer extends VerticalDragGestureRecognizer {
  final ScrollableInfo? Function(Offset)? getScrollableInfo;
  final bool enableDrag;

  bool _hasForcedWin = false;
  double? _initialY;
  ScrollableInfo? _cachedScrollableInfo; // Cache del risultato per evitare hit test ripetuti

  _SheetDragGestureRecognizer({this.getScrollableInfo, this.enableDrag = true});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _hasForcedWin = false;
    _initialY = event.position.dy;
    // Calcola una sola volta info sullo scrollable (se esiste e la sua position)
    _cachedScrollableInfo = getScrollableInfo?.call(event.position);
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_hasForcedWin && event is PointerMoveEvent && _initialY != null && enableDrag) {
      final delta = event.position.dy - _initialY!;
      final info = _cachedScrollableInfo;

      // Caso 1: Nessuno scrollable (elemento fisso) E drag down → Vinci sempre
      if (info == null && delta > 0) {
        resolve(GestureDisposition.accepted);
        _hasForcedWin = true;
      }
      // Caso 2: C'è scrollable E è in cima E drag down → Vinci per bloccare la lista
      else if (info != null && info.isOnScrollable && info.isAtTop && delta > 0) {
        resolve(GestureDisposition.accepted);
        _hasForcedWin = true;
      }
      // Caso 3: Tutti gli altri casi → Lascia che la gesture arena decida naturalmente
    }

    super.handleEvent(event);
  }

  @override
  void dispose() {
    _initialY = null;
    _cachedScrollableInfo = null;
    super.dispose();
  }
}

/// Evolved wrapper for custom bottom sheet with full height control
class CustomBottomSheetWrapper extends StatefulWidget {
  final Widget child;

  /// Threshold in pixels - if dragged down more than this, dismiss the sheet
  final double dismissThreshold;

  /// Velocity threshold in pixels/second - if velocity exceeds this, dismiss
  final double velocityThreshold;

  final double screenCornerRadius;

  final Color backgroundColor;

  /// Optional GlobalKey for the scrollable widget inside the sheet
  /// Used to detect if touch is on the scrollable vs fixed elements
  final GlobalKey? scrollableKey;

  /// Enable/disable drag to dismiss functionality
  final bool enableDrag;

  /// Animation controller from the route for entry/exit animations
  final Animation<double> routeAnimation;

  /// Callback when sheet should be dismissed
  final VoidCallback? onDismiss;

  final bool enablePopoverEffect;

  const CustomBottomSheetWrapper({
    super.key,
    required this.child,
    this.dismissThreshold = 150.0,
    this.velocityThreshold = 700.0,
    this.screenCornerRadius = 0.0,
    this.enablePopoverEffect = false,
    this.backgroundColor = Colors.white,
    this.scrollableKey,
    this.enableDrag = true,
    required this.routeAnimation,
    this.onDismiss,
  });

  @override
  State<CustomBottomSheetWrapper> createState() => _CustomBottomSheetWrapperState();
}

class _CustomBottomSheetWrapperState extends State<CustomBottomSheetWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _offsetY = 0.0;
  bool _isDismissing = false;

  // Track drag state
  double? _scrollDragStartY;

  // Cache degli scrollable registrati tramite ScrollMetricsNotification
  final Map<ScrollableState, RenderBox> _scrollables = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _offsetY = _controller.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollables.clear();
    super.dispose();
  }

  /// Registra scrollable quando viene costruito tramite ScrollMetricsNotification
  bool _onScrollMetrics(ScrollMetricsNotification notification) {
    final scrollableState = notification.context.findAncestorStateOfType<ScrollableState>();
    final renderBox = notification.context.findRenderObject() as RenderBox?;
    if (scrollableState != null && renderBox != null) {
      // final position = scrollableState.position;
      _scrollables[scrollableState] = renderBox;
      // myPrint('📝 Registered scrollable: ${scrollableState.widget.axisDirection}');
      // myPrint('   maxScrollExtent at registration: ${position.maxScrollExtent}');
      // myPrint('   Total scrollables in cache: ${_scrollables.length}');
    }
    return false; // Non bloccare la notifica
  }

  void _dismissSheet({double velocity = 0.0}) {
    _isDismissing = true;
    _controller.stop();

    // Target position off screen
    const targetY = 1000.0;

    // Threshold to call dismiss callback (when sheet is visually off screen)
    const dismissCallbackThreshold = 400.0;
    bool dismissCalled = false;

    // Add listener to call dismiss when sheet is off screen
    void listener() {
      if (!dismissCalled && _offsetY >= dismissCallbackThreshold) {
        dismissCalled = true;
        _controller.removeListener(listener);
        if (mounted) {
          widget.onDismiss?.call();
        }
      }
    }

    _controller.addListener(listener);

    // Use fling simulation if there's velocity, otherwise spring
    if (velocity > 100) {
      final simulation = FrictionSimulation(0.15, _offsetY, velocity);
      _controller.animateWith(simulation);
    } else {
      // Fast spring to dismiss
      const spring = SpringDescription(mass: 1.0, stiffness: 300.0, damping: 25.0);
      final simulation = SpringSimulation(spring, _offsetY, targetY, velocity / 1000);
      _controller.animateWith(simulation);
    }
  }

  void _animateBack() {
    if (_offsetY == 0.0) return;

    _controller.stop();

    // iOS-style spring animation - matches route animation
    const spring = SpringDescription(mass: 1.0, stiffness: 380.0, damping: 32.0);

    final simulation = SpringSimulation(spring, _offsetY, 0.0, 0.0);
    _controller.animateWith(simulation);
  }

  /// Ottiene info sullo scrollable al punto toccato (se esiste e la sua posizione)
  ScrollableInfo? _getScrollableInfo(Offset globalPosition) {
    // Metodo 1: Se c'è una scrollableKey, usala (metodo veloce e preciso)
    if (widget.scrollableKey != null) {
      final context = widget.scrollableKey!.currentContext;
      if (context != null) {
        final scrollable = Scrollable.maybeOf(context);
        final renderBox = context.findRenderObject() as RenderBox?;

        if (scrollable != null && renderBox != null) {
          final localPosition = renderBox.globalToLocal(globalPosition);
          // Verifica che il tocco sia effettivamente dentro lo scrollable
          if (renderBox.paintBounds.contains(localPosition)) {
            return (isOnScrollable: true, isAtTop: scrollable.position.pixels <= 0);
          }
        }
      }
    }

    // Metodo 2: Consulta la cache degli scrollable registrati (efficiente, nessun hit test!)
    if (_scrollables.isNotEmpty) {
      // Rimuovi scrollable non più attaccati al tree
      _scrollables.removeWhere((state, renderBox) => !renderBox.attached);

      // Rimuovi scrollable inattivi (pagine non visibili in Navigator, maxScrollExtent = 0)
      _scrollables.removeWhere((state, renderBox) => state.position.maxScrollExtent == 0);

      for (final entry in _scrollables.entries) {
        final scrollableState = entry.key;
        final renderBox = entry.value;

        try {
          final localPosition = renderBox.globalToLocal(globalPosition);
          if (renderBox.paintBounds.contains(localPosition)) {
            final position = scrollableState.position;
            final isAtTop = position.pixels <= position.minScrollExtent;
            return (isOnScrollable: true, isAtTop: isAtTop);
          }
        } catch (e) {
          //
        }
      }
    }
    return null;
    // Metodo 3 (Fallback): Hit-test automatico per trovare RenderViewport/Sliver
    // ignore: dead_code
    final result = BoxHitTestResult();
    RendererBinding.instance.renderViews.first.hitTest(result, position: globalPosition);

    bool foundScrollable = false;

    for (final entry in result.path) {
      final target = entry.target;
      final typeName = target.runtimeType.toString();

      // Trova qualsiasi tipo che contiene 'Viewport' e prova ad accedere a offset.pixels
      if (typeName.contains('Viewport')) {
        try {
          // Usa dynamic cast per accedere a offset.pixels anche se non è RenderViewport
          // ignore: avoid_dynamic_calls
          final double pixels = (target as dynamic).offset.pixels as double;
          return (isOnScrollable: true, isAtTop: pixels <= 0);
        } catch (e) {
          //
        }
      }

      // Metodo efficiente: Se troviamo _RenderScrollSemantics, usa debugCreator o accedi alla position
      if (typeName.contains('ScrollSemantics')) {
        foundScrollable = true;

        // Approccio 1: Usa debugCreator (solo in debug mode, molto efficiente)
        try {
          // ignore: avoid_dynamic_calls
          final debugCreatorObj = (target as dynamic).debugCreator;
          if (debugCreatorObj != null) {
            // ignore: avoid_dynamic_calls
            final Element? element = debugCreatorObj.element as Element?;
            if (element != null) {
              final scrollable = Scrollable.maybeOf(element);
              if (scrollable != null) {
                return (isOnScrollable: true, isAtTop: scrollable.position.pixels <= 0);
              }
            }
          }
        } catch (e) {
          //
        }

        // Approccio 2: Prova ad accedere direttamente alla position da _RenderScrollSemantics
        try {
          // ignore: avoid_dynamic_calls
          final position = (target as dynamic).position;
          if (position != null) {
            // ignore: avoid_dynamic_calls
            final double pixels = position.pixels as double;
            return (isOnScrollable: true, isAtTop: pixels <= 0);
          }
        } catch (e) {
          //
        }
      }

      // Fallback: Se troviamo un RenderSliver, prova a risalire al parent viewport
      if (typeName.contains('Sliver')) {
        foundScrollable = true;
        var parent = (target as RenderObject).parent;
        int depth = 0;
        while (parent != null && depth < 10) {
          final parentTypeName = parent.runtimeType.toString();
          if (parentTypeName.contains('Viewport')) {
            try {
              // ignore: avoid_dynamic_calls
              final double pixels = (parent as dynamic).offset.pixels as double;
              return (isOnScrollable: true, isAtTop: pixels <= 0);
            } catch (e) {
              //
            }
          }
          parent = parent.parent;
          depth++;
        }
      }
    }

    // Se abbiamo trovato scrollable ma non riusciamo a leggere la posizione,
    // ritorniamo null per lasciare gestire allo scrollable (non assumiamo isAtTop=true)
    if (foundScrollable) {
      return null;
    }

    // Nessuno scrollable trovato → elemento fisso (non su scrollable)
    return null;
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (_isDismissing) return;

    // Il recognizer ha già deciso se vincere o meno nella gesture arena
    // Se questo callback viene chiamato, significa che abbiamo vinto
    _scrollDragStartY = details.globalPosition.dy;
    _controller.stop();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;

    // Fallback: inizializza se onStart non è stato chiamato ancora
    // Può succedere se il recognizer vince dopo che alcuni eventi sono già arrivati
    if (_scrollDragStartY == null) {
      _scrollDragStartY = details.globalPosition.dy;
      _controller.stop();
    }

    final dragDelta = details.globalPosition.dy - _scrollDragStartY!;

    // Se stiamo dragging verso il basso
    if (dragDelta > 0 && !widget.enablePopoverEffect) {
      setState(() {
        _offsetY = dragDelta;
      });
    } else {
      // Dragging verso l'alto: rubber band effect
      final absDistance = dragDelta.abs();
      final resistance = 1.0 / (1.0 + absDistance * 0.02);

      setState(() {
        _offsetY = dragDelta * resistance * 0.8;
      });
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;

    final velocity = details.velocity.pixelsPerSecond.dy;
    final shouldDismiss = _offsetY > widget.dismissThreshold || velocity > widget.velocityThreshold;

    if (shouldDismiss && !widget.enablePopoverEffect) {
      _dismissSheet(velocity: velocity);
    } else {
      _animateBack();
    }

    _scrollDragStartY = null;
  }

  void _handleVerticalDragCancel() {
    _animateBack();
    _scrollDragStartY = null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final isTablet = screenSize.width > 450;
    final radius = max(widget.screenCornerRadius, 30.0);

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onScrollMetrics,
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          _SheetDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<_SheetDragGestureRecognizer>(
            () => _SheetDragGestureRecognizer(getScrollableInfo: _getScrollableInfo, enableDrag: widget.enableDrag),
            (_SheetDragGestureRecognizer instance) {
              instance
                ..onStart = _handleVerticalDragStart
                ..onUpdate = _handleVerticalDragUpdate
                ..onEnd = _handleVerticalDragEnd
                ..onCancel = _handleVerticalDragCancel;
            },
          ),
        },
        behavior: HitTestBehavior.translucent,
        child: Transform.translate(
          // Solo dismiss offset (drag down)
          offset: _offsetY > 0
              ? Offset(0, widget.enablePopoverEffect ? 0 : _offsetY)
              : Offset(0, isTablet ? _offsetY / (!widget.enablePopoverEffect ? 1.75 : 5) : 0),
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Color.fromRGBO(17, 12, 46, 0.15), blurRadius: 100)],
            ),
            child: LiquiScaleTap(
              stretchSensitivity: 0.025,
              scaleOnPress: 1.008,
              stretchSpringDamping: 20,
              translateSensitivity: 0.3,
              autoScaleBySize: false,
              child: ClipRSuperellipse(
                clipper: widget.enablePopoverEffect ? AnimatedRadiusClipper(widget.routeAnimation, radius) : null,
                borderRadius: .circular(radius),
                child: () {
                  final content = ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_offsetY > 0 && widget.enablePopoverEffect)
                          ColoredBox(
                            color: widget.backgroundColor,
                            child: SizedBox(
                              height: _offsetY.abs() / (widget.enablePopoverEffect ? 10 : 1),
                              width: double.maxFinite,
                            ),
                          ),
                        // Main content
                        Flexible(key: const ValueKey("sheet_content"), child: widget.child),
                        // Rubber band space (solo quando drag up)
                        if (_offsetY < 0)
                          ColoredBox(
                            color: widget.backgroundColor,
                            child: SizedBox(
                              height: _offsetY.abs() / (widget.enablePopoverEffect ? 10 : 1),
                              width: double.maxFinite,
                            ),
                          ),
                      ],
                    ),
                  );

                  // Apply BackdropFilter only if background is semi-transparent
                  if (widget.backgroundColor.a < 255) {
                    return BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: content);
                  }

                  return content;
                }(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedRadiusClipper extends CustomClipper<RSuperellipse> {
  final Animation<double> animation;
  final double radius;

  AnimatedRadiusClipper(this.animation, this.radius) : super(reclip: animation);

  @override
  RSuperellipse getClip(Size size) {
    final progress = max(animation.value.clamp(0.0, 1.0), 0.01);
    final compensatedRadius = radius / progress;
    return RSuperellipse.fromRectAndRadius(Offset.zero & size, Radius.circular(compensatedRadius));
  }

  @override
  bool shouldReclip(AnimatedRadiusClipper oldClipper) => false;
}

// ignore: unused_element
class _PopoverArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h) // base sinistra
      ..lineTo(w * 0.35, h * 0.4) // salita sinistra
      ..quadraticBezierTo(
        w * 0.45,
        h * 0.1, // punto di controllo verso la punta
        w * 0.5,
        0, // punta centrale
      )
      ..quadraticBezierTo(
        w * 0.55,
        h * 0.1, // punto di controllo verso destra
        w * 0.65,
        h * 0.4, // discesa destra
      )
      ..lineTo(w, h) // base destra
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrianglePainter extends CustomPainter {
  final double topRadius;
  final Color color;

  TrianglePainter({this.topRadius = 4.0, this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Calcola i punti per il triangolo con il vertice arrotondato in alto
    final centerX = size.width / 2;
    final radius = topRadius.clamp(0.0, size.width / 2);

    // Inizia dal lato sinistro del vertice arrotondato
    path.moveTo(centerX - radius, radius);

    // Crea l'arco arrotondato in alto
    path.arcToPoint(Offset(centerX + radius, radius), radius: Radius.circular(radius));

    // Linea verso il basso a destra
    path.lineTo(size.width - 5, size.height - 5);
    path.arcToPoint(Offset(size.width + 5, size.height), radius: const Radius.circular(15), clockwise: false);

    // Linea verso il basso a sinistra
    path.lineTo(0, size.height);

    path.arcToPoint(Offset(5, size.height - 5), radius: const Radius.circular(15), clockwise: false);

    // Chiude il triangolo
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
