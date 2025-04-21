import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/background/space.dart'; // Import space
import 'package:stardash/game/player3d.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/world3d_component.dart';
import 'package:stardash/util/extensions.dart';
import 'package:vector_math/vector_math_64.dart';

class Scene3d extends Component with HasContext {
  late World3DComponent world;
  double _elapsedTime = 0;
  final double _cameraRotationSpeed = 0.5; // Radians per second (kept slow)
  final double _minCameraRadius = 100.0;
  final double _maxCameraRadius = 100.0;
  final double _cameraZoomSpeed = 0.8; // Speed for in/out motion
  final double _ambientPulseSpeed = 1.0; // Slower pulse for ambient light

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    world = added(World3DComponent());
    await world.add(Player3D(initialPosition: Vector3.all(-50)));
    // await world.add(Cube3D(initialPosition: Vector3.all(100)));

    const int numExtraCubes = 10;
    const double extraCubeRadius = 150.0;
    for (int i = 0; i < numExtraCubes; i++) {
      final angle = (2 * pi / numExtraCubes) * i;
      final x = cos(angle) * extraCubeRadius;
      final z = sin(angle) * extraCubeRadius;
      final y = (i % 5 - 2) * 25.0;
      await world.add(Player3D(initialPosition: Vector3(x, y, -z)));
      // await world.add(Cube3D(initialPosition: Vector3(x, y, z)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedTime += dt;

    // --- Camera Movement ---
    final double radiusRange = _maxCameraRadius - _minCameraRadius;
    final double radiusOscillation = (sin(_elapsedTime * _cameraZoomSpeed) + 1.0) * 0.5; // Range [0, 1]
    final double currentRadius = _minCameraRadius + radiusRange * radiusOscillation;
    final double cameraAngle = _elapsedTime * _cameraRotationSpeed;
    final double camX = cos(cameraAngle) * currentRadius;
    final double camZ = sin(cameraAngle) * currentRadius;
    final cameraPos = Vector3(camX, camZ, camZ); // Store position
    final cameraTarget = Vector3(0, 0, 0);   // Store target
    world.camera.moveTo(cameraPos);
    world.camera.lookAt(cameraTarget);

    // --- Update Space Background Offset ---
    // Extract Yaw (Y rotation) and Pitch (X rotation) from the view matrix
    final Matrix4 view = world.camera.viewMatrix;
    final Matrix3 rot = view.getRotation(); // Gets upper-left 3x3
    final Matrix3 invRot = rot.transposed(); // Camera world rotation

    // Decompose invRot into Euler angles (YXZ order is common)
    // Pitch around X-axis
    final double pitch = asin(-invRot.entry(1, 2));
    // Yaw around Y-axis
    final double yaw = atan2(invRot.entry(0, 2), invRot.entry(2, 2));

    // Use yaw for horizontal offset and pitch for vertical offset
    // Apply scaling and negation for inverse effect.
    const double scale = 0.5;
    final double offsetX = -yaw * scale;
    final double offsetY = -pitch * scale; // Negate pitch for inverse vertical shift

    known_space.setCameraOffset(-offsetX, -offsetY);

    // --- Ambient Light ---
    final double baseAmbient = 0.3;
    final double ambientAmplitude = 0.3;
    final double ambientOscillation = sin(_elapsedTime * _ambientPulseSpeed);
    world.world.ambientLightLevel = // Access public world instance
        baseAmbient + ambientAmplitude * ambientOscillation;
  }
}
