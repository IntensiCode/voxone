import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage1/marauder.dart';

class CapitalShip extends MarauderEntity
    with
        HasTraits,
        WarpInOnIncoming,
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

    await entity.add(EnemyHealthBar(this));

    await add(entity);

    // await add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)
    //   ..paint.color = red
    //   ..opacity = 0.2
    //   ..renderShape = debug);
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

mixin _VibrateOnIncoming {}

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
