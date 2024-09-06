import 'package:voxone/core/common.dart';
import 'package:voxone/game/entities/spawn_mode.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class SpawnWhenVisible extends Component implements SpawnMode {
  @override
  bool should_spawn(LevelProp prop) => prop.position.y >= game.camera.viewfinder.position.y;

  @override
  void update(double dt) {
    super.update(dt);
    if (!should_spawn(my_prop)) return;
    my_prop.enemy?.active = true;
    removeFromParent();
  }
}
