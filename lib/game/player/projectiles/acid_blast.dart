import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/projectiles/directional_projectile.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

class AcidBlast extends SpriteComponent with CollisionCallbacks, Recyclable, FakeThreeDee, DirectionalProjectile {
  static const initial_damage = 3.0;
  static const start_size = 16.0;
  static const size_speed = 12.0;

  AcidBlast(this._respawn) {
    anchor = Anchor.center;
    size.setAll(start_size);
    angle = -pi / 16;

    add(_hitbox = CircleHitbox(radius: start_size, anchor: Anchor.center, isSolid: true)..debug());

    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    scale.y = 0.6;
  }

  late final Function(AcidBlast) _respawn;

  late CircleHitbox _hitbox;
  late SpriteAnimation _anim;

  @override
  double get base_speed => 400;

  double _anim_time = 0;

  double _damage = initial_damage;

  void reset(FakeThreeDee origin) {
    set_direction_angle(0);
    angle = base_direction.screenAngle() - pi  / 2;
    _damage = initial_damage +
        switch (difficulty) {
          Difficulty.easy => 2,
          Difficulty.normal => 1,
          Difficulty.hard => 0,
        };
    size.setAll(start_size);
    init_fake_3d(origin);
    x += 25;
    y -= 25 / 4;
  }

  void reset_respawn(AcidBlast blast) {
    _damage = blast._damage;
    size.setFrom(blast.size);
    init_fake_3d(blast);
    change_direction(rng.nextDoublePM(pi));
    angle = base_direction.screenAngle() - pi  / 2;
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
    if (recycled) return;
    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(damage: _damage, intersections: intersectionPoints);
          _damage /= 2;
          size.scale(0.5);
          if (_damage < 1)
            recycle();
          else
            _respawn(this);
        }
      });
    }
  }
}
