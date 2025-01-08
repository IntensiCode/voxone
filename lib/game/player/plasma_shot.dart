import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';

class PlasmaShot extends PositionComponent with CollisionCallbacks, HasPaint {
  static const _blue1 = Color(0xFFa0a0ff);
  static const _blue2 = Color(0xFF20209f);

  double _start_time = 1;

  PlasmaShot() {
    size.setAll(4);
    add(CircleHitbox(radius: 4, anchor: Anchor.center)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  final direction = Vector2(1, 0)
    ..rotate(-pi / 16)
    ..scale(500);

  final _tmp = Vector2.zero();

  void change_direction(double relative_angle) {
    direction.setValues(1, 0);
    direction.rotate(-pi / 16 + relative_angle);
    direction.scale(500);
  }

  @override
  void update(double dt) {
    if (_start_time > 0) _start_time -= dt;

    _tmp.setFrom(direction);
    _tmp.scale(dt);
    position.add(_tmp);

    // x += 500 * dt;
    // y -= 500 / 4 * dt;
    if (x > 900) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    paint.color = _blue2;
    canvas.drawCircle(Offset.zero, 3.5 + _start_time * 4, paint);
    paint.color = _blue1;
    canvas.drawCircle(Offset.zero, 3, paint);
    paint.color = white;
    canvas.drawCircle(Offset.zero, 2, paint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(intersections: intersectionPoints);
          removeFromParent();
        }
      });
    }
  }
}
