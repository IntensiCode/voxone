import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/context.dart';
import 'package:voxone/game/decals.dart';
import 'package:voxone/game/extras.dart';
import 'package:voxone/game/game_phase.dart';
import 'package:voxone/game/game_screen.dart';
import 'package:voxone/game/info_overlay.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/game/player.dart';
import 'package:voxone/game/shadows.dart';
import 'package:voxone/game/space.dart';
import 'package:voxone/game/stacked_entity.dart';
import 'package:voxone/game/stacked_sprite.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/mut_rect.dart';
import 'package:voxone/util/on_message.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/uniforms.dart';

class Stage1 extends GameScreen {
  Stage1() {
    stage = this;
  }

  double _show_time = 0;

  @override
  onLoad() async {
    add(Space());
    _change_phase(phase);
    add(decals = Decals());
    add(extras = Extras());
    add(mines = MarauderMines());
    add(InfoOverlay());
  }

  void _change_phase(GamePhase phase) {
    logInfo(phase);
    switch (phase) {
      case GamePhase.show_stage:
        final t1 = textXY('Stage 1', game_width / 2, game_height / 2 - 15, scale: 2);
        final t2 = textXY('Approaching Planet Voxone', game_width / 2, game_height / 2 + 5);
        t1.fadeInDeep();
        t2.fadeInDeep();
        clearScript();
        at(2.0, () => t1.fadeOutDeep());
        at(0.0, () => t2.fadeOutDeep());
        _show_time = 0;

      case GamePhase.intro:
        add(shadows = Shadows());
        final p = added(HorizontalPlayer());
        add(PlayerHud(p));
        shadows.isVisible = false;

      case GamePhase.playing:
        add(EnemiesStage1());

      case GamePhase.complete:
        break;

      case GamePhase.game_over:
        break;
    }
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<GamePhaseUpdate>((it) => _change_phase(it.phase));
    onMessage<PlayerReady>((it) => _change_phase(GamePhase.playing));
  }

  @override
  void update(double dt) {
    switch (phase) {
      case GamePhase.show_stage:
        _show_time += dt;
        if (_show_time >= 2.5) {
          phase = GamePhase.intro;
        }

      case GamePhase.intro:
        break; // waiting for PlayerReady

      case GamePhase.playing:
        break; // waiting for EnemiesDefeated

      case GamePhase.complete:
        break;

      case GamePhase.game_over:
        break;
    }
  }
}

class EnemiesStage1 extends Component {
  final _waves = [MarauderWave(), MinefieldWave()];

  EnemyWave? _active_wave;

  @override
  void update(double dt) {
    if (_active_wave?.defeated == false) {
      return;
    } else if (_waves.isEmpty) {
      removeFromParent();
      sendMessage(EnemiesDefeated());
    } else {
      _active_wave = added(_waves.removeAt(0));
    }
  }
}

mixin EnemyWave on Component {
  double delay = 1;
  bool defeated = false;
}

class MarauderWave extends Component with EnemyWave {
  static const enemies_in_wave = 8;

  MarauderWave() {
    Marauder._can_sweep = true;
  }

  bool _info_shown = false;
  bool _active = false;
  double _next_time = 0;

  @override
  void update(double dt) {
    if (delay > 0) {
      delay -= dt;
      return;
    }
    if (!_info_shown) {
      sendMessage(ShowInfoText(text: 'Enemy Wave Incoming', when_done: () => _active = true));
      _info_shown = true;
      _active = true;
    }
    if (!_active) {
      return;
    }
    if (_wave.length >= enemies_in_wave) {
      defeated = _wave.every((it) => it.defeated);
      return;
    }
    if (_next_time > 0) {
      _next_time -= dt;
      return;
    }
    _next_time = 0.5;

    final it = Marauder();
    it.target_position.x = 600 + sin(_wave.length * 2 * pi / enemies_in_wave) * 100;
    it.target_position.y = 160 + cos(_wave.length * 2 * pi / enemies_in_wave) * 100;
    _wave.add(it);
    stage.add(it);
  }

