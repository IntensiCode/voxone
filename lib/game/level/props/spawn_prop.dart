import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:voxone/util/effects.dart';
import 'package:flame/components.dart';

class SpawnProp extends Component {
  SpawnProp(this.consumable);

  final LevelProp consumable;

  @override
  void onMount() {
    super.onMount();
    my_prop.when_removed.add(() {
      removeFromParent();
      entities.add(consumable);
      consumable.add(JumpEffect());
    });
  }
}
