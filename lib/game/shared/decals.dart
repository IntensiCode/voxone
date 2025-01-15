import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

extension HasContextExtensions on HasContext {
  Decals get decals => cache.putIfAbsent('decals', () => Decals());
}

enum Decal {
  dust(1.0),
  energy_ball(0.5),
  explosion16(1.0),
  explosion32(1.0),
  mini_explosion(1.0),
  nuke_explosion(1.0),
  smoke(1.0),
  teleport(0.3),
  rock(0.5),
  ;

  const Decal(this.anim_time);

  final double anim_time;
}

class DecalObj {
  int row = 0;
  final position = Vector2.zero();
  final velocity = Vector2(0, 0);
  double time = 0;

  void randomize_position({double range = 20}) {
    position.x += rng.nextDoublePM(range);
    position.y += rng.nextDoublePM(range);
  }

  void randomize_velocity({double range = 20}) {
    velocity.x += rng.nextDoublePM(range);
    velocity.y += rng.nextDoublePM(range);
  }
}

class Decals extends Component {
  Decals() {
    priority = 10000;
    for (final it in Decal.values) {
      _ready[it] = List.generate(10, (_) => DecalObj());
      _active[it] = List.empty(growable: true);
    }
  }

  final _ready = <Decal, List<DecalObj>>{};
  final _active = <Decal, List<DecalObj>>{};
  final _anim = <Decal, SpriteSheet>{};

  DecalObj spawn(Decal decal, Vector2 start, {double? pos_range, double? vel_range}) {
    late final DecalObj result;

    final instances = _active[decal] ??= List.empty(growable: true);
    final pool = _ready[decal]!;
    if (pool.isEmpty) pool.add(DecalObj());
    instances.add(result = pool.removeAt(0));

    result.position.setFrom(start);
    result.velocity.setZero();
    result.time = 0;

    if (decal == Decal.mini_explosion) {
      result.randomize_position(range: pos_range ?? 20);
      result.randomize_velocity(range: vel_range ?? 20);
      result.row = rng.nextInt(8);
    }
    if (decal == Decal.smoke) {
      result.randomize_position(range: pos_range ?? 8);
      result.randomize_velocity(range: vel_range ?? 8);
    }
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
    }
    decals.removeAll(done);
  }

  @override
  void render(Canvas canvas) {
    for (final it in Decal.values) {
      _render(it, canvas, _anim[it]!);
    }
  }

  void _render(Decal decal, Canvas canvas, SpriteSheet animation) {
    final decals = _active[decal];
    if (decals == null) return;

    final size = switch (decal) {
      Decal.mini_explosion => _mini_explosion_size,
      Decal.smoke => _smoke_size,
      _ => _default_decal_size,
    };
    for (final it in decals) {
      final column = (it.time * (animation.columns - 1) / decal.anim_time).toInt();
      final f = animation.getSprite(it.row, column);
      f.render(canvas, position: it.position, anchor: Anchor.center, size: size);
    }
  }

  final _default_decal_size = Vector2.all(32);
  final _mini_explosion_size = Vector2.all(16);
  final _smoke_size = Vector2.all(6);
}
