import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class IonPulse extends SpriteComponent with CollisionCallbacks, Recyclable, DirectionalProjectile, HasVisibility {
  IonPulse() {
    anchor = Anchor.center;
    size.setAll(16);
    _sprites = atlas.sheetI('melt.png', 5, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 8)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  late final SpriteSheet _sprites;

  double _delay = 0;
  double _size_time = 1;
  late Vector2 _origin;

  void reset(double delay, Vector2 position) {
    _delay = delay;
    _size_time = 1;
    _origin = position;
  }

  @override
  void update(double dt) {
    isVisible = _delay <= 0;
    if (_delay > 0) {
      _delay = max(0, _delay - dt);
      if (_delay == 0) {
        position.setFrom(_origin);
        x += 25;
        y -= 25 / 4;
      }
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
      if (_size_time == 0) recycle();
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
