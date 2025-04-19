import 'dart:math';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/traits.dart';
import 'package:stardash/game/enemies/marauder_shot.dart';
import 'package:stardash/game/player/projectiles/directional_projectile.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/random.dart';

class YinYang extends SpriteComponent
    with CollisionCallbacks, FakeThreeDee, Recyclable, DirectionalProjectile, HasVisibility {
  YinYang(this._stage) {
    anchor = Anchor.center;
    size.setAll(32);
    _sprites = atlas.sheetI('yin-yang.png', 5, 1);
    sprite = _sprites.getSprite(0, 0);
    add(CircleHitbox(radius: 8, position: size / 2, anchor: Anchor.center, isSolid: true)..debug());
  }

  final Component _stage;

  late final SpriteSheet _sprites;

  @override
  double get base_speed => 300;

  double _anim_time = 0;

  double _damage = 2;

  void reset(FakeThreeDee origin) {
    set_direction_angle(0);
    init_fake_3d(origin);
    size.setAll(32);
    x += 25;
    y -= 25 / 4;
    _damage = 2;
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
          it.on_hit(intersections: intersectionPoints, damage: _damage);
          _damage = max(0.25, _damage - 1 / 32);

          var hostiles = _stage.children
              .whereType<Hostile>()
              .map((it) => it as PositionComponent)
              .filterNot((it) => it == other)
              .filterNot((it) => it is MarauderShot)
              .toSet();

          if (hostiles.isEmpty) {
            set_direction(randomNormalizedVector2());
            return;
          }

          // pick nearest target from hostiles:
          final nearest = hostiles.reduce((a, b) => a.distance(this) < b.distance(this) ? a : b);

          // change direction towards nearest target:
          final direction = nearest.position - position;
          set_direction(direction.normalized());

          size.setAll(size.x - 0.25);
          if (size.x < 8) recycle();
        }
      });
    }
  }
}
