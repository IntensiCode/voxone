import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class Bomb extends SpriteComponent with CollisionCallbacks, Recyclable, DirectionalProjectile, HasVisibility {
  Bomb() {
    anchor = Anchor.center;
    size.setAll(10);
    _sprites = atlas.sheetI('bomb.png', 16, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 5)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  late final SpriteSheet _sprites;

  double _life_time = 0;

  @override
  double get base_speed => 200;

  void reset(Vector2 origin) {
    _life_time = 0;
    position.setFrom(origin);
    x += 25;
    y -= 25 / 4;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life_time += dt;

    final anim_time = _life_time % 1;
    final sprite_index = (anim_time * (_sprites.columns - 1)).toInt();
    sprite = _sprites.getSprite(0, sprite_index);

    if (_life_time > 5 || _is_outside()) recycle();
  }

  bool _is_outside() => x < -50 || x > game_width + 50 || y < 50 || y > game_height + 50;

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(damage: 5, intersections: intersectionPoints);
          recycle();
        }
      });
    }
  }
}
