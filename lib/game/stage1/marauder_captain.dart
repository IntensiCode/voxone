import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/util/random.dart';

class MarauderCaptain extends MarauderEntity
    with
        HasTraits,
        CreateMarauderEntity,
        WarpInOnIncoming,
        _AddShieldAfterOnIncoming,
        FloatOnActive,
        _SpamMinesWhenAlone,
        NopOnSweeping,
        NopOnLeaving,
        TumbleOnExploding {
  //
  @override
  createEntity() async {
    reset_hit_points_to(40);

    size.setAll(256);

    entity = StackedEntity('entities/camo_stellar_jet.png', 16, shadows);
    entity.size.setAll(512);

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
  }
}

mixin _AddShieldAfterOnIncoming on MarauderEntity, HasTraits {
  @override
  void on_incoming(double dt) {
    super.on_incoming(dt);

    if (incoming_time < 1) return;

    final shield = DeflectorShield(this);
    shield.scale.setAll(6);
    shield.auto_recharge = null;
    shield.addTrait(Hostile());
    add(shield);
    addTrait(shield);
  }
}

mixin _SpamMinesWhenAlone on MarauderEntity {
  bool get _last_remaining => stage.children.whereType<Marauder>().singleOrNull == this;

  double _mine_spawn_time = 0;

  @override
  void on_active(double dt) {
    super.on_active(dt);

    if (!_last_remaining) return;

    if (_mine_spawn_time <= 0) {
      _mine_spawn_time = 0.5;
      mines.spawn(position).then((it) => it.drift = rng.nextDoublePM(40));
    } else {
      _mine_spawn_time -= dt;
    }
  }
}