  final _wave = List<Marauder>.empty(growable: true);
}

enum MarauderState {
  incoming,
  active,
  sweeping,
  leaving,
  left,
  exploding,
  defeated,
}

class Marauder extends PositionComponent with Context, EnemyHitPoints {
  late final StackedEntity _entity;

  Marauder() {
    hit_points = 25;
    remaining = 25;
  }

  MarauderState _state = MarauderState.incoming;

  bool get defeated => _state == MarauderState.defeated || _state == MarauderState.left;

  final target_position = Vector2.zero();

  @override
  bool get volatile => switch (_state) {
        MarauderState.left => false,
        MarauderState.exploding => false,
        MarauderState.defeated => false,
        _ => _incoming_time > 0.9,
      };

  @override
  void on_destroyed() {
    if (_state == MarauderState.exploding) return;
    _state = MarauderState.exploding;
    _entity.add(EnemyExplosion());
    if (_sweep_time > 0) _can_sweep = true;
  }

  @override
  void on_hit() {
    super.on_hit();
    decals.spawn(Decal.mini_explosion, position);
    _hit_time += 0.05;
  }

  double _hit_time = 0;

  @override
  Future onLoad() async {
    super.onLoad();

    _entity = StackedEntity('entities/transstellar.png', 14, shadows);
    // _entity.sprite.add(EnemyHealthBar(this));
    await _entity.add(EnemyHealthBar(this));
    _entity.size.setAll(256);

    _entity.rot_x = -pi / 8;
    _entity.rot_y = -pi / 2 + pi / 8;
    _entity.rot_z = -pi / 8;
    _entity.scale_x = 1.2;
    _entity.scale_y = 3.5;
    _entity.scale_z = 1.2;
    position.setFrom(target_position);

    await add(_entity);

    size.setAll(180);
    await add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    await add(MarauderGun(this));
  }

  double _incoming_time = 0;
  double _active_time = 0;
  double _leaving_time = 0;

  @override
  void update(double dt) {
    if (_hit_time > 0) _hit_time -= dt;
    _entity.sprite.highlight_mode = _hit_time > 0 ? HighlightMode.hit : HighlightMode.none;

    switch (_state) {
      case MarauderState.incoming:
        _on_incoming(dt);

      case MarauderState.active:
        _on_active(dt);

      case MarauderState.sweeping:
        _on_sweeping(dt);

      case MarauderState.leaving:
        _on_leaving(dt);

      case MarauderState.left:
        removeFromParent();

      case MarauderState.exploding:
        _on_exploding(dt);

      case MarauderState.defeated:
        if (!_spawned) extras.spawn(position);
        _spawned = true;
        removeFromParent();
    }
  }

  bool _spawned = false;

  void _on_incoming(double dt) {
    _incoming_time += dt * 2 / 3;
    if (_incoming_time >= 1) {
      _incoming_time = 1;
      _state = MarauderState.active;
    }
    scale.setAll((1 - _incoming_time) * 0.5 + 0.2);
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(_incoming_time);
    position.setFrom(target_position);
    position.x += 350;
    position.x -= 350 * i;
  }

  void _on_active(double dt) {
    scale.setAll(sin(_active_time / 3) * 0.025 + 0.2);
    priority = (scale.x * 1000).toInt();
    _entity.rot_x = -pi / 8 + sin(_active_time / 7) * 0.2;
    _entity.rot_y = -pi / 2 + pi / 8;
    _entity.rot_z = -pi / 8 + sin(_active_time) * 0.2;
    _active_time += dt * 3;
    position.setFrom(target_position);
    position.x += sin(_active_time / 1.2345) * 10;
    position.y += sin(_active_time) * 10;

    if (_state != MarauderState.active) {
      return;
    } else if (_can_sweep && rng.nextDouble() < 0.2) {
      _can_sweep = false;
      _sweep_time = 0;
      _sweep_dist = 300 - target_position.x;
      _state = MarauderState.sweeping;
    } else if (_active_time > 120) {
      if (!dev) _state = MarauderState.leaving;
    }
  }

