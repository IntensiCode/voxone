import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/enemies/marauder_shot.dart';
import 'package:voxone/game/player/projectiles/directional_projectile.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class NukeMissile extends SpriteComponent
    with CollisionCallbacks, Recyclable, FakeThreeDee, DirectionalProjectile, HasVisibility {
  NukeMissile(this.decals, this._emit_nuke) {
    anchor = Anchor.center;
    size.setAll(30);
    _sprites = atlas.sheetI('missile.png', 4, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 15, isSolid: true)..debug());
    angle = pi / 2 - pi / 16;
    priority = 100;
  }

  final Decals decals;
  late final Function(FakeThreeDee) _emit_nuke;
  late final SpriteSheet _sprites;

  double _speed = 100;
  double _anim_time = 0;
  double _smoke_time = 0;

  @override
  double get base_speed => _speed;

  void reset(FakeThreeDee origin) {
    _speed = 100;
    init_fake_3d(origin);
    x -= 25;
    y += 25 / 4;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _speed += 50 * dt + pow(_speed, 0.9) * dt;
    _anim_time = (_anim_time + dt * 4) % 1;
    _smoke_time += dt;
    if (_smoke_time > 0.01) {
      _smoke_time = 0;
      decals.spawn3d(Decal.smoke, this);
    }

    change_direction(0);

    final sprite_index = (_anim_time * (_sprites.columns - 1)).toInt();
    sprite = _sprites.getSprite(0, sprite_index);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is! MarauderShot && other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          final d = switch (difficulty) {
            Difficulty.easy => 60.0,
            Difficulty.normal => 50.0,
            Difficulty.hard => 45.0,
          };
          it.on_hit(damage: d, intersections: intersectionPoints);
          _emit_nuke(this);
          recycle();
        }
      });
    }
  }
}
