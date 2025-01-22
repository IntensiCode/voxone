import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/ranger_laser.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/util/extensions.dart';

mixin CreateRangerEntity on EnemyEntity {
  @override
  createEntity() {
    can_sweep = true;

    reset_hit_points_to(10);

    size.setAll(48);

    set_sprite_source(atlas.sprite('entities/red_fighter.png'), 22);
    rot_x = -pi / 8;
    rot_y = -pi / 2 + pi / 8;
    rot_z = -pi / 8;
    scale_x = 1.2;
    scale_y = 3.5;
    scale_z = 1.2;

    add(EnemyHealthBar(this));
    add(CircleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center, isSolid: true)..anchor_to_parent());
    init_laser(added(laser = RangerLaser(this)
      ..anchor = Anchor.center
      ..anchor_to_parent()));
  }

  void init_laser(RangerLaser it) {}

  RangerLaser? laser;
}
