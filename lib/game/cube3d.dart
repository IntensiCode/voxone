import 'dart:ui';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/game/position_component_3d.dart'; // Use correct package name

class Cube3D extends PositionComponent3D {
  // Define its size in 3D world units (optional for now, needed for scaling)
  final Vector3 size3D = Vector3(10, 10, 10);

  Cube3D({required Vector3 initialPosition}) : super(initialPosition) {
    anchor = Anchor.center; // Set anchor to center
  }

  static final _paint = Paint()..color = const Color(0xFFFF0000); // Red

  @override
  void render(Canvas canvas) {
    // super.render(canvas); // Uncomment for Flame's debug box

    // We draw a simple rectangle using the 2D size calculated by World3D.
    // The 2D `size` property on PositionComponent is set by World3D's projection.
    if (size.x > 0 && size.y > 0) {
      // Avoid drawing if size is zero (clipped)
      canvas.drawRect(size.toRect(), _paint);
    }
  }

  // Example update logic (moves the cube slowly away)
  @override
  void update(double dt) {
    // logInfo('Cube3D update');
    position3D.z -= 5 * dt; // Move away from camera
    super.update(dt); // Important to call super
  }
}
