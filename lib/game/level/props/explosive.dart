import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class Explosive extends Component {
  @override
  void onMount() {
    super.onMount();
    my_prop.when_destroyed.add(() => model.explosions.spawn_explosion_for(my_prop));
  }
}
