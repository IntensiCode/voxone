import 'dart:ui';

import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';

Color? debugHitboxColor = const Color(0x80ff0000);

class DebugText extends TextComponent with HasVisibility {
  DebugText({required String Function() text, super.anchor, super.position, double? scale}) {
    _text = text;
    this.scale.setAll(scale ?? 0.25);
  }

  late final String Function() _text;

  @override
  bool get isVisible => debug;

  @override
  void render(Canvas canvas) {
    if (isVisible) super.text = _text();
    super.render(canvas);
  }
}
