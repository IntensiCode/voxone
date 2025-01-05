import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/enemy_explosion.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/stacked_sprite.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/marauder_gun.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/util/random.dart';

class SweepingMarauder extends PositionComponent with HasContext, Marauder, EnemyHitPoints {
  late final StackedEntity entity;

  SweepingMarauder() {
    reset_hit_points_to(25);
  }

  @override
  MarauderState state = MarauderState.incoming;

  final target_position = Vector2.zero();

  @override
  bool get susceptible => switch (state) {
        MarauderState.left => false,
        MarauderState.exploding => false,
        MarauderState.defeated => false,
        _ => incoming_time > 0.9,
      };

  @override
  set highlight_mode(HighlightMode mode) => entity.sprite.highlight_mode = mode;

  @override
  void on_destroyed() {
    if (state == MarauderState.exploding) return;
    state = MarauderState.exploding;
    entity.add(EnemyExplosion());
    if (_sweep_time > 0) can_sweep = true;
    soundboard.play(Sound.explosion);
    logInfo('play explosion');
  }

  @override
  Future onLoad() async {
    super.onLoad();

    entity = StackedEntity('entities/transstellar.png', 14, shadows);
    await entity.add(EnemyHealthBar(this));
    entity.size.setAll(256);

    entity.rot_x = -pi / 8;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8;
    entity.scale_x = 1.2;
    entity.scale_y = 3.5;
    entity.scale_z = 1.2;
    position.setFrom(target_position);

    await add(entity);

    size.setAll(180);
    await add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    await add(MarauderGun(this));
  }

  double incoming_time = 0;
  double _active_time = 0;
  double _leaving_time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    switch (state) {
      case MarauderState.incoming:
        on_incoming(dt);

      case MarauderState.active:
        _on_active(dt);

      case MarauderState.sweeping:
        _on_sweeping(dt);

      case MarauderState.leaving:
        _on_leaving(dt);

      case MarauderState.left:
        removeFromParent();

      case MarauderState.exploding:
        _on_exploding(dt);

      case MarauderState.defeated:
        removeFromParent();
    }
  }

  bool _spawned = false;

  void on_incoming(double dt) {
    incoming_time += dt * 2 / 3;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = MarauderState.active;
    }
    scale.setAll((1 - incoming_time) * 0.5 + 0.2);
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(incoming_time);
    position.setFrom(target_position);
    position.x += 350;
    position.x -= 350 * i;
  }

  void _on_active(double dt) {
    scale.setAll(sin(_active_time / 3) * 0.025 + 0.2);
    priority = (scale.x * 1000).toInt();
    entity.rot_x = -pi / 8 + sin(_active_time / 7) * 0.2;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8 + sin(_active_time) * 0.2;
    _active_time += dt * 3;
    position.setFrom(target_position);
    position.x += sin(_active_time / 1.2345) * 10;
    position.y += sin(_active_time) * 10;

    if (state != MarauderState.active) {
      return;
    } else if (_active_time > 120) {
      state = MarauderState.leaving;
    } else if (can_sweep && rng.nextDouble() < 0.2) {
      can_sweep = false;
      _sweep_time = 0;
      _sweep_dist = 300 - target_position.x;
      state = MarauderState.sweeping;
    }
  }

  static bool can_sweep = true;

  double _sweep_time = 0;
  double _sweep_dist = 0;
  bool _planted = false;

  void _on_sweeping(double dt) {
    _on_active(dt);

    _sweep_time += dt;
    if (_sweep_time >= 10) {
      can_sweep = true;
      _planted = false;
      _sweep_time = 0;
      state = MarauderState.active;
      return;
    }

    if (_sweep_time >= 5 && !_planted) {
      _planted = true;
      logInfo('plant mine');
      mines.spawn(position);
    }

    final t = Curves.easeInOutCubic.transform(_sweep_time / 10);
    final x = sin(t * pi) * _sweep_dist;
    position.x += x;
    scale.x += sin(t * pi) / 10;
    scale.y += sin(t * pi) / 10;
    priority = (scale.x * 1000).toInt();

    double mm = _sweep_time < 5 ? 0 : 0.5 + (_sweep_time - 5) / 10;
    double m = Curves.easeInOut.transform(mm);
    entity.rot_x -= sin(m * pi * 8 / 4) * pi / 4;
    entity.rot_y -= sin(m * pi * 8 / 4) * pi / 1;
    entity.rot_z += sin(m * pi * 8 / 4) * pi / 2;
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

    entity.rot_x += dt;
    entity.rot_y += dt * 2;
    entity.rot_z += dt * 0.5;
    position.x -= dt * 100;
    position.y += dt * 100 / 4;

    entity.sprite.opacity = 1 - _leaving_time / 2;
  }
}
