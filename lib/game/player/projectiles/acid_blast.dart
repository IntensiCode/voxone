import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/projectiles/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';

class AcidBlast extends SpriteComponent with CollisionCallbacks, Recyclable, DirectionalProjectile {
  static const initial_damage = 6.0;
  static const start_size = 16.0;
  static const size_speed = 12.0;

  AcidBlast() {
    anchor = Anchor.center;
    size.setAll(start_size);
    angle = -pi / 16;

    add(_hitbox = CircleHitbox(radius: start_size, anchor: Anchor.center)..debug());

    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    scale.y = 0.6;
  }

  late CircleHitbox _hitbox;
  late SpriteAnimation _anim;

  @override
  double get base_speed => 400;

  double _anim_time = 0;

  double _damage = initial_damage;

  void reset(Vector2 origin) {
    _damage = initial_damage;
    size.setAll(start_size);
    position.setFrom(origin);
    x += 25;
    y -= 25 / 4;
  }

  @override
  onLoad() {
    this._anim = animCR('acid_blast.png', 1, 16, vertical: true);
    this.sprite = _anim.frames.first.sprite;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _anim_time = (_anim_time + dt) % 1;
    this.sprite = _anim.frames[(_anim_time * _anim.frames.length).floor()].sprite;

    size.x += size_speed * dt;
    size.y += size_speed * dt;

    _hitbox.radius = size.y / 2;
    _hitbox.x = size.x / 2;
    _hitbox.y = size.y / 2;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          _damage /= 2;
          it.on_hit(damage: _damage, intersections: intersectionPoints);
          if (_damage < 1) recycle();
          size.scale(0.5);
        }
      });
    }
  }
}
