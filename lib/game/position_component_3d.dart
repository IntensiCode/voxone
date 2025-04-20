import 'package:flame/components.dart';
import 'package:stardash/game/position3d.dart';

mixin HasPosition3D on PositionComponent {
  late final Position3D position3d;
}

// Base class for components existing in the 3D world space managed by World3DComponent
class PositionComponent3D extends PositionComponent {
  // TODO: Remove this class if we can't find functionality for it to hold
  final Position3D position3d;

  PositionComponent3D(this.position3d);
}
