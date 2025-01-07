import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/stage1/marauder.dart';

class CapitalShip extends MarauderEntity
    with
        HasTraits,
        _VibrateOnIncoming,
        AddShieldAfterOnIncoming,
        _MaintainSatellitesOnActive,
        NopOnSweeping,
        NopOnLeaving,
        TumbleOnExploding {
  //
  @override
  String get shader_name => 'hex_shield.frag';

  @override
  createEntity() async {
    reset_hit_points_to(150);

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

    await add(CircleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);
  }

  @override
  void shield_added() {
    super.shield_added();
    shield.size.setFrom(entity.size);
    shield.auto_recharge = 0.05;
    shield.max_rotate_time = 360;
    indicator.scale.setAll(0.25);
    indicator.position.setValues(0, -16);
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
      soundboard.play(Sound.incoming);
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

mixin _LoseShieldWhenGeneratorDestroyed {}

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
