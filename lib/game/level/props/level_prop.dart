import 'dart:ui';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/level/level_object.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class LevelProp extends SpriteComponent with HasVisibility, LevelObject, TapCallbacks {
  LevelProp({
    required super.sprite,
    required Paint paint,
    required super.position,
    required super.priority,
    super.children,
  }) : super(anchor: Anchor.bottomCenter) {
    level_paint = paint;
    position.x += width / 2;
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (dev) logInfo(this);
  }

  @override
  String toString() => '''
${super.toString()}
- traits: $children
- props: $properties
    ''';
}
