import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:voxone/game/level/props/spawn_prop.dart';
import 'package:flame/components.dart';

class Spawned extends Component {
  @override
  void onMount() {
    super.onMount();
    removeFromParent();
    _move_into_container();
  }

  void _move_into_container() {
    final containers = entities.children.whereType<LevelProp>();
    for (final it in containers) {
      if (it.properties['consumable'] == true) continue;
      if (it.properties['spawned'] == true) continue;

      if (it.containsPoint(my_prop.center)) {
        it.add(SpawnProp(my_prop));
        my_prop.removeFromParent();
        return;
      }
    }

    // placed, not spawned, which is fine:
    my_prop.properties.remove('spawned');
  }
}
