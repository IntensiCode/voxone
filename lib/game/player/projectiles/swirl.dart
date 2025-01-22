import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/projectiles/directional_projectile.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class Swirl extends SpriteComponent
    with CollisionCallbacks, Recyclable, FakeThreeDee, DirectionalProjectile, HasVisibility {
  Swirl() {
    anchor = Anchor.center;
    size.setAll(24);
    _sprites = atlas.sheetI('swirl.png', 8, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 8, position: size / 2, anchor: Anchor.center, isSolid: true)..debug());
  }

  late final SpriteSheet _sprites;

  @override
  double get base_speed => 700;

  double _anim_time = 0;

  double _damage = 1;

  void reset(FakeThreeDee origin) {
    init_fake_3d(origin);
    x += 25;
    y -= 25 / 4;
    _damage = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _anim_time = (_anim_time + dt * 3) % 1;
    angle = _anim_time * pi * 2;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(intersections: intersectionPoints, damage: _damage);
          _damage = max(0.1, _damage * 0.9);
        }
      });
    }
  }
}
