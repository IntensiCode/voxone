import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class FadeParent extends Component {
  FadeParent({this.from = 0, this.to = 1, this.duration = 1});

  final double from;
  final double to;
  final double duration;

  double _fade_time = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    final op = parent as OpacityProvider;
    _fade_time = min(_fade_time + dt, duration);
    op.opacity = lerpDouble(from, to, _fade_time / duration)!;
    if (_fade_time == duration) removeFromParent();
  }
}
