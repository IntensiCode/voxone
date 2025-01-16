import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/enemies/marauder.dart';
import 'package:voxone/game/enemies/marauder_mines.dart';

class CirclingMarauder extends MarauderEntity
    with
        CreateMarauderEntity,
        HasVisibility,
        DelayOnIncoming,
        HasTraits,
        AddShieldAfterOnIncoming,
        _MoveAlongPathOnActive,
        NopOnSweeping,
        NopOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {
  CirclingMarauder(super.wave);

  @override
  void createEntity() {
    super.createEntity();
    scale.setAll(0.2);
    reset_hit_points_to(15);
  }

  @override
  void shield_added() {
    super.shield_added();
    shield.auto_recharge = 0.01;
    shield.shield.shield_boost = 0.25;
    shield.scale.setAll(6);
    indicator.position.setValues(0, -64);
  }
}

Offset _o(double x, double y) => Offset(x * game_width, y * game_height);

mixin _MoveAlongPathOnActive on MarauderEntity {
  static CatmullRomSpline? _path;

  @override
  void on_active(double dt) {
    _path ??= CatmullRomSpline([
      _o(0.9, -0.1),
      _o(0.5, 0.1),
      _o(0.35, 0.25),
      _o(0.3, 0.5),
      _o(0.35, 0.75),
      _o(0.5, 0.9),
      _o(0.65, 0.75),
      _o(0.7, 0.5),
      _o(0.65, 0.25),
      _o(0.5, 0.1),
      _o(0.35, 0.25),
      _o(0.3, 0.5),
      _o(0.35, 0.75),
      _o(0.5, 0.9),
      _o(0.65, 0.75),
      _o(0.7, 0.5),
      _o(0.65, 0.25),
      _o(0.5, 0.1),
      _o(0.3, -0.1),
    ]);

    active_time = (active_time + dt / 10).clamp(0, 1);
    if (active_time >= 1) {
      state = MarauderState.left;
      return;
    }

    final p = _path?.transform(active_time);
    if (p == null) {
      state = MarauderState.left;
      return;
    }

    position.x = p.dx;
    position.y = p.dy;

    if (active_time > 0.01 && active_time < 0.99) {
      final prev = _path!.transform(active_time - 0.01);
      _prev_dir.setFrom(position);
      _prev_dir.x -= prev.dx;
      _prev_dir.y -= prev.dy;
      _prev_dir.scale(10);

      final next = _path!.transform(active_time + 0.01);
      _next_dir.setValues(next.dx, next.dy);
      _next_dir.x -= position.x;
      _next_dir.y -= position.y;
      _next_dir.scale(10);

      target_dir.setFrom(_next_dir);
      target_dir.add(_prev_dir);
      target_dir.scale(0.5);

      _target_ry = pi / 2 - atan2(target_dir.y, target_dir.x);
      _target_ry %= 2 * pi;

      var d = atan2(_next_dir.y, _next_dir.x) - atan2(_prev_dir.y, _prev_dir.x);
      _target_rz = (d * 8 - pi / 8 + pi / 8) / 3;
      _target_rz %= 2 * pi;
    }

    final rot_y = _safe_angle(_target_ry, entity.rot_y);
    entity.rot_y = lerpDouble(rot_y, _target_ry, 10 * dt) ?? rot_y;

    final rot_z = _safe_angle(_target_rz, entity.rot_z);
    entity.rot_z = lerpDouble(rot_z, _target_rz, 2 * dt) ?? rot_z;

    _tmp.setFrom(player.position);
    _tmp.sub(position);
    _tmp.normalize();
    _tmp2.setFrom(target_dir);
    _tmp2.normalize();
    _tmp.sub(_tmp2);

    final trigger = _tmp.x.abs() < 0.01 && _tmp.y.abs() < 0.01;
    if (trigger && !mine_planted) {
      mine_planted = true;
      mines.spawn(position)?.set_direction(target_dir);
    }
  }

  final _tmp = Vector2.zero();
  final _tmp2 = Vector2.zero();

  double _safe_angle(double target, double current) {
    final dy = target - current;
    if (dy.abs() < pi) return current;
    return dy > 0 ? current + 2 * pi : current - 2 * pi;
  }

  double _target_ry = 0;
  double _target_rz = 0;

  final _prev_dir = Vector2.zero();
  final _next_dir = Vector2.zero();
  final target_dir = Vector2.zero();
}
