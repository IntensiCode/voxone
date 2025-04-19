import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/animation.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/core/traits.dart';
import 'package:stardash/game/enemies/enemy.dart';
import 'package:stardash/game/enemies/homing_launcher.dart';
import 'package:stardash/game/enemies/marauder_mines.dart';
import 'package:stardash/game/enemies/ranger_laser.dart';
import 'package:stardash/game/enemies/satellite_marauder.dart';
import 'package:stardash/game/shared/decals.dart';
import 'package:stardash/game/shared/difficulty.dart';
import 'package:stardash/game/shared/enemy_explosion.dart';
import 'package:stardash/game/shared/enemy_health_bar.dart';
import 'package:stardash/game/shared/enemy_hit_points.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/messages.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/random.dart';

Vector2 _v(double x, double y) => Vector2(x, y);

class CapitalShip extends EnemyEntity
    with
        HasTraits,
        _CreateCapitalShipEntity,
        _VibrateOnIncoming,
        AddShieldAfterOnIncoming,
        _LoseShieldWhenGeneratorDestroyed,
        _FloatOnActive,
        _MaintainSatellitesOnActive,
        NopOnSweeping,
        NopOnLeaving,
        _MultipleExplosionsOnExploding,
        _ReleaseMinesOnActive,
        SpawnExtrasOnExploding {
  CapitalShip(super.wave);

  @override
  String get shield_shader => 'hex_shield.frag';

  @override
  void createEntity() {
    super.createEntity();
    active_time_limit = 0;
    add(HomingLauncher(this));
    add(RangerLaser(this, offset: _v(-144, -4), damage: 0.4, cool_down: 2.8)
      ..priority = 10
      ..anchor = Anchor.center
      ..anchor_to_parent());
    add(RangerLaser(this, offset: _v(-80, 82), damage: 0.4, cool_down: 2.8)
      ..priority = 10
      ..anchor = Anchor.center
      ..anchor_to_parent());
    add(RangerLaser(this, offset: _v(-10, 4), damage: 0.4)
      ..priority = 10
      ..anchor = Anchor.center
      ..anchor_to_parent());
    random_extras_count = 5;
    required_extras = {ExtraId.smart_bomb, ExtraId.phosphor_swirl, ExtraId.nuke_missile};
  }

  @override
  void shield_added() {
    super.shield_added();
    shield.shield.shield_boost = 3;
    shield.auto_recharge = switch (difficulty) {
      Difficulty.easy => 0.225,
      Difficulty.normal => 0.28,
      Difficulty.hard => 0.29,
    };
    shield.max_rotate_time = 360;
  }
}

mixin _CreateCapitalShipEntity on EnemyEntity {
  late CircleHitbox center_mass;

  @override
  void createEntity() {
    reset_hit_points_to(switch (difficulty) {
      Difficulty.easy => 1250,
      Difficulty.normal => 2500,
      Difficulty.hard => 4000,
    });

    set_sprite_source(atlas.sprite('entities/dual_striker.png'), 16);

    size.setAll(350);

    force_render = true;

    rot_x = -pi / 4;
    rot_y = -pi / 2 + pi / 8;
    rot_z = pi / 16;
    scale_x = 1.4;
    scale_y = 4.5;
    scale_z = 1.4;

    add(EnemyHealthBar(this)..position.y += 32);

    add(center_mass = CircleHitbox.relative(
      0.3,
      parentSize: size,
      position: _v(0, -10),
      isSolid: true,
      collisionType: CollisionType.passive,
      anchor: Anchor.center,
    )..anchor_to_parent());

    add(CircleHitbox.relative(
      0.25,
      parentSize: size,
      position: _v(-100, -30),
      isSolid: true,
      collisionType: CollisionType.passive,
      anchor: Anchor.center,
    )..anchor_to_parent());

    add(CircleHitbox.relative(
      0.25,
      parentSize: size,
      position: _v(-30, 60),
      isSolid: true,
      collisionType: CollisionType.passive,
      anchor: Anchor.center,
    )..anchor_to_parent());
  }
}

