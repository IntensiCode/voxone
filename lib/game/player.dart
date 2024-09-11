import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/context.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/game/stacked_entity.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/particle_recycler.dart';
import 'package:voxone/util/random.dart';

enum PlayerState {
  incoming,
  playing,
  exploding,
  destroyed,
}

class HorizontalPlayer extends Component with Context {
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

  Vector2 get position => _entity.position;

  @override
  onLoad() async {
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
    _entity.position.setValues(100, 280);

    add(_entity);
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
    _entity.position.setValues(-50 + 150 * i, 280 + 50 - 50 * i);
  }

  double _rot = 0;
  double _rot_sign = 1;

  void _update_rotate(double dt) {
    if (keys.fire2 && _rot == 0) {
      _rot = pi * 2;
      _rot_sign = -_strafe_speed.sign;
      if (_rot_sign == 0) _rot = 0;
      logInfo(_strafe_speed);
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
    _entity.position.setValues(100 + _strafe / 4, 280 + _strafe);
  }
}

class HorizontalExhaust extends Component with HasPaint {
  HorizontalExhaust(this._player);

  final HorizontalPlayer _player;

  final _emission = ParticleRecycler<Emission>(() => Emission());

  double _emit_time = 0;

  @override
  void update(double dt) {
    if (_emit_time <= 0) {
      _emit_time = 0.01;
      for (int i = 0; i < 10; i++) {
        final it = _emission.acquire();
        it.pos.setFrom(_player.position);
        final off = rng.nextDoublePM(10) * cos(_player._rot);
        it.pos.x -= 25 - off / 3;
        it.pos.y += 8 + off;
        it.time = rng.nextDoubleLimit(0.5) + off.abs()/40;
        it.speed = 1 + rng.nextDoubleLimit(0.5) - off.abs()/40;
      }
    } else {
      _emit_time -= dt;
    }
    for (final it in _emission.active) {
      it.pos.x -= dt * 220 * it.speed;
      it.pos.y += dt * 60;
      it.time += dt * 2;
      if (it.time >= 1) it.active = false;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final it in _emission.active) {
      paint.color = it.color;
      paint.strokeWidth = 2 + it.speed * 2;
      canvas.drawLine(it.pos.toOffset(), Offset(it.pos.x - 12, it.pos.y + 3), paint);
    }
  }
}

class Emission with Particle {
  static final _colors = [white, yellow, orange, red, black, transparent];

  final pos = Vector2.zero();

  double time = 0;
  double speed = 0;

  Color get color => _colors[(time * (_colors.length - 1)).toInt()];
}