  static bool _can_sweep = true;

  double _sweep_time = 0;
  double _sweep_dist = 0;
  bool _planted = false;

  void _on_sweeping(double dt) {
    _on_active(dt);

    _sweep_time += dt;
    if (_sweep_time >= 10) {
      _can_sweep = true;
      _planted = false;
      _sweep_time = 0;
      _state = MarauderState.active;
      return;
    }

    if (_sweep_time >= 5 && !_planted) {
      _planted = true;
      logInfo('plant mine');
      mines.spawn(position);
    }

    final t = Curves.easeInOutCubic.transform(_sweep_time / 10);
    final x = sin(t * pi) * _sweep_dist;
    position.x += x;
    scale.x += sin(t * pi) / 10;
    scale.y += sin(t * pi) / 10;
    priority = (scale.x * 1000).toInt();

    double mm = _sweep_time < 5 ? 0 : 0.5 + (_sweep_time - 5) / 10;
    double m = Curves.easeInOut.transform(mm);
    _entity.rot_x -= sin(m * pi * 8 / 4) * pi / 4;
    _entity.rot_y -= sin(m * pi * 8 / 4) * pi / 1;
    _entity.rot_z += sin(m * pi * 8 / 4) * pi / 2;
  }

  void _on_leaving(double dt) {
    _on_active(dt);

    _leaving_time += dt;
    if (_leaving_time >= 2) {
      _leaving_time = 2;
      _state = MarauderState.left;
    }

    scale.x += _leaving_time * 0.5;
    scale.y += _leaving_time * 0.5;
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(_leaving_time / 2);
    position.y -= 550 * i;
    position.x -= 550 * i / 4;
  }

  void _on_exploding(double dt) {
    _leaving_time += dt;
    if (_leaving_time >= 2) {
      _leaving_time = 2;
      _state = MarauderState.defeated;
    }

    _entity.rot_x += dt;
    _entity.rot_y += dt * 2;
    _entity.rot_z += dt * 0.5;
    position.x -= dt * 100;
    position.y += dt * 100 / 4;

    _entity.sprite.opacity = 1 - _leaving_time / 2;
  }
}

class EnemyExplosion extends CircleComponent {
  EnemyExplosion() {
    radius = 128;
  }

  static FragmentShader? _explosion;
  static SpriteAnimation? _anim;

  @override
  Future onLoad() async {
    _explosion ??= await loadShader('explosion.frag');
    _explosion!.setFloat(0, width);
    _explosion!.setFloat(1, height);
    _anim ??= await animCR('explosion96.png', 12, 1, 0.1);
    paint.color = white;
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    paint.shader = _explosion!;
    return super.onLoad();
  }

  double _time = 0;
  bool _added = false;

  @override
  void update(double dt) {
    _explosion!.setFloat(2, _time / 2);
    _time += dt;
    if (_time >= 1 && !_added) {
      add(SpriteAnimationComponent(animation: _anim!, removeOnFinish: true)..scale.setAll(2.5));
      _added = true;
    }
  }
}

mixin EnemyHitPoints on Component {
  double hit_points = 10;
  double remaining = 10;

  bool get volatile;

  void on_destroyed();

  void on_hit() {
    if (remaining > 0) remaining--;
    if (remaining == 0) on_destroyed();
  }
}

class EnemyHealthBar extends PositionComponent {
  EnemyHealthBar(this._hit_points);

  final EnemyHitPoints _hit_points;

  static const _good = Color(0xA0ffffff);
  static const _half = Color(0xA0ffff00);
  static const _bad = Color(0xA0ff7f00);
  static const _critical = Color(0xA0ff0000);

  static final _paint = pixel_paint()..strokeWidth = 2;

  final _outline = const Rect.fromLTWH(0, 0, 100, 20);
  final _health = MutRect(3, 3, 96, 16);

  @override
  void onMount() {
    super.onMount();
    position.x = (parent as PositionComponent).width / 2 - 50;
  }

  @override
  void update(double dt) {
    if (_show_time > 0) _show_time -= dt;
  }

