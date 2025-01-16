import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage1/homing_launcher.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/game/stage1/ranger_laser.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';

class MarauderCaptain extends MarauderEntity
    with
        HasTraits,
        _CreateMarauderCaptainEntity,
        WarpInOnIncoming,
        AddShieldAfterOnIncoming,
        FloatOnActive,
        _ReleaseMinesWhenInDanger,
        NopOnSweeping,
        NopOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {
  MarauderCaptain(super._wave, {this.homing = true});

  @override
  final bool homing;

  @override
  void createEntity() {
    super.createEntity();
    final secondary = [ExtraId.plasma_ring, ExtraId.cluster_bomb, ExtraId.nuke_missile, ExtraId.smart_bomb].random(rng);
    required_extras = {ExtraId.phosphor_swirl, ExtraId.ion_pulse, secondary, ExtraId.triple_plasma};
    random_extras_count = 1;
  }

  @override
  void shield_added() {
    super.shield_added();
    shield.scale.setAll(6);
    indicator.position.setValues(0, -64);
  }
}

mixin _CreateMarauderCaptainEntity on MarauderEntity {
  bool get homing;

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
    await add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)..debug());
    await add(RangerLaser(this)..damage = 0.3);

    if (homing) await add(HomingLauncher(this));
  }
}

mixin _ReleaseMinesWhenInDanger on AddShieldAfterOnIncoming {
  bool get _last_remaining => stage.children.whereType<Marauder>().singleOrNull == this;

  bool get _shield_low => shield.energy < 0.25;

  double _mine_spawn_time = 0;

  @override
  void on_active(double dt) {
    super.on_active(dt);
    if (player.is_dead_or_dying()) return;
    if (_last_remaining || _shield_low) _on_release_mine(dt);
  }

  void _on_release_mine(double dt) {
    if (_mine_spawn_time <= 0) {
      _mine_spawn_time = 2;
      mines.spawn(position, drift: rng.nextDoublePM(40));
    } else {
      _mine_spawn_time -= dt;
    }
  }
}
