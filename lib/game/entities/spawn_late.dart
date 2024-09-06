import 'package:voxone/core/common.dart';
import 'package:voxone/game/entities/spawn_mode.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class SpawnLate extends Component implements SpawnMode {
  late double start_y;
  bool waiting = true;
  double enter_time = 0;

  @override
  bool should_spawn(LevelProp prop) {
    final top = prop.position.y - prop.visual_height;
    return top >= game.camera.viewfinder.position.y;
  }

  @override
  void onMount() {
    super.onMount();
    my_prop.force_visible = false;
    my_prop.force_opacity = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (waiting) {
      if (!should_spawn(my_prop)) return;
      waiting = false;
      my_prop.force_opacity = 0;
      my_prop.force_visible = null;
      my_prop.position.y -= 16;
      start_y = my_prop.position.y;
    } else {
      enter_time += dt * 2;
      if (enter_time >= 1) {
        my_prop.force_opacity = 1;
        my_prop.enemy?.active = true;
        removeFromParent();
      } else {
        my_prop.force_opacity = enter_time;
        my_prop.position.y = start_y + enter_time * 16;
      }
    }
  }
}
