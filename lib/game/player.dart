import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/context.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/game/stacked_entity.dart';
import 'package:voxone/game/stage1.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/mut_rect.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/uniforms.dart';

enum PlayerState {
  incoming,
  playing,
  exploding,
  destroyed,
}

class HorizontalPlayer extends PositionComponent with Context, FriendlyTarget {
  HorizontalPlayer() {
    h_player = this;
  }

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

class PlasmaGun extends Component with Context {
  double _cool_down = 0;

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.fire1) {
      _cool_down += 0.1;

      final it = PlasmaShot();
      it.position.setFrom(h_player.position);
      it.x += 25;
      it.y -= 25 / 4;
      stage.add(it);
    }
  }
}

class PlasmaShot extends PositionComponent with CollisionCallbacks, HasPaint {
  static const _blue1 = Color(0xFFa0a0ff);
  static const _blue2 = Color(0xFF20209f);

  double _start_time = 1;

  PlasmaShot() {
    size.setAll(4);
    add(CircleHitbox(radius: 4, anchor: Anchor.center)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  @override
  void update(double dt) {
    if (_start_time > 0) _start_time -= dt;
    x += 500 * dt;
    y -= 500 / 4 * dt;
    if (x > 900) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    paint.color = _blue2;
    canvas.drawCircle(Offset.zero, 3.5 + _start_time * 4, paint);
    paint.color = _blue1;
    canvas.drawCircle(Offset.zero, 3, paint);
    paint.color = white;
    canvas.drawCircle(Offset.zero, 2, paint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other case EnemyHitPoints it) {
      if (it.volatile) {
        it.on_hit();
        removeFromParent();
      }
    }
  }
}

class DeflectorShield extends PositionComponent with HasPaint, FriendlyTarget {
  DeflectorShield() {
    size.setAll(96);
    add(CircleHitbox(anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.1
      ..renderShape = debug);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    priority = -1;
  }

  double energy = 1;
  double _deflect_time = 0;

  @override
  bool get susceptible => energy > 0.1;

  @override
  void on_hit(double damage) {
    _deflect_time = 0.3;
    energy -= damage / 25;
    if (energy < 0) {
      double remaining = energy.abs();
      if (remaining > 0) h_player.on_hit(remaining * 25);
    }
    energy = max(0, energy);
  }

  late final FragmentShader _shader;

  @override
  onLoad() async {
    _shader = await loadShader('plasma_shield.frag');
    paint.shader = _shader;
    priority = 1;
    opacity = 0.5;
    angle = -0.2;
    _shader.setFloat(0, size.x);
    _shader.setFloat(1, size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (energy < 1) energy += dt / 3;

    if (_deflect_time > 0) _deflect_time -= dt;

    _shader.setFloat(4, _deflect_time);
  }

  final _rect = MutRect(0, 0, 0, 0);
  Offset? _offset;

  @override
  void render(Canvas canvas) {
    if (_deflect_time <= 0) return;

    final image = pixelate(size.x.toInt(), size.y.toInt(), (canvas) {
      _rect.right = size.x;
      _rect.bottom = size.y;
      canvas.drawRect(_rect, paint);
    });

    _offset ??= Offset(-size.x / 2, -size.y / 2);
    _paint.opacity = _deflect_time > 0 ? 0.75 : 0.05;
    canvas.drawImage(image, _offset!, _paint);
    image.dispose();
  }

  final _paint = pixel_paint();
}

mixin FriendlyTarget {
  bool get susceptible;

  void on_hit(double damage);
}

class PlayerHud extends Component with HasPaint {
  PlayerHud(this._player) {
    add(BitmapText(text: 'SHIELD', position: Vector2(16, 16))..renderSnapshot = true);
    add(BitmapText(text: 'INTEGRITY', position: Vector2(16, 32))..renderSnapshot = true);
    // add(BitmapText(text: 'OVERHEAT', position: Vector2(16, 48))..renderSnapshot = true);
  }

  final HorizontalPlayer _player;

  @override
  void render(Canvas canvas) {
    final e = _player.shield?.energy;
    if (e != null) {
      paint.color = switch (e) {
        > .7 => _good,
        > .5 => _damaged,
        > .2 => _danger,
        _ => _critical,
      };
      _rect.left = 16;
      _rect.top = 26;
      _rect.right = 16 + e * 100;
      _rect.bottom = 30;
      canvas.drawRect(_rect, paint);
    }

    final i = _player.integrity;
    paint.color = switch (i) {
      > .6 => _good,
      > .5 => _damaged,
      > .2 => _danger,
      _ => _critical,
    };
    _rect.left = 16;
    _rect.top = 26 + 16;
    _rect.right = 16 + i * 100;
    _rect.bottom = 30 + 16;
    canvas.drawRect(_rect, paint);
  }

  final _rect = MutRect(0, 0, 0, 0);

  final _good = white;
  final _damaged = const Color(0xFFf0f060);
  final _danger = const Color(0xFFf0a060);
  final _critical = const Color(0xF0ff4040);
}
