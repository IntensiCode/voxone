import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/enemy_explosion.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/ranger_laser.dart';
import 'package:voxone/game/stage1/satellite_marauder.dart';
import 'package:voxone/util/extensions.dart';

class CapitalShip extends MarauderEntity
    with
        HasTraits,
        _CreateCapitalShipEntity,
        _VibrateOnIncoming,
        AddShieldAfterOnIncoming,
        _LoseShieldWhenGeneratorDestroyed,
        _MaintainSatellitesOnActive,
        NopOnSweeping,
        NopOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {
  //
  @override
  String get shield_shader => 'hex_shield.frag';

  @override
  void createEntity() {
    super.createEntity();
    add(RangerLaser(this, offset: Vector2(-113, -3), damage: 0.4, cool_down: 2.8)..priority = 10);
    add(RangerLaser(this, offset: Vector2(-60, 68), damage: 0.4, cool_down: 2.8)..priority = 10);
    add(RangerLaser(this, offset: Vector2(-10, 4), damage: 0.4)..priority = 10);
  }

  @override
  void shield_added() {
    super.shield_added();
    shield.size.setFrom(entity.size);
    shield.auto_recharge = 0.05;
    shield.auto_recharge = dev ? 0.01 : 0.05;
    shield.max_rotate_time = 360;
    indicator.scale.setAll(0.25);
    indicator.position.setValues(0, -16);

    sendMessage(ShowInfoText(title: 'The End For Now', text: 'Work In Progress'));
  }
}

mixin _CreateCapitalShipEntity on MarauderEntity {
  late CircleHitbox center_mass;

  @override
  createEntity() async {
    reset_hit_points_to(dev ? 25 : 500);
    reset_hit_points_to(500);

    size.setAll(220);

    entity = StackedEntity('entities/dual_striker.png', 16, shadows);
    entity.size.setFrom(size);
    entity.size.scale(1.25);

    entity.rot_x = -pi / 4;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = pi / 16;
    entity.scale_x = 1.4;
    entity.scale_y = 4.5;
    entity.scale_z = 1.4;

    await entity.add(EnemyHealthBar(this)..scale.setAll(0.25));

    await add(entity);

    await add(center_mass = CircleHitbox.relative(
      0.25,
      parentSize: size,
      position: Vector2(0, -10),
      collisionType: CollisionType.passive,
      anchor: Anchor.center,
    )
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    await add(CircleHitbox.relative(
      0.25,
      parentSize: size,
      position: Vector2(-80, -20),
      collisionType: CollisionType.passive,
      anchor: Anchor.center,
    )
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    await add(CircleHitbox.relative(
      0.25,
      parentSize: size,
      position: Vector2(-30, 50),
      collisionType: CollisionType.passive,
      anchor: Anchor.center,
    )
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);
  }
}

mixin _VibrateOnIncoming on MarauderEntity {
  Vector2? _cam_base;

  bool _vibrating = false;

  @override
  void on_incoming(double dt) {
    incoming_time += dev ? dt : dt / 9;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = MarauderState.active;
    }
    if (!_vibrating && !dev) {
      _vibrating = true;
      audio.play(Sound.incoming);
    }

    final i = Curves.decelerate.transform(incoming_time);

    position.setFrom(target_position);
    position.x += 550;
    position.x -= 550 * i;
    position.y -= 550 / 4;
    position.y += 550 / 4 * i;

    final cam_pos = game.camera.viewport.position;
    _cam_base ??= cam_pos.clone();

    final strength = (1 - incoming_time) * 3;
    cam_pos.setFrom(_cam_base!);
    cam_pos.x += sin(incoming_time * 2300.527) * strength;
    cam_pos.y += cos(incoming_time * 930.182) * strength;
  }
}

mixin _LoseShieldWhenGeneratorDestroyed on _CreateCapitalShipEntity, AddShieldAfterOnIncoming {
  final _nop = <Vector2>{};

  // double _generator_hit_points = dev ? 3 : 150;
  double _generator_hit_points = 150;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    final center_hit = (intersections ?? _nop).any(center_mass.containsPoint);
    if (state == MarauderState.active && center_hit && _generator_hit_points > 0) {
      _generator_hit_points = max(0, _generator_hit_points - damage);
      if (_generator_hit_points <= 0) {
        logInfo('Shield generator destroyed');
        shield.removeFromParent();
        indicator.removeFromParent();
        entity.add(EnemyExplosion()..scale.setAll(0.2));
      }
    }

    super.on_hit(intersections: intersections, damage: center_hit ? damage * 2.5 : damage);
  }
}

mixin _MaintainSatellitesOnActive on MarauderEntity, HasTraits {
  static const _satellite_count = 6;

  int _waves = 10;

  final _satellites = <MarauderEntity>[];

  @override
  void on_active(double dt) {
    _satellites.forEach((it) {
      if (it.state == MarauderState.left || it.state == MarauderState.defeated) {
        it.removeFromParent();
      }
    });
    _satellites.removeWhere((it) => it.state == MarauderState.left);
    _satellites.removeWhere((it) => it.state == MarauderState.defeated);

    if (_satellites.isNotEmpty || _waves <= 0) return;

    final target = Vector2.zero();
    _satellite_count.forEach((index) {
      final angle = pi / 4 - pi / 2 * index / _satellite_count;
      target.setValues(-200 * cos(angle) - index * 10, 30 + 130 * sin(angle));
      target.add(position);

      final satellite = SatelliteMarauder();
      satellite.target_position.setFrom(target);
      satellite.init_formation(position, index / _satellite_count, index * 2 - 5);

      _satellites.add(satellite);
      stage.add(satellite);
    });

    _waves--;
  }

  @override
  void on_destroyed() {
    super.on_destroyed();
    _satellites.forEach((it) => it.on_destroyed());
  }
}
