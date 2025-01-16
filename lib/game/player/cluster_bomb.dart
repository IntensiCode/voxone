import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/enemies/marauder_shot.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class ClusterBomb extends SpriteComponent with CollisionCallbacks, Recyclable, DirectionalProjectile, HasVisibility {
  ClusterBomb(this._emit_bombs) {
    anchor = Anchor.center;
    size.setAll(20);
    _sprites = atlas.sheetI('cluster_bomb.png', 1, 16);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 10)..debug());
  }

  late final Function(Vector2) _emit_bombs;
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
    final sprite_index = (anim_time * (_sprites.rows - 1)).toInt();
    sprite = _sprites.getSprite(sprite_index, 0);

    if (_life_time > 2) {
      _emit_bombs(position);
      recycle();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is! MarauderShot && other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(damage: 15, intersections: intersectionPoints);
          _emit_bombs(position);
          recycle();
        }
      });
    }
  }
}
