import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/ranger_laser.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/util/extensions.dart';

mixin CreateRangerEntity on EnemyEntity {
  @override
  createEntity() {
    can_sweep = true;

    reset_hit_points_to(10);

    size.setAll(150);
    scale.setAll(0.2);

    entity = StackedEntity('entities/red_fighter.png', 22, shadows);
    entity.size.setAll(225);
    entity.rot_x = -pi / 8;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8;
    entity.scale_x = 1.2;
    entity.scale_y = 3.5;
    entity.scale_z = 1.2;

    entity.add(EnemyHealthBar(this));
    add(entity);
    add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)..debug());
    init_laser(added(laser = RangerLaser(this)));
  }

  void init_laser(RangerLaser it) {}

  RangerLaser? laser;
}
