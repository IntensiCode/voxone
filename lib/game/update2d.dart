import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/game/has_position_3d.dart';

/// Mixin for PositionComponents that automatically update their 2D position and size
/// based on the projected vertices calculated by the 3D system.
mixin HasUpdate2D on PositionComponent implements HasPosition3D {
  final Vector2 _minBounds = Vector2.zero();
  final Vector2 _maxBounds = Vector2.zero();

  @override
  void onMount() {
    super.onMount();

    debugMode = true;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isVisible) return;

    assert(priority != HasPosition3D.INVISIBILITY_PRIORITY);
    assert(anchor == Anchor.center, 'Anchor must be center for now.');

    position = position3d.projectedOrigin;

    final vs = position3d.projectedVertices;
    // assert(vs.isNotEmpty, 'Projected vertices should not be empty.');
    if (vs.isEmpty) {
      logWarn('Projected vertices are empty. Skipping update.');
      return;
    }

    // Calculate bounding box and center from projected vertices
    _minBounds.setFrom(vs.first);
    _maxBounds.setFrom(vs.first);
    for (final v in vs) {
      _minBounds.x = min(_minBounds.x, v.x);
      _minBounds.y = min(_minBounds.y, v.y);
      _maxBounds.x = max(_maxBounds.x, v.x);
      _maxBounds.y = max(_maxBounds.y, v.y);
    }

    // Update 2D size based on the bounding box dimensions
    size.x = _maxBounds.x - _minBounds.x;
    size.y = _maxBounds.y - _minBounds.y;

    // Update 2D position to center the component
    for (final v in vs) {
      v.sub(position);
    }
  }
}
