import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
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

  final _animations = <ExtraId, List<Image>>{};

  Sprite icon_for(ExtraId which) => _sheet.getSpriteById(which.sheet_index);

  void spawn(Vector2 position, {required Set<ExtraId> choices, int? index, int? count}) {
    final pick = _pick_power_up(choices);
    if (pick == null) return;

    final animation = _animations[pick] ??= _make_animation(pick);
    final extra = _Extra(animation, shadows);
    extra.which = pick;
    extra.position.setFrom(position);
    stage.add(extra);

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

  List<Image> _make_animation(ExtraId which) {
    final result = List<Image>.empty(growable: true);
    for (int a = 0; a < 1; a++) {
      final src = _sheet.getSpriteById(which.sheet_index);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      for (int i = 0; i < 16; i++) {
        src.render(canvas, position: Vector2(0, i * 16), size: Vector2(16, 16));
      }
      final picture = recorder.endRecording();
      final image = picture.toImageSync(16, 256);
      picture.dispose();
      result.add(image);
    }
    return result;
  }

  @override
  onLoad() async {
    _sheet = sheetI('extras.png', 8, 4);
  }
}

class _Extra extends PositionComponent with CollisionCallbacks, HasContext, HasPaint {
  _Extra(this.animation, Shadows shadows) : entity = StackedEntity.image(animation.first, 16, shadows) {
    // priority = 0;

    entity.scale_x = 1.2;
    entity.scale_y = 4.2;
    entity.scale_z = 1.2;
    entity.size.setAll(32);

    add(entity);

    size.setAll(32);
    add(RectangleHitbox(anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);
  }

  final List<Image> animation;
  final StackedEntity entity;

  late ExtraId which;

  double _anim_time = rng.nextDouble();

  @override
  void update(double dt) {
    super.update(dt);
    _anim_time += dt;
    entity.rot_x = sin(_anim_time * 2 * pi) * pi / 4 + pi / 2;
    entity.rot_y = sin(_anim_time * 2 * pi * 0.24569) * pi / 8;
    entity.rot_z = sin(_anim_time * 2 * pi * 0.74569) * pi / 8;
    position.x -= 100 * dt;
    position.y += 100 / 4 * dt;
    if (position.x < -100) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    other.onTraits<Friendly>((it) {
      decals.spawn(Decal.teleport, position);
      removeFromParent();
      player.on_collect_extra(which);
    });
  }
}
