import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/ranger_laser.dart';

class WarpingRanger extends MarauderEntity
    with WarpInOnIncoming, FloatOnActive, PlantMineOnSweeping, SweepOutOnLeaving, TumbleOnExploding {
  @override
  createEntity() async {
    can_sweep = true;

    reset_hit_points_to(10);

    size.setAll(128);

    entity = StackedEntity('entities/red_fighter.png', 22, shadows);
    entity.size.setAll(200);
    entity.rot_x = -pi / 8;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8;
    entity.scale_x = 1.2;
    entity.scale_y = 3.5;
    entity.scale_z = 1.2;

    await entity.add(EnemyHealthBar(this));

    await add(entity);

    await add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    await add(RangerLaser(this));
  }
}
