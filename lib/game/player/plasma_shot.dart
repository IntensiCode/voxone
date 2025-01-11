import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class PlasmaShot extends PositionComponent with CollisionCallbacks, Recyclable, DirectionalProjectile, HasPaint {
  static const _blue1 = Color(0xFFa0a0ff);
  static const _blue2 = Color(0xFF20209f);

  static double power_boost = 1;

  PlasmaShot() {
    size.setAll(4);
    add(CircleHitbox(radius: 4, anchor: Anchor.center)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  double _start_time = 1;

  @override
  double get base_speed => 400 + power_boost * 25;

  void reset(Vector2 origin) {
    _start_time = 1;
    change_direction(0);
    position.setFrom(origin);
    x += 25;
    y -= 25 / 4;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_start_time > 0) _start_time = max(0, _start_time - dt);
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
          it.on_hit(intersections: intersectionPoints, damage: power_boost * 0.75);
          recycle();
        }
      });
    }
  }
}
