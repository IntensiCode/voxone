import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/delayed.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:kart/kart.dart';

// note: not using actual particles because of the pseudo-3d effect based on priority. afaict particles wouldn't work
// here at all.

class Particles extends Component {
  Particles(SpriteSheet sprites) {
    _smoke = sprites.createAnimation(row: 19, stepTime: 0.1, loop: false, from: 30, to: 40);
    _fire = sprites.createAnimation(row: 22, stepTime: 0.1, loop: false, from: 30, to: 34);
    _sparkle = sprites.createAnimation(row: 22, stepTime: 0.1, loop: false, from: 35, to: 38);
  }

  final _fire_pool = ComponentRecycler(() => _Rising());
  final _smoke_pool = ComponentRecycler(() => _Rising());
  final _sparkle_pool = ComponentRecycler(() => _Static());

  late final SpriteAnimation _smoke;
  late final SpriteAnimation _fire;
  late final SpriteAnimation _sparkle;

  void spawn_fire(Vector2 position, double variance) =>
      entities.add(_fire_pool.acquire()..init(position: position, animation: _fire, variance: variance));

  void spawn_smoke(Vector2 position, double variance) =>
      entities.add(_smoke_pool.acquire()..init(position: position, animation: _smoke, variance: variance));

  void spawn_sparkles_for(LevelProp prop) {
    final v = prop.width / 2;
    repeat(4, (i) {
      final it = _sparkle_pool.acquire();
      it.init(position: prop.position, animation: _sparkle, variance: v);
      add(Delayed(i * 0.1, () => entities.add(it)));
    });
  }
}

class BaseParticle extends SpriteAnimationComponent with Recyclable {
  late double variance;

  init({
    required Vector2 position,
    required SpriteAnimation animation,
    required double variance,
  }) {
    this.anchor = Anchor.center;
    this.position.setFrom(position);
    this.animation = animation;
    this.variance = variance;
    animationTicker!.reset();
    animationTicker!.onComplete = removeFromParent;
  }

  @override
  void onMount() {
    super.onMount();

    // setting this before adding some variance to get the "depth" right(?):
    priority = position.y.toInt() + 1;

    // default variance - actual types will change this:
    init_start_pos();
  }

  void init_start_pos() {
    position.x += rng.nextDoublePM(variance / 2);
    position.y -= rng.nextDoubleLimit(variance / 2);
    position.y -= variance / 4;
    priority = 16 + position.y.toInt() + variance.toInt();
  }
}

class _Static extends BaseParticle {}

class _Rising extends BaseParticle {
  @override
  void init_start_pos() {
    position.x += rng.nextDoublePM(variance / 2);
    position.y -= rng.nextDoubleLimit(variance);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 20 * dt;
    priority = 16 + position.y.toInt() + variance.toInt();
  }
}
