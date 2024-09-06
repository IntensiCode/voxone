import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class Decals extends Component {
  Decals(this._sprites32);

  late final SpriteSheet _sprites32;

  void spawn_for(LevelProp prop) {
    final big = prop.hit_width > 16;
    final which = prop.enemy != null
        ? 194
        : big
            ? 192
            : 193;
    final sprite = _sprites32.getSpriteById(which);
    entities.add(SpriteComponent(
      sprite: sprite,
      anchor: Anchor.bottomCenter,
      position: prop.position,
      priority: prop.position.y.toInt() - 15,
    ));
  }
}
