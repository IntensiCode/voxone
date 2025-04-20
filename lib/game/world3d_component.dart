import 'package:flame/components.dart';
import 'package:stardash/game/camera3d.dart';
import 'package:stardash/game/has_lighted_faces.dart';
import 'package:stardash/game/has_position_3d.dart';
import 'package:stardash/game/world3d.dart';

class World3DComponent extends Component {
  late final World3d world;

  Camera3D get camera => world.camera;

  World3DComponent({Camera3D? camera}) {
    world = World3d(camera: camera);
  }

  @override
  void updateTree(double dt) {
    super.updateTree(dt);
    world.projectChildren(children.whereType<HasPosition3D>());
    world.lightChildren(children.whereType<HasLightedFaces>());
  }
}
