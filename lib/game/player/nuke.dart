import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class Nuke extends PositionComponent with CollisionCallbacks, Recyclable, DirectionalProjectile, HasPaint {
  Nuke() {
    size.setAll(250);
    add(CircleHitbox(anchor: Anchor.center, isSolid: true)
      ..renderShape = debug
      ..paint.opacity = 0.2);

    paint.color = white;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 16);

    priority = 5000;
  }

  double _life_time = 0;

  @override
  double get base_speed => 0;

  void reset(Vector2 origin) {
    _life_time = 0;
    position.setFrom(origin);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life_time += dt;
    if (_life_time > 1) recycle();
  }

  @override
  void render(Canvas canvas) {
    final saved = paint.opacity;

    final x = _life_time < 0.5 ? _life_time * 2 : 1 - (_life_time - 0.5) * 2;
    final o = Curves.easeInOutCubic.transform(x.clamp(0, 1));
    paint.opacity *= o;
    canvas.drawCircle(Offset.zero, size.x / 2, paint);

    paint.opacity = saved;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_life_time < 0.2 && other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(intersections: intersectionPoints);
        }
      });
    }
  }
}
