import 'package:flame/components.dart';
import 'package:stardash/game/position3d.dart';

mixin HasPosition3D on PositionComponent, HasVisibility {
  static const int INVISIBILITY_PRIORITY = -9876543210;

  late final Position3D position3d;

  void markInvisible() {
    priority = INVISIBILITY_PRIORITY;
    isVisible = false;
  }

  HasPosition3D markedInvisible() {
    priority = INVISIBILITY_PRIORITY;
    isVisible = false;
    return this;
  }
}
