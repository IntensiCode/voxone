import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/stacked_sprite.dart';

extension HasContextExtensions on HasContext {
  MarauderMines get mines => cache.putIfAbsent('mines', () => MarauderMines());
}

class MarauderMines extends Component with HasContext {
  Future<MarauderMine> spawn(Vector2 position) {
    final animation = cache.require<Future<SpriteAnimation>>('mines_animation');
    return animation.then((animation) {
      final it = MarauderMine(animation, shadows);
      it.position.setFrom(position);
      stage.add(it);
      return it;
    });
  }

  @override
  onLoad() async {
    cache.putIfAbsent('mines_animation', () async {
      final sheet = sheetI('acid_bomb.png', 8, 2);
      return _make_animation(sheet);
    });
  }

  Future<SpriteAnimation> _make_animation(SpriteSheet sheet) async {
    final frames = List.generate(8, (frame) => _render_frame(sheet, frame));

    // make single image from the frames in result:
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (int i = 0; i < frames.length; i++) {
      canvas.drawImage(frames[i], Offset(i * 16.0, 0), Paint());
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(frames.first.width * 8, frames.first.height);
    picture.dispose();
    cache.addDisposable(Disposable.wrap(() => image.dispose()));

    frames.forEach((it) => it.dispose());

    final result_sheet = SpriteSheet.fromColumnsAndRows(image: image, columns: 8, rows: 1);
    return result_sheet.createAnimation(row: 0, stepTime: 0.1, loop: true);
  }

  Image _render_frame(SpriteSheet sheet, int a) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (int i = 0; i < 8; i++) {
      final src = sheet.getSprite(a == i ? 1 : 0, i);
      src.render(canvas, position: Vector2(0, i * 16), size: Vector2(16, 16));
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(16, 128);
    picture.dispose();
    return image;
  }
}

class MarauderMine extends PositionComponent with CollisionCallbacks, HasContext, HasPaint, EnemyHitPoints {
  MarauderMine(this.animation, Shadows shadows)
      : entity = StackedEntity.image(animation.frames.first.sprite.image, 8, shadows) {
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

  final SpriteAnimation animation;
  final StackedEntity entity;

  late ExtraId which;

  double drift = 0.0;

  bool _destroyed = false;
  double _anim_time = 0;

  @override
  bool get susceptible => !_destroyed;

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

    final anim_frame = (_anim_time * (animation.frames.length - 1)).toInt();

    if (entity.sprite.isLoaded) {
      entity.sprite.change_sprite(animation.frames[anim_frame].sprite);
    }

    entity.rot_x += dt;
    entity.rot_y += dt / 2;
    entity.rot_z += dt * 3;
    position.x -= 100 * dt;
    position.y += 100 / 4 * dt;
    position.x -= drift / 4 * dt;
    position.y -= drift * dt;
    if (position.x < -100) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (!other.hasTrait<Friendly>()) return;

    other.onTraits<Target>((it) {
      if (!it.susceptible) return;

      it.on_hit(damage: 10);

      position.x -= 10;
      position.y += 10 / 4;
      for (int i = 0; i < 5; i++) {
        final d = decals.spawn(Decal.mini_explosion, position);
        d.velocity.setValues(-10.0 * i, 10 / 4 * i);
        d.time = rng.nextDoubleLimit(0.2);
      }
      removeFromParent();

      soundboard.play(Sound.explosion_hollow);
    });
  }
}
