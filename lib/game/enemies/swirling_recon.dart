import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/vox.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/marauder_mines.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/voxel/vox_io.dart';

class SwirlingRecon extends EnemyEntity
    with
        _CreateMicroReconEntity,
        HasVisibility,
        DelayOnIncoming,
        _MoveAlongPathOnActive,
        NopOnSweeping,
        NopOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {
  //
  static int _count = 0;

  SwirlingRecon(super.wave) : _which_path = (_count++).isEven {
    go_down_on_exploding = true;
  }

  final bool _which_path;

  static Future preload() async {
    final voxels = _CreateMicroReconEntity._voxels ??= await vox('ultraviolet_intruder.vx');
    _CreateMicroReconEntity._image ??= vox_to_image_ext(voxels);
  }

  @override
  CatmullRomSpline get chosen_path => _which_path ? _MoveAlongPathOnActive._path1 : _MoveAlongPathOnActive._path2;
}

mixin _CreateMicroReconEntity on EnemyEntity {
  static Voxels? _voxels;
  static Image? _image;

  @override
  void createEntity() {
    reset_hit_points_to(10);

    anchor = Anchor.center;
    size.setAll(40);

    set_image_source(_image!, _voxels!.height);

    rot_x = -pi / 8;
    rot_y = -pi / 2 + pi / 8;
    rot_z = -pi / 8;
    scale_x = 1.2;
    scale_y = 3.5;
    scale_z = 1.2;

    add(EnemyHealthBar(this));
    added(CircleHitbox(anchor: Anchor.center, isSolid: true)..anchor_to_parent());
  }

  @override
  void onMount() {
    super.onMount();
    shadows.add(create_linked_shadow());
  }
}

Offset _o(double x, double y) => Offset(x * game_width, y * game_height);

mixin _MoveAlongPathOnActive on EnemyEntity {
  static final CatmullRomSpline _path1 = CatmullRomSpline([
    _o(1.1, 0.10),
    _o(1.0, 0.225),
    _o(0.9, 0.35),
    _o(0.7, 0.475),
    _o(0.5, 0.45),
    _o(0.3, 0.25),
    _o(0.1, 0.0),
    _o(-0.1, -0.25),
  ]);

  static final CatmullRomSpline _path2 = CatmullRomSpline([
    _o(1.1, 0.70),
    _o(1.0, 0.625),
    _o(0.9, 0.55),
    _o(0.7, 0.475),
    _o(0.5, 0.55),
    _o(0.3, 0.75),
    _o(0.1, 1.0),
    _o(-0.1, 1.25),
  ]);

  CatmullRomSpline get chosen_path;

  @override
  void on_active(double dt) {
    active_time = (active_time + dt / 6).clamp(0, 1);
    if (active_time >= 1) {
      state = EnemyState.left;
      return;
    }

    final p = chosen_path.transform(active_time);
    position.x = p.dx;
    position.y = p.dy;

    if (active_time > 0.01 && active_time < 0.99) {
      final prev = chosen_path.transform(active_time - 0.01);
      _prev_dir.setFrom(position);
      _prev_dir.x -= prev.dx;
      _prev_dir.y -= prev.dy;
      _prev_dir.scale(10);

      final next = chosen_path.transform(active_time + 0.01);
      _next_dir.setValues(next.dx, next.dy);
      _next_dir.x -= position.x;
      _next_dir.y -= position.y;
      _next_dir.scale(10);

      target_dir.setFrom(_next_dir);
      target_dir.add(_prev_dir);
      target_dir.scale(0.5);

      _target_ry = pi / 2 - atan2(target_dir.y, target_dir.x);
      _target_ry %= 2 * pi;

      // var d = atan2(_next_dir.y, _next_dir.x) - atan2(_prev_dir.y, _prev_dir.x);
      // _target_rz = (d * 8 - pi / 8 + pi / 8) / 3;
      // _target_rz %= 2 * pi;

      final dir = chosen_path == _path1 ? 1 : -1;
      _target_rz = active_time * 2 * pi * 2 * dir;
    }

    final ry = _safe_angle(_target_ry, rot_y);
    rot_y = lerpDouble(ry, _target_ry, 10 * dt) ?? ry;

    final rz = _safe_angle(_target_rz, rot_z);
    rot_z = lerpDouble(rz, _target_rz, 2 * dt) ?? rz;

    _plant_time ??= 0.4 + rng.nextDoubleLimit(0.2);
    if (active_time > _plant_time! && !mine_planted) {
      mine_planted = true;
      mines.spawn3d(this)?.set_direction(target_dir);
    }
  }

  double? _plant_time;

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
