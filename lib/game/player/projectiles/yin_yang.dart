import 'dart:math';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/enemies/marauder_shot.dart';
import 'package:voxone/game/player/projectiles/directional_projectile.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';

class YinYang extends SpriteComponent
    with CollisionCallbacks, FakeThreeDee, Recyclable, DirectionalProjectile, HasVisibility {
  YinYang(this._stage) {
    anchor = Anchor.center;
    size.setAll(32);
    _sprites = atlas.sheetI('yin-yang.png', 5, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 4, position: size / 2, anchor: Anchor.center, isSolid: true)..debug());
  }

  final Component _stage;

  late final SpriteSheet _sprites;

  @override
  double get base_speed => 300;

  double _anim_time = 0;

  void reset(FakeThreeDee origin) {
    change_direction(0);
    init_fake_3d(origin);
    x += 25;
    y -= 25 / 4;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _anim_time = (_anim_time + dt * 3) % 1;
    angle = -_anim_time * pi * 2;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (recycled) return;
    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(intersections: intersectionPoints);

          var hostiles = _stage.children
              .whereType<Hostile>()
              .map((it) => it as PositionComponent)
              .filterNot((it) => it == other)
              .filterNot((it) => it is MarauderShot)
              .toSet();

          if (hostiles.isEmpty) {
            logInfo('no other hostiles');
            set_direction(randomNormalizedVector2());
            return;
          }

          // pick nearest target from hostiles:
          final nearest = hostiles.reduce((a, b) => a.distance(this) < b.distance(this) ? a : b);

          // change direction towards nearest target:
          final direction = nearest.position - position;
          set_direction(direction.normalized());
        }
      });
    }
  }
}
