import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/game/position3d.dart';

// Import the new mixin files
import 'has_position_3d.dart';
import 'has_lighted_faces.dart';

// Base class for components existing in the 3D world space managed by World3DComponent
class PositionComponent3D extends PositionComponent {
  // TODO: Remove this class if we can't find functionality for it to hold
  final Position3D position3d;

  PositionComponent3D(this.position3d);
}
