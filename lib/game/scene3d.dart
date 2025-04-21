import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/game/cube3d.dart';
import 'package:stardash/game/player3d.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/world3d_component.dart';
import 'package:stardash/util/extensions.dart';

class Scene3d extends Component with HasContext {
  late World3DComponent world;
  double _elapsedTime = 0;
  final double _cameraRotationSpeed = 0.5; // Radians per second (kept slow)
  final double _minCameraRadius = 50.0;
  final double _maxCameraRadius = 500.0;
  final double _cameraZoomSpeed = 0.8; // Speed for in/out motion
  final double _ambientPulseSpeed = 1.0; // Slower pulse for ambient light

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    world = added(World3DComponent());
    await world.add(Player3D(initialPosition: Vector3.zero()));
    // await world.add(Cube3D(initialPosition: Vector3.all(100)));

    const int numExtraCubes = 0;
    const double extraCubeRadius = 150.0;
    for (int i = 0; i < numExtraCubes; i++) {
      final angle = (2 * pi / numExtraCubes) * i;
      final x = cos(angle) * extraCubeRadius;
      final z = sin(angle) * extraCubeRadius;
      // Stagger Y position slightly for visual interest
      final y = (i % 5 - 2) * 25.0;
      await world.add(Cube3D(initialPosition: Vector3(x, y, z)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedTime += dt;

    // Calculate oscillating radius
    final double radiusRange = _maxCameraRadius - _minCameraRadius;
    final double radiusOscillation = (sin(_elapsedTime * _cameraZoomSpeed) + 1.0) * 0.5; // Range [0, 1]
    final double currentRadius = _minCameraRadius + radiusRange * radiusOscillation;

    // Update camera position using oscillating radius and slow rotation
    final double camX = cos(_elapsedTime * _cameraRotationSpeed) * currentRadius;
    final double camZ = sin(_elapsedTime * _cameraRotationSpeed) * currentRadius;
    world.camera.moveTo(Vector3(camX, camZ / 4, camZ));
    world.camera.lookAt(Vector3(0, camZ / 4, 0));

    // Update ambient light level (oscillating between 0.1 and 0.3)
    final double baseAmbient = 0.3;
    final double ambientAmplitude = 0.3;
    final double ambientOscillation = sin(_elapsedTime * _ambientPulseSpeed);
    world.world.ambientLightLevel = // Access public world instance
        baseAmbient + ambientAmplitude * ambientOscillation;
  }
}
