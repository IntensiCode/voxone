import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage1/marauder_shot.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class NukeMissile extends SpriteComponent with CollisionCallbacks, Recyclable, DirectionalProjectile, HasVisibility {
  NukeMissile(this.decals, this._emit_nuke) {
    anchor = Anchor.center;
    size.setAll(30);
    _sprites = atlas.sheetI('missile.png', 4, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 15)
      ..renderShape = debug
      ..paint.opacity = 0.2);
    angle = pi / 2 - pi / 16;
    priority = 100;
  }

  final Decals decals;
  late final Function(Vector2) _emit_nuke;
  late final SpriteSheet _sprites;

  double _speed = 100;
  double _anim_time = 0;
  double _smoke_time = 0;

  @override
  double get base_speed => _speed;

  void reset(Vector2 origin) {
    _speed = 100;
    position.setFrom(origin);
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
      decals.spawn(Decal.smoke, position);
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
          it.on_hit(damage: 15, intersections: intersectionPoints);
          _emit_nuke(position);
          recycle();
        }
      });
    }
  }
}
