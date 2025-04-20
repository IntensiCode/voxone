import 'package:flame/components.dart';
import 'package:stardash/game/cube3d.dart';
import 'package:stardash/game/world3d.dart';

class Scene3d extends Component {
  late World3DComponent world;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    world = World3DComponent();
    await add(world);

    final cube = Cube3D(initialPosition: Vector3.zero());
    await world.add(cube);

    // final cube2 = Cube3D(initialPosition: Vector3(20, 10, -30));
    // await world.add(cube2);
  }
}
