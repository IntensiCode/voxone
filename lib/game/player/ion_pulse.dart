import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';

class IonPulse extends SpriteComponent with CollisionCallbacks, DirectionalProjectile, HasVisibility {
  late final SpriteSheet _sprites;

  double delay = 0;
  double _size_time = 1;

  IonPulse() {
    anchor = Anchor.center;
    size.setAll(16);
    _sprites = atlas.sheetI('melt.png', 5, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 8)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  @override
  void update(double dt) {
    isVisible = delay <= 0;
    if (delay > 0) {
      delay = max(0, delay - dt);
      return;
    }

    super.update(dt);

    if (_size_time > 0) {
      _size_time = max(0, _size_time - dt * 5);
      sprite = _sprites.getSprite(0, (_size_time * (_sprites.columns - 1)).toInt());
    }
    if (_size_time < 0) {
      _size_time = min(0, _size_time + dt * 5);
      sprite = _sprites.getSprite(0, ((1 + _size_time) * (_sprites.columns - 1)).toInt());
      if (_size_time == 0) removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (_size_time != 0) return;

    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(intersections: intersectionPoints);
          _size_time = -1;
        }
      });
    }
  }
}
