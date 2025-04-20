import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/game/cube3d.dart';
import 'package:stardash/game/world3d_component.dart';

class Scene3d extends Component {
  late World3DComponent world;
  double _elapsedTime = 0;
  final double _cameraRotationSpeed = 0.5; // Radians per second
  final double _cameraRadius = 100.0;
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
    const int numExtraCubes = 50;
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

    // Update camera position
    final double camX = cos(_elapsedTime * _cameraRotationSpeed) * _cameraRadius;
    final double camZ = sin(_elapsedTime * _cameraRotationSpeed) * _cameraRadius;
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
