import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:stardash/util/extensions.dart';

ColorEffect HighlightEffect({
  Color color = const Color(0x40ffffff),
  double? opacity,
  double duration = 0.5,
  bool repeat = true,
}) {
  return ColorEffect(
      color,
      EffectController(
        duration: duration,
        curve: Curves.easeInOut,
        infinite: repeat,
        alternate: repeat,
      ),
      opacityFrom: 0,
      opacityTo: opacity ??= color.a / 255);
}

class BlinkEffect extends Effect {
  BlinkEffect({this.on = 0.35, this.off = 0.15}) : super(InfiniteEffectController(LinearEffectController(on + off)));

  final double on;
  final double off;

  @override
  void apply(double progress) {
    final visible = (progress * (on + off)) % (on + off);
    (parent as HasVisibility).isVisible = visible <= on;
  }
}

class JumpEffect extends Component {
  JumpEffect({this.duration = 0.5, this.height = 16, this.echos = 1});

  final double duration;
  final double height;
  final int echos;

  final _base_position = Vector2.zero();

  double _elapsed = 0;
  int _echoed = 0;

  @override
  void onMount() {
    _base_position.setFrom(ppc.position);
    _elapsed = 0;
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= duration) {
      if (_echoed < echos) {
        _echoed++;
        _elapsed = 0;
      } else {
        ppc.position.setFrom(_base_position);
        removeFromParent();
      }
    } else {
      final h = height - height * _echoed / (echos + 1);
      final y = sin(_elapsed * pi / duration) * h;
      ppc.position.y = (_base_position.y - y).roundToDouble();
    }
  }
}

class JumpyEffect extends Component {
  JumpyEffect({Random? random}) : rng = random ?? Random();

  final Random rng;

  double jumpiness = 3;

  double _jump_time = 0;

  final _base_position = Vector2.zero();

  @override
  void onMount() {
    final p = parent as PositionComponent;
    _base_position.setFrom(p.position);
  }

  @override
  void update(double dt) {
    _jump_time -= dt;
    if (_jump_time <= 0) {
      _jump_time = rng.nextDouble() / 10;

      final p = parent as PositionComponent;
      p.position.setFrom(_base_position);
      p.position.x += rng.nextDouble() * jumpiness;
      p.position.y += rng.nextDouble() * jumpiness;
    }
  }
}
