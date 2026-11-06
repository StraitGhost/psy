import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sacude horizontalmente a su hijo cuando [active] pasa a true.
///
/// No cambia la estructura del árbol, así que el estado interno del hijo
/// (por ejemplo lo escrito en un campo) no se pierde.
class ShakeWidget extends StatelessWidget {
  const ShakeWidget({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 500),
      child: child,
      builder: (context, t, child) {
        final dx = active ? math.sin(t * math.pi * 6) * 10 * (1 - t) : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
