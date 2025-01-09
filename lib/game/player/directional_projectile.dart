import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';

mixin DirectionalProjectile on PositionComponent {
  double get base_speed => 500;

  late final _direction = Vector2(1, 0)
    ..rotate(-pi / 16)
    ..scale(base_speed);

  void change_direction(double relative_angle) {
    _direction.setValues(1, 0);
    _direction.rotate(-pi / 16 + relative_angle);
    _direction.scale(base_speed);
  }

  final _tmp = Vector2.zero();

  @override
  void update(double dt) {
    _tmp.setFrom(_direction);
    _tmp.scale(dt);
    position.add(_tmp);

    if (x > game_width + 100) removeFromParent();
  }
}
