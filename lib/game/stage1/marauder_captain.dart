import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/enemy_explosion.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/stacked_sprite.dart';
import 'package:voxone/game/stage1/marauder.dart';

class MarauderCaptain extends PositionComponent with HasContext, HasPaint, Marauder, EnemyHitPoints {
  late final StackedEntity _entity;

  MarauderCaptain() {
    reset_hit_points_to(100);
  }

  @override
  MarauderState state = MarauderState.incoming;

  final target_position = Vector2.zero();

  @override
  bool get volatile => switch (state) {
        MarauderState.left => false,
        MarauderState.exploding => false,
        MarauderState.defeated => false,
        _ => _incoming_time > 0.9,
      };

  @override
  set highlight_mode(HighlightMode mode) => _entity.sprite.highlight_mode = mode;

  @override
  void on_destroyed() {
    if (state == MarauderState.exploding) return;
    state = MarauderState.exploding;
    _entity.add(EnemyExplosion());
  }

  @override
  void on_hit() {
    super.on_hit();
    decals.spawn(Decal.mini_explosion, position);
  }

  @override
  Future onLoad() async {
    super.onLoad();

    _entity = StackedEntity('entities/camo_stellar_jet.png', 16, shadows);
    await _entity.add(EnemyHealthBar(this));
    _entity.size.setAll(256);

    _entity.rot_x = -pi / 8;
    _entity.rot_y = -pi / 2 + pi / 8;
    _entity.rot_z = -pi / 8;
    _entity.scale_x = 1.2;
    _entity.scale_y = 3.5;
    _entity.scale_z = 1.2;
    position.setFrom(target_position);

    await add(_entity);

    size.setAll(180);
    await add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    // await add(MarauderGun(this));
  }

  double _incoming_time = 0;
  double _active_time = 0;
  double _leaving_time = 0;

  @override
  void update(double dt) {
    super.update(dt);

    switch (state) {
      case MarauderState.incoming:
        _on_incoming(dt);

      case MarauderState.active:
        _on_active(dt);

      case MarauderState.leaving:
        _on_leaving(dt);

      case MarauderState.left:
        removeFromParent();

      case MarauderState.exploding:
        _on_exploding(dt);

      case MarauderState.defeated:
        removeFromParent();

      case MarauderState.sweeping:
        throw 'does not sweep';
    }
  }

  bool _spawned = false;

  void _on_incoming(double dt) {
    _incoming_time += dt * 2 / 3;
    if (_incoming_time >= 1) {
      _incoming_time = 1;
      state = MarauderState.active;
      _entity.sprite.paint.imageFilter = null;
      _entity.sprite.paint.colorFilter = null;
    }
    scale.setAll(0.3);
    scale.x += 4 - _incoming_time * 4;
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(_incoming_time);
    position.setFrom(target_position);
    position.x += 550;
    position.x -= 550 * i;

    _entity.sprite.opacity = _incoming_time;

    _entity.sprite.paint.imageFilter = ImageFilter.blur(sigmaX: 32 * (1 - i), sigmaY: 32 * (1 - i));
    _entity.sprite.paint.colorFilter = ColorFilter.mode(Colors.white, BlendMode.modulate);
  }

  void _on_active(double dt) {
    scale.setAll(sin(_active_time / 3) * 0.025 + 0.3);
    priority = (scale.x * 1000).toInt();
    _entity.rot_x = -pi / 8 + sin(_active_time / 7) * 0.2;
    _entity.rot_y = -pi / 2 + pi / 8;
    _entity.rot_z = -pi / 8 + sin(_active_time) * 0.2;
    _active_time += dt * 3;
    position.setFrom(target_position);
    position.x += sin(_active_time / 1.2345) * 10;
    position.y += sin(_active_time) * 10;

    if (state != MarauderState.active) {
      return;
    } else if (_active_time > 120) {
      state = MarauderState.leaving;
      // if (!dev) state = MarauderState.leaving;
    }
  }

  void _on_leaving(double dt) {
    _on_active(dt);

    _leaving_time += dt;
    if (_leaving_time >= 2) {
      _leaving_time = 2;
      state = MarauderState.left;
    }

    scale.x += _leaving_time * 0.5;
    scale.y += _leaving_time * 0.5;
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(_leaving_time / 2);
    position.y -= 550 * i;
    position.x -= 550 * i / 4;
  }

  void _on_exploding(double dt) {
    _leaving_time += dt;
    if (_leaving_time >= 1) {
      if (!_spawned) extras.spawn(position);
      _spawned = true;
    }
    if (_leaving_time >= 2) {
      _leaving_time = 2;
      state = MarauderState.defeated;
    }

    _entity.rot_x += dt;
    _entity.rot_y += dt * 2;
    _entity.rot_z += dt * 0.5;
    position.x -= dt * 100;
    position.y += dt * 100 / 4;

    _entity.sprite.opacity = 1 - _leaving_time / 2;
  }
}
