import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/context.dart';
import 'package:voxone/game/decals.dart';
import 'package:voxone/game/stacked_entity.dart';
import 'package:voxone/game/stacked_sprite.dart';
import 'package:voxone/game/stage1/enemy_explosion.dart';
import 'package:voxone/game/stage1/enemy_health_bar.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/marauder_gun.dart';
import 'package:voxone/game/stage1/marauder_hit_points.dart';

class WarpingMarauder extends PositionComponent with Context, Marauder, MarauderHitPoints {
  late final StackedEntity _entity;

  WarpingMarauder() {
    hit_points = 25;
    remaining = 25;
  }

  @override
  MarauderState state = MarauderState.incoming;

  bool get defeated => state == MarauderState.defeated || state == MarauderState.left;

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

    _entity = StackedEntity('entities/transstellar.png', 14, shadows);
    await _entity.add(MarauderHealthBar(this));
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

    await add(MarauderGun(this));
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
    }
    scale.setAll((1 - _incoming_time) * 0.5 + 0.2);
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(_incoming_time);
    position.setFrom(target_position);
    position.x += 350;
    position.x -= 350 * i;
  }

  void _on_active(double dt) {
    scale.setAll(sin(_active_time / 3) * 0.025 + 0.2);
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
      if (!dev) state = MarauderState.leaving;
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
