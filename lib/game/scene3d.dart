import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/game/cube3d.dart';
import 'package:stardash/game/world3d_component.dart';

class Scene3d extends Component {
  late World3DComponent world;
  double _elapsedTime = 0;
  final double _rotationSpeed = 0.5; // Radians per second
  final double _radius = 100.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    world = World3DComponent();
    await add(world);

    final cube = Cube3D(initialPosition: Vector3.zero());
    await world.add(cube);

    final cube2 = Cube3D(initialPosition: Vector3(20, 10, -30));
    await world.add(cube2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedTime += dt;

    // Calculate new camera position on the XZ plane circle
    final double camX = cos(_elapsedTime * _rotationSpeed) * _radius;
    final double camZ = sin(_elapsedTime * _rotationSpeed) * _radius;
    final newPosition = Vector3(camX, 0, camZ); // Keep Y at 0 for now

    world.camera.moveTo(newPosition);

    // Camera target remains (0,0,0) as set initially in World3d logic class
  }
}
