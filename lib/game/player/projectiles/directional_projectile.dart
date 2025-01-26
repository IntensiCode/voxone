import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/util/component_recycler.dart';

mixin DirectionalProjectile on PositionComponent, FakeThreeDee, Recyclable {
  @override
  double? get fake_size => 2;

  double get base_speed => 500;

  late final _direction = Vector2(1, 0)
    ..rotate(-pi / 16)
    ..scale(base_speed);

  void change_direction(double relative_angle) {
    _direction.setValues(1, 0);
    _direction.rotate(-pi / 16 + relative_angle);
    _direction.scale(base_speed);
  }

  void set_direction(Vector2 direction) {
    _direction.setFrom(direction);
    _direction.normalize();
    _direction.scale(base_speed);
  }

  final _tmp = Vector2.zero();

  @override
  void update(double dt) {
    _tmp.setFrom(_direction);
    _tmp.scale(dt);
    position.add(_tmp);
    priority = position.y.toInt() + 50; // player fake height is fixed for now - KISS for now

    if (x > game_width + 100) recycle();
  }
}
