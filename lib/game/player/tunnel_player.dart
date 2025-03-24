import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/game_phase.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/player_state.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/shared/voxel_entity.dart';
import 'package:voxone/util/auto_dispose.dart';

class TunnelPlayer extends VoxelEntity
    with AutoDispose, HasContext, HasTraits, Player, Target, _CreateEntityOnLoad, _TunnelStrafe
    implements Friendly {
  @override
  PlayerState state = PlayerState.playing;

  @override
  double get cooldown_boost => throw UnimplementedError();

  @override
  double get integrity => throw UnimplementedError();

  @override
  double get integrity_boost => throw UnimplementedError();

  @override
  double get shield_boost => throw UnimplementedError();

  @override
  bool get susceptible => stage.phase == GamePhase.playing;

  @override
  bool get show_indicator => false;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {}

  @override
  void on_collect_extra(ExtraId which) {}

  @override
  void update(double dt) {
    super.update(dt);
    update_strafe(dt);
  }

  @override
  void set_strafe(double tilt, double move_offset) {
    position.setValues(game_width / 2 + move_offset, 400);
    rot_x = 0;
    rot_y = pi;
    rot_z = 0;
    rot_z = 0; // tilt / 4;
    shift_x = move_offset / 100000;
    shift_y = 0.005;
    shift_z = 0.005;
  }
}

mixin _CreateEntityOnLoad on VoxelEntity, HasContext, HasTraits, Player, Target {
  static const _size = 160.0;

  @override
  void onRemove() {
    super.onRemove();
    dispose_sprite();
  }

  @override
  Future onLoad() async {
    set_sprite_source(atlas.sprite('entities/ZaxxonPlayer-15.png'), 15);
    shadows.add(create_linked_shadow());
    super.onLoad();
    cache_render = false; // to make shift work without rotate
    force_render = true;
    rot_x = -0.95;
    rot_y = 1.8;
    rot_z = -0.2;
    scale_x = 1.2;
    scale_y = 2.2;
    scale_z = 1.2;
    size.setAll(_size);
    position.setValues(100, 280);
    fake_height = 50;
  }
}

mixin _TunnelStrafe on HasContext {
  static const _strafe_accel = 22.5;
  static const _max_strafe_speed = 12.0;
  static const _max_strafe = 250.0;

  double _strafe_speed = 0;
  double _strafe = 0;

  void update_strafe(double dt) {
    if (dev && dt.abs() < 0.0125) dt = 0.0125 * dt.sign;

    double max_strafe_speed = (_max_strafe - _strafe.abs()) / 5;

    final left = keys.left;
    final right = keys.right;
    if (left && _strafe > -_max_strafe) {
      if (_strafe_speed > 0) _strafe_speed /= 1.5;
      _strafe_speed -= _strafe_accel * dt;
      if (_strafe < -_max_strafe / 2) {
        _strafe_speed = min(_strafe_speed.abs(), max_strafe_speed) * _strafe_speed.sign;
      }
    } else if (right && _strafe < _max_strafe) {
      if (_strafe_speed < 0) _strafe_speed /= 1.5;
      _strafe_speed += _strafe_accel * dt;
      if (_strafe > _max_strafe / 2) {
        _strafe_speed = min(_strafe_speed.abs(), max_strafe_speed) * _strafe_speed.sign;
      }
    } else {
      _strafe_speed /= 1.05;
    }

    if (_strafe_speed.abs() > _max_strafe_speed) {
      _strafe_speed = _max_strafe_speed * _strafe_speed.sign;
    } else if (_strafe_speed.abs() < 0.1) {
      // _strafe_speed = 0;
    }

    _strafe += _strafe_speed;
    if (_strafe.abs() > _max_strafe) {
      // _strafe_speed = 0;
      _strafe = _max_strafe * _strafe.sign;
    }

    set_strafe(_strafe_speed, _strafe);
  }

  void set_strafe(double tilt, double move_offset) {}
}
