import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/game/cube3d.dart';
import 'package:stardash/game/world3d_component.dart';
import 'package:vector_math/vector_math_64.dart';

class Scene3d extends Component {
  late World3DComponent world;
  double _elapsedTime = 0;
  final double _cameraRotationSpeed = 0.1; // Radians per second (kept slow)
  final double _minCameraRadius = 50.0;
  final double _maxCameraRadius = 200.0;
  final double _cameraZoomSpeed = 0.8; // Speed for in/out motion
  final double _ambientPulseSpeed = 0.3; // Slower pulse for ambient light

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    world = World3DComponent();
    await add(world);

    // Initial cubes
    await world.add(Cube3D(initialPosition: Vector3.zero()));
    await world.add(Cube3D(initialPosition: Vector3(20, 10, -30)));

    // Add 50 more cubes in a larger circle
    const int numExtraCubes = 5;
    const double extraCubeRadius = 150.0;
    for (int i = 0; i < numExtraCubes; i++) {
      final angle = (2 * pi / numExtraCubes) * i;
      final x = cos(angle) * extraCubeRadius;
      final z = sin(angle) * extraCubeRadius;
      // Stagger Y position slightly for visual interest
      final y = (i % 5 - 2) * 15.0;
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
    world.camera.moveTo(Vector3(camX, 0, camZ));

    // Update ambient light level (oscillating between 0.1 and 0.3)
    final double baseAmbient = 0.2;
    final double ambientAmplitude = 0.1;
    final double ambientOscillation = sin(_elapsedTime * _ambientPulseSpeed);
    world.world.ambientLightLevel = // Access public world instance
        baseAmbient + ambientAmplitude * ambientOscillation;

    // Camera target remains (0,0,0)
  }
}