  double _percent_seen = 100;
  double _show_time = 0;

  @override
  void render(Canvas canvas) {
    final percent = _hit_points.remaining * 100 / _hit_points.hit_points;
    if (percent <= 0) {
      removeFromParent();
      return;
    }
    if (_percent_seen != percent) {
      _show_time = 1;
      _percent_seen = percent;
    }
    if (percent > 60 && _show_time <= 0) return;

    _paint.color = switch (percent) {
      <= 20 => _critical,
      <= 40 => _bad,
      <= 60 => _half,
      _ => _good,
    };
    _paint.style = PaintingStyle.stroke;
    canvas.drawRect(_outline, _paint);
    _paint.style = PaintingStyle.fill;
    _health.right = max(3, min(96, percent));
    canvas.drawRect(_health, _paint);
  }
}

class MarauderGun extends Component with Context {
  MarauderGun(this.source);

  final Marauder source;

  double _cool_down = rng.nextDouble();

  @override
  void update(double dt) {
    if (source._state == MarauderState.exploding) removeFromParent();
    if (source._state == MarauderState.defeated) removeFromParent();
    if (source._state == MarauderState.left) removeFromParent();
    if (source._state != MarauderState.active) return;

    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    _cool_down += 0.4 + rng.nextDoubleLimit(0.9);

    final it = MarauderShot();
    it.position.setFrom(source.position);
    it.x -= 25;
    it.y += 25 / 4;
    stage.add(it);
  }
}

class MarauderShot extends PositionComponent with CollisionCallbacks, HasPaint {
  static const _inner = Color(0xFFa0ffa0);
  static const _outer = Color(0xFF209f20);
  static const _core = Color(0xFFffffff);

  MarauderShot() {
    size.setAll(4);
    add(CircleHitbox(radius: 4, anchor: Anchor.center)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  @override
  void update(double dt) {
    x -= 300 * dt;
    y += 300 / 4 * dt;
    if (x < -100) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    paint.color = _outer;
    canvas.drawCircle(Offset.zero, 3.5, paint);
    paint.color = _inner;
    canvas.drawCircle(Offset.zero, 3, paint);
    paint.color = _core;
    canvas.drawCircle(Offset.zero, 2, paint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other case FriendlyTarget it) {
      if (it.susceptible) {
        it.on_hit(1);
        removeFromParent();
      }
    }
  }
}

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

class MarauderMine extends PositionComponent with CollisionCallbacks, Context, EnemyHitPoints, HasPaint {
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
  void on_destroyed() {
    if (_destroyed) return;
    _destroyed = true;
    decals.spawn(Decal.nuke_explosion, position);
    removeFromParent();
  }

  @override
  void on_hit() {
    super.on_hit();
    decals.spawn(Decal.mini_explosion, position);
    _hit_time += 0.05;
  }

  double _hit_time = 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (_hit_time > 0) _hit_time -= dt;
    entity.sprite.highlight_mode = _hit_time > 0 ? HighlightMode.hit : HighlightMode.none;

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
      }
    }
  }
}

class MinefieldWave extends Component with Context, EnemyWave {
  static const enemies_in_wave = 64;

  MinefieldWave() {
    delay = 3;
  }

  bool _info_shown = false;
  bool _active = false;
  double _next_time = 0;

  @override
  void update(double dt) {
    if (delay > 0) {
      delay -= dt;
      return;
    }
    if (!_info_shown) {
      sendMessage(ShowInfoText(text: 'Approaching Minefield', when_done: () => _active = true));
      _info_shown = true;
      _active = true;
    }
    if (!_active) {
      return;
    }
    if (_wave.length >= enemies_in_wave) {
      defeated = _wave.every((it) => it.isRemoved);
      return;
    }
    if (_next_time > 0) {
      _next_time -= dt;
      return;
    }
    _next_time = 0.2;

    final it = mines.spawn(Vector2(850, -150 + rng.nextDoubleLimit(500)));
    it.then((it) => _wave.add(it));
  }

  final _wave = List<MarauderMine>.empty(growable: true);
}
