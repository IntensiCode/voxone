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
  double _generator_hit_points = dev ? 3 : 150;

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
  final _satellites = <MarauderEntity>[];

  @override
  void on_active(double dt) {
    // if (_satellites.isEmpty) {
    //   final satellite = Marauder();
    //   satellite.target = target;
    //   satellite.target_position = target_position;
    //   satellite.position.setFrom(position);
    //   satellite.position.x += 100;
    //   satellite.position.y += 100;
    //   satellite.position.z += 100;
    //   satellite.addTrait(Hostile());
    //   _satellites.add(satellite);
    //   add(satellite);
    // }
  }
}
