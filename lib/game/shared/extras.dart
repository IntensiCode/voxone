import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

extension HasContextExtensions on HasContext {
  Extras get extras => cache.putIfAbsent('extras', () => Extras());
}

class Extras extends Component with HasContext {
  Extras() {
    priority = 10000;
  }

  late final SpriteSheet _sheet;
  late final ComponentRecycler<_Extra> _pool;

  Sprite icon_for(ExtraId which) => _sheet.getSpriteById(which.sheet_index);

  void spawn3d(FakeThreeDee origin, {required Set<ExtraId> choices, int? index, int? count}) {
    spawn(origin.position, origin.fake_height, choices: choices, index: index, count: count);
  }

  void spawn(Vector2 origin, double fake_height, {required Set<ExtraId> choices, int? index, int? count}) {
    final pick = _pick_power_up(choices);
    if (pick == null) return;

    final extra = stage.added(_pool.acquire()..reset(pick, origin, fake_height));
    if (index != null && count != null && count > 1) {
      final distance = count * 6;
      final angle = 2 * pi * index / count;
      extra.position.x += cos(angle) * distance;
      extra.position.y += sin(angle) * distance;
    }
  }

  ExtraId? _pick_power_up(Set<ExtraId> allowed) {
    if (allowed.isEmpty) return null;

    // pick random power up, based on probabilities in _extras:

    final extras = <(ExtraId, double)>[];
    var added_probability = 0.0;
    for (final it in allowed) {
      added_probability += it.probability;
      extras.add((it, added_probability));
    }

    final all = extras.last.$2;
    final pick = rng.nextDoubleLimit(all);
    for (final it in extras) {
      if (pick < it.$2) return it.$1;
    }
    throw 'oh really?';
  }

  @override
  onLoad() {
    _sheet = sheetI('extras.png', 8, 4);

    final sprites = <ExtraId, Sprite>{};
    for (final it in ExtraId.values) {
      sprites[it] = atlas.sprite('extras/extra_${it.name}.png');
    }
    _pool = ComponentRecycler<_Extra>(() => _Extra(sprites, shadows));
  }
}

class _Extra extends PositionComponent with CollisionCallbacks, HasContext, HasPaint, Recyclable , FakeThreeDee{
  _Extra(this.sprites, Shadows shadows) : entity = StackedEntity.sprite(sprites[ExtraId.values.first]!, 16, shadows) {
    // priority = 0;

    entity.scale_x = 1.2;
    entity.scale_y = 4.2;
    entity.scale_z = 1.2;
    entity.size.setAll(32);

    add(entity);

    size.setAll(32);
    add(RectangleHitbox(anchor: Anchor.center)..debug());
  }

  final Map<ExtraId, Sprite> sprites;
  final StackedEntity entity;

  late ExtraId which;

  double _anim_time = rng.nextDouble();

  void reset(ExtraId which, Vector2 origin, double fake_height) {
    this.which = which;
    this.fake_height = fake_height;
    position.setFrom(origin);
    _anim_time = rng.nextDouble();

    entity.sprite.loaded.then((_) {
      entity.sprite.change_sprite(sprites[which]!);
    });

    entity.sprite.reset();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _anim_time += dt;
    entity.rot_x = sin(_anim_time * 2 * pi) * pi / 4 + pi / 2;
    // entity.rot_y = sin(_anim_time * 2 * pi * 0.24569) * pi / 8;
    // entity.rot_z = sin(_anim_time * 2 * pi * 0.74569) * pi / 8;
    position.x -= 100 * dt;
    position.y += 100 / 4 * dt;
    if (position.x < -100) recycle();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    other.onTraits<Friendly>((it) {
      decals.spawn3d(Decal.teleport, this);
      player.on_collect_extra(which);
      recycle();
    });
  }
}
