import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/player/deflector_shield.dart';
import 'package:voxone/game/player/plasma_gun.dart';
import 'package:voxone/game/player/player_state.dart';
import 'package:voxone/game/player/player_target.dart';
import 'package:voxone/game/shared/friendly_target.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/util/messaging.dart';

class HorizontalPlayer extends PositionComponent with HasContext, FriendlyTarget, PlayerTarget {
  late final StackedEntity _entity;

  static const _strafe_accel = 10.0;
  static const _max_strafe_speed = 4.0;
  static const _max_strafe = 150.0;

  double _strafe_speed = 0;
  double _strafe = 0;

  PlayerState _state = PlayerState.incoming;

  PlayerState get state => _state;

  set state(PlayerState value) {
    logInfo(value);
    _state = value;
  }

  Component? weapon;
  DeflectorShield? shield;

  double integrity = 1;

  @override
  bool get susceptible => true;

  @override
  void on_hit(double damage) {
    integrity -= damage / 50;
    if (integrity < 0) integrity = 0;
  }

  @override
  Future onLoad() async {
    super.onLoad();

    _entity = StackedEntity('entities/star_runner.png', 16, shadows);

    _entity.rot_x = -0.95;
    _entity.rot_y = 1.8;
    _entity.rot_z = -0.2;
    _entity.scale_x = 1.2;
    _entity.scale_y = 2.5;
    _entity.scale_z = 1.2;
    _entity.scale.setAll(0.3);
    _entity.size.setAll(256);
    position.setValues(100, 280);

    await add(_entity);

    size.setAll(256 * 0.3);

    await add(CircleHitbox(
      radius: 16,
      position: Vector2(-10, 2),
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    )
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    await add(CircleHitbox(
      radius: 8,
      position: Vector2(15, -5),
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    )
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    weapon = PlasmaGun();
    await add(weapon!);

    shield = DeflectorShield();
    await add(shield!);

    priority = 100;
  }

  double _incoming_time = 0;

  @override
  void update(double dt) {
    switch (state) {
      case PlayerState.incoming:
        _on_incoming(dt);

      case PlayerState.playing:
        _update_rotate(dt);
        _update_strafe(dt);

      case PlayerState.exploding:
        break;

      case PlayerState.destroyed:
        break;
    }
  }

  void _on_incoming(double dt) {
    _incoming_time += dt * 2 / 3;
    if (_incoming_time >= 1) {
      _incoming_time = 1;
      state = PlayerState.playing;
      sendMessage(PlayerReady());
    }
    _entity.scale.setAll(0.3);
    _entity.size.setAll(256);

    final i = Curves.easeOut.transform(_incoming_time);
    position.setValues(-50 + 150 * i, 280 + 50 - 50 * i);
  }

  double _rot = 0;
  double _rot_sign = 1;

  void _update_rotate(double dt) {
    if (keys.fire2 && _rot == 0) {
      _rot = pi * 2;
      _rot_sign = -_strafe_speed.sign;
      if (_rot_sign == 0) _rot = 0;
    }

    if (_rot > 0) {
      _rot -= pi * 2 * dt;
      if (_rot <= 0) _rot = 0;
    }

    _entity.rot_z = -0.2 + _rot * _rot_sign;
  }

  void _update_strafe(double dt) {
    double max_strafe_speed = (_max_strafe - _strafe.abs()) / 5;

    if (keys.left && _strafe > -_max_strafe) {
      if (_strafe_speed > 0) _strafe_speed /= 1.5;
      _strafe_speed -= _strafe_accel * dt;
      if (_strafe < -_max_strafe / 2) {
        _strafe_speed = min(_strafe_speed.abs(), max_strafe_speed) * _strafe_speed.sign;
      }
    } else if (keys.right && _strafe < _max_strafe) {
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
      _strafe_speed = 0;
    }

    _strafe += _strafe_speed;
    if (_strafe.abs() > _max_strafe) {
      _strafe_speed = 0;
      _strafe = _max_strafe * _strafe.sign;
    }

    _entity.rot_x = -0.95 - _strafe_speed / 10;
    position.setValues(100 + _strafe / 4, 280 + _strafe);
  }
}