mixin _VibrateOnIncoming on EnemyEntity {
  Vector2? _cam_base;

  bool _vibrating = false;

  @override
  void on_incoming(double dt) {
    incoming_time += dev ? dt : dt / 9;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = EnemyState.active;
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

  @override
  void onRemove() {
    super.onRemove();
    if (_cam_base != null) {
      game.camera.viewport.position.setFrom(_cam_base!);
    }
  }
}

mixin _LoseShieldWhenGeneratorDestroyed on _CreateCapitalShipEntity, AddShieldAfterOnIncoming {
  final _nop = <Vector2>{};

  late double _generator_hit_points = switch (difficulty) {
    Difficulty.easy => 500,
    Difficulty.normal => 1000,
    Difficulty.hard => 1500,
  };

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    final center_hit = (intersections ?? _nop).any(center_mass.containsPoint);
    if (state == EnemyState.active && center_hit && _generator_hit_points > 0) {
      _generator_hit_points = max(0, _generator_hit_points - damage);
      if (_generator_hit_points <= 0) {
        sendMessage(ShowInfoText(text: 'Shield Generator Destroyed', title: 'Critical Hit'));
        audio.play_one_shot_sample('voice/shield_generator_destroyed.ogg', volume_factor: 2);
        shield.removeFromParent();
        indicator.removeFromParent();
        add(explosions.spawn(this)..scale.setAll(0.5));
      }
    }

    super.on_hit(intersections: intersections, damage: center_hit ? damage * 2.5 : damage);
  }
}

mixin _FloatOnActive on EnemyEntity {
  @override
  void on_active(double dt) {
    active_time += dt * 3;
    position.setFrom(target_position);
    position.x += sin(active_time / 1.2345) * 10;
    position.y += sin(active_time) * 10;
    fake_height = 25;
  }
}

mixin _MaintainSatellitesOnActive on EnemyEntity, HasTraits {
  static const _satellite_count = 6;

  int _waves = 10;

  final _satellites = <SatelliteMarauder>[];

  @override
  void on_active(double dt) {
    super.on_active(dt);

    if (player.is_dead_or_dying()) return;

    for (final it in _satellites) {
      if (it.state == EnemyState.left || it.state == EnemyState.defeated) {
        it.removeFromParent();
      }
    }

    if (_satellites.isNotEmpty && _satellites.every((it) => it.isRemoved)) {
      if (_satellites.every((it) => it.state == EnemyState.defeated)) {
        if (_satellites.none((it) => it.self_destruct)) {
          _satellites.random(rng).spawn_bonus();
        }
      }
      _satellites.clear();
    }

    if (_satellites.isNotEmpty || _waves <= 0) return;

    final target = Vector2.zero();
    for (var index = 0; index < _satellite_count; index++) {
      final angle = pi / 4 - pi / 2 * index / _satellite_count;
      target.setValues(-200 * cos(angle) - index * 10, 30 + 130 * sin(angle));
      target.add(position);

      final satellite = SatelliteMarauder(wave);
      satellite.target_position.setFrom(target);
      satellite.init_formation(position, index / _satellite_count, index * 2 - 5);

      _satellites.add(satellite);
      stage.add(satellite);
    }

    _waves--;
  }

  @override
  void on_destroyed({Vector2? direction}) {
    super.on_destroyed(direction: direction);
    tumble_dir.setValues(-10, 10 / 4);
    stage.children
        .whereType<Hostile>()
        .whereType<EnemyHitPoints>()
        .filterNot((it) => it == this)
        .forEach((it) => it.on_destroyed());
  }
}

mixin _MultipleExplosionsOnExploding on EnemyEntity {
  double _add_explosion_time = 0;
  int _sound_trigger = 5;

  final _tmp = Vector2.zero();

  @override
  void on_exploding(double dt) {
    if (tumble_dir.isZero()) tumble_dir.setValues(-10, 10 / 4);

    leaving_time += dt / 1.5;
    if (leaving_time >= 2) {
      leaving_time = 2;
      state = EnemyState.defeated;
    }

    _tmp.setFrom(position);
    _tmp.x += rng.nextDoublePM(100);
    _tmp.y += rng.nextDoublePM(100);
    decals.spawn3d(Decal.smoke, this, pos_override: _tmp);

    _add_explosion_time += dt;
    if (_add_explosion_time > 0.1) {
      _add_explosion_time -= 0.1;

      final it = decals.spawn3d(Decal.nuke_explosion, this);
      it.position.x += rng.nextDoublePM(100);
      it.position.y += rng.nextDoublePM(100);

      if (leaving_time < 1 && --_sound_trigger <= 0) {
        audio.play(Sound.explosion);
        _sound_trigger = 5;
      }
    }

    position.x += dt * tumble_dir.x;
    position.y += dt * tumble_dir.y;

    opacity = leaving_time < 1 ? 1 - leaving_time / 2 : 0;
  }
}

mixin _ReleaseMinesOnActive on EnemyEntity {
  double _mine_spawn_time = 0;

  @override
  void on_active(double dt) {
    super.on_active(dt);
    if (player.is_dead_or_dying()) return;

    if (_mine_spawn_time <= 0) {
      _mine_spawn_time = 3;
      mines.spawn(position, drift: rng.nextDoublePM(40));
    } else {
      _mine_spawn_time -= dt;
    }
  }
}
