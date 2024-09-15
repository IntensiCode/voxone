import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/context.dart';
import 'package:voxone/game/player.dart';
import 'package:voxone/game/shadows.dart';
import 'package:voxone/game/stacked_entity.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

enum ExtraId {
  triple_plasma(8, when_random: true),
  acid_blast(9, when_random: true),
  ion_pulse(10, when_random: true),
  phosphor_swirl(11, when_random: true),
  yin_yang(12, when_random: true),
  plasma_ring(13, when_random: true),
  cluster_bomb(14, when_random: true),
  nuke_missile(15, when_random: true),
  health(16, when_random: true),
  shield(17, when_random: true),
  weapon(18, when_random: true),
  full_health(19),
  full_shield(20),
  full_weapon(21),
  full_clear(22),
  half_clear(23),
  ;

  final int sheet_index;
  final bool when_random;

  const ExtraId(this.sheet_index, {this.when_random = false});
}

class _Extra extends PositionComponent with CollisionCallbacks, HasPaint {
  _Extra(this.animation, Shadows shadows) : entity = StackedEntity.image(animation.first, 16, shadows) {
    priority = 10000;

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

  double _anim_time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _anim_time += dt;

    // if (_anim_time >= 1) _anim_time -= 1;
    //
    // final anim_frame = (_anim_time * (animation.length - 1)).toInt();
    //
    // entity.sprite.change_image(animation[anim_frame]);

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
    if (other is HorizontalPlayer) {
      removeFromParent();
      logInfo('collect extra $which');
    }
  }
}

class Extras extends Component with Context {
  Extras() {
    priority = 10000;
  }

  late final SpriteSheet _sheet;

  final _animations = <ExtraId, List<Image>>{};

  void spawn(Vector2 position) {
    final which = ExtraId.values.random(rng);
    final animation = _animations[which] ??= _make_animation(which);
    final extra = _Extra(animation, shadows);
    extra.which = which;
    extra.position.setFrom(position);
    stage.add(extra);
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
      // final anim = _sheet.getSprite(0, a);
      // anim.render(canvas, position: Vector2.zero());
      // anim.render(canvas, position: Vector2(0, 240));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(16, 256);
      picture.dispose();
      result.add(image);
    }
    return result;
  }

  @override
  onLoad() async {
    _sheet = await sheetI('extras.png', 8, 4);
  }
}
