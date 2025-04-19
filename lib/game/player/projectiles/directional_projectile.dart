import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/util/component_recycler.dart';

mixin DirectionalProjectile on PositionComponent, FakeThreeDee, Recyclable {
  @override
  double? get fake_size => 2;

  double get base_speed => 500;

  Vector2 get base_direction => _direction;

  late final _direction = Vector2(1, 0)
    ..rotate(-pi / 16)
    ..scale(base_speed);

  void change_direction(double relative_angle) {
    _direction.rotate(-pi / 16 + relative_angle);
  }

  void set_direction_angle(double angle) {
    _direction.setValues(1, 0);
    _direction.rotate(-pi / 16 + angle);
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
    super.update(dt);

    _tmp.setFrom(_direction);
    _tmp.scale(dt);
    position.add(_tmp);

    // TODO how can we get away without priority based on y? too expensive, right?
    priority = position.y.toInt() + fake_height.toInt();

    if (x > game_width + 100) recycle();
  }
}
