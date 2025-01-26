import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/homing_launcher.dart';
import 'package:voxone/game/enemies/marauder_mines.dart';
import 'package:voxone/game/enemies/ranger_laser.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';

class MarauderCaptain extends EnemyEntity
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
    random_extras_count = 3;
    active_time_limit = 0;
  }

  @override
  void shield_added() {
    super.shield_added();
    shield.shield.shield_boost = switch (difficulty) {
      Difficulty.easy => 1.0,
      Difficulty.normal => 1.05,
      Difficulty.hard => 1.1,
    };
    shield.auto_recharge = switch (difficulty) {
      Difficulty.easy => 0.10,
      Difficulty.normal => 0.14,
      Difficulty.hard => 0.18,
    };
    indicator.position.setValues(0, -16);
  }
}

mixin _CreateMarauderCaptainEntity on EnemyEntity {
  bool get homing;

  @override
  void createEntity() {
    reset_hit_points_to(switch (difficulty) {
      Difficulty.easy => 100,
      Difficulty.normal => 175,
      Difficulty.hard => 250,
    });

    set_sprite_source(atlas.sprite('entities/camo_stellar_jet.png'), 16);
    size.setAll(96);
    anchor = Anchor.center;

    force_render = true;

    rot_x = -pi / 8;
    rot_y = -pi / 2 + pi / 8;
    rot_z = -pi / 8;
    scale_x = 1.2;
    scale_y = 3.5;
    scale_z = 1.2;

    add(EnemyHealthBar(this));
    add(CircleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center, isSolid: true)..anchor_to_parent());
    add(RangerLaser(this)
      ..anchor = Anchor.center
      ..damage = 0.3
      ..anchor_to_parent());

    if (homing) add(HomingLauncher(this));
  }
}

mixin _ReleaseMinesWhenInDanger on AddShieldAfterOnIncoming, FloatOnActive {
  bool get _last_remaining => stage.children.whereType<Enemy>().singleOrNull == this;

  bool get _shield_low => shield.energy < 0.25;

  double _mine_spawn_time = 0;

  @override
  void on_active(double dt) {
    super.on_active(dt);
    if (player.is_dead_or_dying()) return;
    if (_last_remaining || _shield_low) {
      _on_release_mine(dt);
      float_radius = min(50, float_radius + dt);
    } else {
      float_radius = max(10, float_radius - dt);
    }
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
