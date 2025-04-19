import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/core/traits.dart';
import 'package:stardash/game/shared/decals.dart';
import 'package:stardash/game/shared/deflector_shield.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/shadows.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/game/shared/video_mode.dart';
import 'package:stardash/game/shared/voxel_entity.dart';
import 'package:stardash/util/component_recycler.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/functions.dart';
import 'package:stardash/util/random.dart';

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
  void onRemove() {
    super.onRemove();
    stage.children.whereType<_Extra>().forEach((it) {
      it.recycle();
      it.dispose_sprite();
    });
    _pool.items.forEach((it) => it.dispose_sprite());
    _pool.items.clear();
  }

  @override
  onLoad() {
    _sheet = sheetI('extras.png', 8, 4);

    final sprites = <ExtraId, Sprite>{};
    for (final it in ExtraId.values) {
      sprites[it] = atlas.sprite('extras/extra_${it.name}.png');
    }
    _pool = ComponentRecycler<_Extra>(() => _Extra(sprites, shadows));
    _pool.precreate(128);
  }
}

class _Extra extends VoxelEntity with CollisionCallbacks, HasContext, Recyclable {
  _Extra(this.sprites, Shadows shadows) {
    set_sprite_source(sprites[ExtraId.values.first]!, 16);

    scale_x = 1.2;
    scale_y = 4.2;
    scale_z = 1.2;
    size.setAll(32);

    add(CircleHitbox(anchor: Anchor.center, isSolid: true)..anchor_to_parent());
  }

  final Map<ExtraId, Sprite> sprites;

  late ExtraId which;

  final _direction = Vector2.zero();
  bool _captured = false;

  double _anim_time = rng.nextDouble();

  void reset(ExtraId which, Vector2 origin, double fake_height) {
    this.which = which;
    this.fake_height = fake_height;
    position.setFrom(origin);
    _anim_time = rng.nextDouble();
    _direction.setValues(-100, 25);
    _captured = false;

    change_sprite_source(sprites[which]!);
    reset_sprite_data();

    fake_height = 50;

    _delay = 0.01 + rng.nextDoubleLimit(0.3);

    scale.setAll(0);
  }

  double _delay = 0;

  @override
  void onMount() {
    super.onMount();
    shadows.add(create_linked_shadow());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _anim_time += dt;
    rot_x = sin(_anim_time * 2 * pi) * pi / 4 + pi / 2;
    if (video == VideoMode.quality) {
      // entity.rot_y = sin(_anim_time * 2 * pi * 0.24569) * pi / 8;
      rot_z = sin(_anim_time * 2 * pi * 0.74569) * pi / 8;
    }
    position.add(_direction * dt);
    if (position.x < -32) recycle();
    if (_captured) _direction.scale(1.25);

    if (!player.is_dead_or_dying() && position.x > 0 && position.x < player.position.x + 100) {
      _tmp.setFrom(player.position);
      _tmp.sub(position);
      _tmp.normalize();
      _tmp.scale(60 * dt);
      _direction.add(_tmp);
    }

    if (_delay > 0) {
      _delay = max(0, _delay - dt);
      if (_delay <= 0) decals.spawn3d(Decal.teleport, this);
      return;
    }

    if (scale.x < 1) {
      scale.x += dt * 2;
      scale.y = scale.x;
      if (scale.x >= 1) scale.setAll(1);
      return;
    }
  }

  final _tmp = v2z();

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (recycled) return;
    if (player.is_dead_or_dying()) return;
    other.onTraits<Player>((it) {
      if (it.is_dead_or_dying()) return;
      player.on_collect_extra(which);
      recycle();
    });
    other.onTraits<Friendly>((it) {
      if (other is DeflectorShield) _on_captured();
    });
  }

  void _on_captured() {
    _captured = true;

    final speed = _direction.length;
    _direction.setFrom(player.position);
    _direction.sub(position);
    _direction.normalize();
    _direction.scale(speed);
  }
}
