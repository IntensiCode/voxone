import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/decals.dart';
import 'package:voxone/core/friendly_target.dart';
import 'package:voxone/core/marauder_hit_points.dart';
import 'package:voxone/core/shadows.dart';
import 'package:voxone/core/stacked_entity.dart';
import 'package:voxone/core/stacked_sprite.dart';
import 'package:voxone/game/context.dart';
import 'package:voxone/game/extras.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

class MarauderMines extends Component with Context {
  late final SpriteSheet _sheet;

  late final Future<List<Image>> _animation;

  Future<MarauderMine> spawn(Vector2 position) {
    return _animation.then((animation) {
      final it = MarauderMine(animation, shadows);
      it.position.setFrom(position);
      stage.add(it);
      return it;
    });
  }

  @override
  onLoad() async {
    _sheet = await sheetI('acid_bomb.png', 8, 2);
    _animation = _make_animation();
  }

  Future<List<Image>> _make_animation() async {
    final result = List<Image>.empty(growable: true);
    for (int a = 0; a < 8; a++) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      for (int i = 0; i < 8; i++) {
        final src = _sheet.getSprite(a == i ? 1 : 0, i);
        src.render(canvas, position: Vector2(0, i * 16), size: Vector2(16, 16));
      }
      // final anim = _sheet.getSprite(0, a);
      // anim.render(canvas, position: Vector2.zero());
      // anim.render(canvas, position: Vector2(0, 240));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(16, 128);
      picture.dispose();
      result.add(image);
    }
    return result;
  }
}

class MarauderMine extends PositionComponent with CollisionCallbacks, Context, MarauderHitPoints, HasPaint {
  MarauderMine(this.animation, Shadows shadows) : entity = StackedEntity.image(animation.first, 8, shadows) {
    entity.scale_x = 1.2;
    entity.scale_y = 1.8;
    entity.scale_z = 1.2;
    entity.size.setAll(16);

    add(entity);

    size.setAll(16);
    add(RectangleHitbox(anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    hit_points = 10;
    remaining = 10;
  }

  final List<Image> animation;
  final StackedEntity entity;

  late ExtraId which;

  bool _destroyed = false;
  double _anim_time = 0;

  @override
  bool get volatile => !_destroyed;

  @override
  set highlight_mode(HighlightMode mode) => entity.sprite.highlight_mode = mode;

  @override
  void on_destroyed() {
    if (_destroyed) return;
    _destroyed = true;
    decals.spawn(Decal.nuke_explosion, position);
    removeFromParent();

    soundboard.play(Sound.explosion_hollow);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _anim_time += dt;

    if (_anim_time >= 1) _anim_time -= 1;

    final anim_frame = (_anim_time * (animation.length - 1)).toInt();

    entity.sprite.change_image(animation[anim_frame]);

    entity.rot_x += dt;
    entity.rot_y += dt / 2;
    entity.rot_z += dt * 3;
    position.x -= 100 * dt;
    position.y += 100 / 4 * dt;
    if (position.x < -100) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other case FriendlyTarget it) {
      if (it.susceptible) {
        it.on_hit(10);
        position.x -= 10;
        position.y += 10 / 4;
        for (int i = 0; i < 5; i++) {
          final d = decals.spawn(Decal.mini_explosion, position);
          d.velocity.setValues(-10.0 * i, 10 / 4 * i);
          d.time = rng.nextDoubleLimit(0.2);
        }
        removeFromParent();

        soundboard.play(Sound.explosion_hollow);
      }
    }
  }
}
