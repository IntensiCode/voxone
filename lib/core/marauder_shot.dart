import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/friendly_target.dart';
import 'package:voxone/util/extensions.dart';

class MarauderShot extends PositionComponent with CollisionCallbacks, HasPaint {
  static const _inner = Color(0xFFa0ffa0);
  static const _outer = Color(0xFF209f20);
  static const _core = Color(0xFFffffff);

  MarauderShot() {
    size.setAll(4);
    add(CircleHitbox(radius: 4, anchor: Anchor.center)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  @override
  void update(double dt) {
    x -= 300 * dt;
    y += 300 / 4 * dt;
    if (x < -100) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    paint.color = _outer;
    canvas.drawCircle(Offset.zero, 3.5, paint);
    paint.color = _inner;
    canvas.drawCircle(Offset.zero, 3, paint);
    paint.color = _core;
    canvas.drawCircle(Offset.zero, 2, paint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other case FriendlyTarget it) {
      if (it.susceptible) {
        it.on_hit(1);
        removeFromParent();
      }
    }
  }
}
