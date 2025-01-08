import 'dart:math';

import 'package:voxone/game/shared/has_context.dart';

mixin PlayerStrafe on HasContext {
  static const _strafe_accel = 10.0;
  static const _max_strafe_speed = 4.0;
  static const _max_strafe = 150.0;

  double _strafe_speed = 0;
  double _strafe = 0;

  void update_strafe(double dt) {
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

    set_strafe(-0.95 - _strafe_speed / 10, _strafe);
  }

  void set_strafe(double tilt, double move_offset) {}
}
