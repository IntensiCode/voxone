import 'package:voxone/game/level/props/level_prop.dart';
import 'package:flame/components.dart';

mixin SpawnMode on Component {
  bool should_spawn(LevelProp prop);
}
