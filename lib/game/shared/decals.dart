import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

extension HasContextExtensions on HasContext {
  Decals get decals => cache.putIfAbsent('decals', () => Decals());
}

enum Decal {
  dust(1.0),
  energy_ball(0.5, 0),
  explosion16(1.0),
  explosion32(1.0),
  mini_explosion(1.0, 20),
  nuke_explosion(1.0, 0),
  smoke(1.0),
  teleport(0.3, 0),
  rock(0.5, 0),
  ;

  const Decal(this.anim_time, [this.random_range = 8]);

  final double anim_time;
  final double random_range;
}

class DecalObj extends PositionComponent with HasPaint, FakeThreeDee {
  DecalObj(this.animation, this.decal) : this.velocity = Vector2.zero();

  final SpriteSheet animation;
  final Decal decal;
  final Vector2 velocity;

  int row = 0;
  double time = 0;

  void randomize_position({double range = 20}) {
    position.x += rng.nextDoublePM(range);
    position.y += rng.nextDoublePM(range);
  }

  void randomize_velocity({double range = 20}) {
    velocity.x += rng.nextDoublePM(range);
    velocity.y += rng.nextDoublePM(range);
  }

  @override
  void render(Canvas canvas) {
    final size = switch (decal) {
      Decal.dust => _dust_size,
      Decal.mini_explosion => _mini_explosion_size,
      Decal.smoke => _smoke_size,
      _ => _default_decal_size,
    };
    final it = this;
    final column = (it.time * (animation.columns - 1) / decal.anim_time).toInt();
    final f = animation.getSprite(it.row, column);
    f.render(canvas, anchor: Anchor.center, size: size);
  }

  final _default_decal_size = Vector2.all(32);
  final _dust_size = Vector2.all(6);
  final _mini_explosion_size = Vector2.all(16);
  final _smoke_size = Vector2.all(6);
}

class Decals extends Component with HasContext {
  Decals() {
    for (final it in Decal.values) {
      _ready[it] = List.empty(growable: true);
      _active[it] = List.empty(growable: true);
    }
  }

  final _ready = <Decal, List<DecalObj>>{};
  final _active = <Decal, List<DecalObj>>{};
  final _anim = <Decal, SpriteSheet>{};

  DecalObj spawn3d(Decal decal, FakeThreeDee origin, {Vector2? pos_override, double? pos_range, double? vel_range}) {
    final it = _spawn(decal, pos_override ?? origin.position, pos_range: pos_range, vel_range: vel_range);
    it.fake_height = origin.fake_height;
    it.fake_height += 25;
    if (dev) it.debugMode = debugMode;
    return it;
  }

  DecalObj _spawn(Decal decal, Vector2 start, {double? pos_range, double? vel_range}) {
    late final DecalObj result;

    final instances = _active[decal] ??= List.empty(growable: true);
    final pool = _ready[decal]!;
    if (pool.isEmpty) pool.add(DecalObj(_anim[decal]!, decal));
    instances.add(result = pool.removeAt(0));

    result.position.setFrom(start);
    result.velocity.setZero();
    result.time = 0;

    if (decal == Decal.mini_explosion) {
      result.randomize_position(range: pos_range ?? 20);
      result.randomize_velocity(range: vel_range ?? 20);
      result.row = rng.nextInt(8);
    }
    if (decal == Decal.dust || decal == Decal.smoke) {
      result.randomize_position(range: pos_range ?? 8);
      result.randomize_velocity(range: vel_range ?? 8);
    }
    stage.add(result);
    return result;
  }

  @override
  onLoad() {
    _anim[Decal.dust] = sheetI('dust.png', 10, 1);
    _anim[Decal.energy_ball] = sheetI('energy_balls.png', 6, 3);
    _anim[Decal.explosion16] = sheetI('explosion16.png', 15, 1);
    _anim[Decal.explosion32] = sheetI('explosion32.png', 18, 1);
    _anim[Decal.mini_explosion] = sheetI('explosions.png', 7, 8);
    _anim[Decal.nuke_explosion] = sheetI('explosion.png', 14, 1);
    _anim[Decal.rock] = sheetI('mini_rock.png', 5, 1);
    _anim[Decal.smoke] = sheetI('smoke.png', 11, 1);
    _anim[Decal.teleport] = sheetI('teleport.png', 5, 1);
  }

  @override
  void update(double dt) {
    for (final it in Decal.values) {
      _update(it, dt);
    }
  }

  void _update(Decal decal, double dt) {
    final decals = _active[decal];
    if (decals == null) return;

    for (final it in decals) {
      it.position.x += it.velocity.x * dt;
      it.position.y -= it.velocity.y * dt;
      it.time += dt;
    }
    final done = decals.where((it) => it.time >= decal.anim_time).toList();
    for (final it in done) {
      _ready[decal]!.add(it);
      it.removeFromParent();
    }
    decals.removeAll(done);
  }
}
