import 'package:flame/components.dart';
import 'package:stardash/game/camera3d.dart';
import 'package:stardash/game/position3d.dart';
import 'package:stardash/game/position_component_3d.dart';
import 'package:stardash/game/world3d.dart';

class World3DComponent extends Component {
  late final World3d _world;

  Camera3D get camera => _world.camera;

  World3DComponent({Camera3D? camera}) {
    _world = World3d(camera: camera);
  }

  @override
  void updateTree(double dt) {
    // First, update self and all children via Flame's mechanism
    super.updateTree(dt);

    // Then, delegate projection logic to the World3d instance
    // Pass only the PositionComponent3D children to it
    final children3d = children.whereType<HasPosition3D>().toList();
    _world.projectChildren(children3d);
  }
}
