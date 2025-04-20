import 'package:flame/components.dart';
import 'package:stardash/game/camera3d.dart';
import 'package:stardash/game/position3d_component.dart';
import 'package:stardash/game/world3d.dart';

class World3DComponent extends Component {
  late final World3d _world;

  Camera3D get camera => _world.camera;

  World3DComponent({Camera3D? camera}) {
    _world = World3d(camera: camera);
  }

  @override
  void updateTree(double dt) {
    super.updateTree(dt);
    _world.projectChildren(children.whereType<HasPosition3D>());
    _world.lightChildren(children.whereType<HasLightedFaces>());
  }
}
