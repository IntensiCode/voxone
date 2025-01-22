import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/marauder_mines.dart';
import 'package:voxone/game/enemies/marauder_pulse_gun.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';

class SatelliteMarauder extends EnemyEntity
    with
        CollisionCallbacks,
        HasVisibility,
        _CreateSatelliteEntity,
        _MoveIntoFormationOnIncoming,
        FloatOnActive,
        NopOnSweeping,
        TumbleOnExploding,
        SpawnExtrasOnExploding,
        _KamikazeOnLeaving {
  SatelliteMarauder(super.wave);

  @override
  double get volatile_incoming_time => 0.1;
}

mixin _CreateSatelliteEntity on EnemyEntity, HasVisibility {
  @override
  createEntity() async {
    reset_hit_points_to(10);

    active_time_limit = dev ? 20 : 45;
    active_time_limit += rng.nextDoubleLimit(5);

    isVisible = false;
    size.setAll(40);

    set_sprite_source(atlas.sprite('entities/ultraviolet_intruder.png'), 19);
    rot_x = -pi / 8;
    rot_y = -pi / 2 + pi / 8;
    rot_z = -pi / 8;
    scale_x = 1.2;
    scale_y = 3.5;
    scale_z = 1.2;

    await add(EnemyHealthBar(this));
    await add(CircleHitbox(
      collisionType: CollisionType.passive,
      anchor: Anchor.center,
      isSolid: true,
    )..anchor_to_parent());
    await add(MarauderPulseGun(this));
  }
}

mixin _MoveIntoFormationOnIncoming on EnemyEntity, HasVisibility {
  final _origin = Vector2.zero();
  double _incoming_delay = 0;

  late final CatmullRomSpline _path;

  void init_formation(Vector2 origin, double delay, int dy) {
    _origin.setFrom(origin);
    _incoming_delay = delay;
    _path = CatmullRomSpline([
      origin.toOffsetXY(25, -20),
      origin.toOffsetXY(150 - dy * 10.0, -dy.toDouble() * 10 - 20),
      origin.toOffsetXY(0, -50 * dy.sign - dy.toDouble() * 20 - 10),
      origin.toOffsetXY(-100, -50 * dy.sign - dy.toDouble() * 20),
      target_position.toOffset(),
    ]);
  }

  @override
  void on_incoming(double dt) {
    if (_incoming_delay > 0) {
      _incoming_delay -= dt;
      return;
    }

    isVisible = true;

    incoming_time += dt / 4;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = EnemyState.active;
    }

    final i = incoming_time;
    final p = _path.transform(i);
    position.x = p.dx;
    position.y = p.dy;

    if (i > 0.01) {
      final pb = _path.transform(i - 0.01);
      _last_dir.setFrom(position);
      _last_dir.x -= pb.dx;
      _last_dir.y -= pb.dy;
      _last_dir.scale(10);

      rot_y = pi / 2 - atan2(_last_dir.y, _last_dir.x);
    }
    if (i > 0.9) rot_y = -1 - (1 - i) * 10;

    fake_height = i < 0.3 ? -50 : 50;
  }

  final _last_dir = Vector2.zero();
}

mixin _KamikazeOnLeaving on EnemyEntity, CollisionCallbacks, TumbleOnExploding, SpawnExtrasOnExploding {
  CatmullRomSpline? _attack_path;

  RectangleHitbox? _hitbox;

  final _last_dir = Vector2.zero();

  bool self_destruct = false;

  @override
  void on_leaving(double dt) {
    on_active(dt);

    _hitbox ??= children.whereType<RectangleHitbox>().firstOrNull;
    _hitbox?.collisionType = CollisionType.active;

    if (leaving_time > 0.75) random_extras_count = 0;

    final pp = player.position;
    _attack_path ??= CatmullRomSpline([
      position.toOffset(),
      pp.y < position.y ? position.toOffsetXY(50, 50) : position.toOffsetXY(50, -50),
      pp.y < position.y ? position.toOffsetXY(0, 80) : position.toOffsetXY(0, -80),
      pp.y < position.y ? position.toOffsetXY(-100, 100) : position.toOffsetXY(-100, -100),
      pp.y < position.y ? position.toOffsetXY(-200, 100) : position.toOffsetXY(-200, -100),
      player.position.toOffset(),
    ]);

    leaving_time += dt / 3;

    final i = Curves.easeInOut.transform(leaving_time.clamp(0, 1));
    final p = _attack_path!.transform(i);
    position.x = p.dx;
    position.y = p.dy;

    if (i > 0.01) {
      final pb = _attack_path!.transform(i - 0.01);
      _last_dir.setFrom(position);
      _last_dir.x -= pb.dx;
      _last_dir.y -= pb.dy;
      _last_dir.scale(10);

      rot_y = pi / 2 - atan2(_last_dir.y, _last_dir.x);
    }
    if (i < 0.1) rot_y = -1 + i * 10;

    if (leaving_time >= 0.95) {
      leaving_time = 0.95;
      mines.spawn(position)?.set_direction(_last_dir);
      on_destroyed(direction: _last_dir);
      self_destruct = true;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other.hasTrait<Friendly>() && state == EnemyState.leaving) {
      mines.spawn(position)?.set_direction(_last_dir);
      on_destroyed(direction: _last_dir);
      self_destruct = true;
    }
  }
}

extension on Vector2 {
  Offset toOffsetXY(double dx, double dy) => Offset(x + dx, y + dy);
}
