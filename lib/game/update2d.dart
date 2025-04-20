import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/game/has_position_3d.dart';

/// Mixin for PositionComponents that automatically update their 2D position and size
/// based on the projected vertices calculated by the 3D system.
mixin HasUpdate2D on PositionComponent implements HasPosition3D {
  final Vector2 _projectedCenter = Vector2.zero();
  final Vector2 _minBounds = Vector2.zero();
  final Vector2 _maxBounds = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt); // Ensure parent updates run

    // Access position3d via 'this' as HasPosition3D is required
    if (this.position3d.projectedVertices.isEmpty || priority < 0) {
      // Not visible or no vertices, potentially hide or do nothing
      // size.setZero(); // Optional: collapse size if not visible
      return;
    }

    // Calculate bounding box and center from projected vertices
    _minBounds.setValues(double.infinity, double.infinity);
    _maxBounds.setValues(double.negativeInfinity, double.negativeInfinity);
    _projectedCenter.setZero();

    for (final v in this.position3d.projectedVertices) {
      _projectedCenter.add(v);
      _minBounds.x = min(_minBounds.x, v.x);
      _minBounds.y = min(_minBounds.y, v.y);
      _maxBounds.x = max(_maxBounds.x, v.x);
      _maxBounds.y = max(_maxBounds.y, v.y);
    }

    // Update 2D size based on the bounding box dimensions
    size.x = _maxBounds.x - _minBounds.x;
    size.y = _maxBounds.y - _minBounds.y;

    // Update 2D position to the center of the bounding box (or average)
    // Using average center here as it aligns with previous logic
    _projectedCenter.scale(1.0 / this.position3d.projectedVertices.length);
    position.setFrom(_projectedCenter);

    // Adjust anchor if needed based on how position/size are used.
    // Since we set position to center and size to bounds, anchor should be center.
    if (anchor != Anchor.center) {
      logWarn('Anchor is not center. Adjusting to center.');
      anchor = Anchor.center;
    }
  }
}
