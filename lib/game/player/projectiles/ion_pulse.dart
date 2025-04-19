import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/traits.dart';
import 'package:stardash/game/player/projectiles/directional_projectile.dart';
import 'package:stardash/game/shared/difficulty.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/random.dart';

class IonPulse extends SpriteComponent
    with CollisionCallbacks, Recyclable, FakeThreeDee, DirectionalProjectile, HasVisibility {
  IonPulse() {
    anchor = Anchor.center;
    size.setAll(16);
    _sprites = atlas.sheetI('melt.png', 5, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 8, isSolid: true)..debug());
  }

  late final SpriteSheet _sprites;

  double _delay = 0;
  double _size_time = 1;
  late Vector2 _origin;

  void reset(double delay, FakeThreeDee origin) {
    _delay = delay;
    _size_time = 1;
    _origin = origin.position;
    set_direction_angle(0);
    init_fake_3d(origin);
    fake_height -= 5;
  }

  @override
  void onMount() {
    super.onMount();
    damage = switch (difficulty) {
      Difficulty.easy => 0.35,
      Difficulty.normal => 0.3,
      Difficulty.hard => 0.25,
    };
  }

  late double damage;

  @override
  void update(double dt) {
    isVisible = _delay <= 0;
    if (_delay > 0) {
      _delay = max(0, _delay - dt);
      if (_delay == 0) {
        position.setFrom(_origin);
        position.add(base_direction * dt / 4);
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

    if (recycled) return;

    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(intersections: intersectionPoints, damage: damage * _size_time.abs());
          _size_time = -1;
          set_direction_angle(rng.nextDoublePM(pi / 2));
        }
      });
    }
  }
}
