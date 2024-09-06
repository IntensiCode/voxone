import 'dart:math';
import 'dart:ui';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_configuration.dart';
import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/game_messages.dart';
import 'package:voxone/game/player/base_weapon.dart';
import 'package:voxone/game/player/player_state.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/keys.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/on_message.dart';
import 'package:voxone/util/shortcuts.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Player extends SpriteComponent with AutoDispose, GameContext, HasAutoDisposeShortcuts, HasVisibility {
  Player(this._sprites1632) : super(anchor: const Anchor(0.5, 0.8)) {
    player = this;
  }

  final SpriteSheet _sprites1632;

  final bounds = MutableRectangle(0.0, 0.0, 0.0, 0.0);

  final fire_dir = Vector2.zero();
  final move_dir = Vector2.zero();
  final _temp_move = Vector2.zero();
  final _check_pos = Vector2.zero();
  final _last_free = Vector2.zero();

  late final Keys _keys;

  late TiledMap _map;

  var state = PlayerState.gone;
  var _state_progress = 0.0;
  double _anim_time = 0;
  double show_firing = 0;
  double move_speed = configuration.player_move_speed;

  BaseWeapon? active_weapon;

  void reset(PlayerState reset_state) {
    logInfo('reset player: $reset_state');
    state = reset_state;
    _state_progress = 0.0;
    position.setValues(center_x, game_height + height);
  }

  @override
  bool get isVisible => state != PlayerState.gone;

  @override
  Future onLoad() async {
    super.onLoad();

    paint = pixel_paint();
    paint.style = PaintingStyle.stroke;

    _keys = keys;
    this.sprite = _sprites1632.getSpriteById(0);

    onMessage<EnterRound>((_) => reset(PlayerState.gone));
    onMessage<GameComplete>((_) => _on_level_complete());
    onMessage<LevelComplete>((_) => _on_level_complete());
    onMessage<LevelDataAvailable>((it) => _map = it.map);
    onMessage<LevelReady>((_) => reset(PlayerState.entering));
  }

  void _on_level_complete() => state = PlayerState.leaving;

  @override
  void update(double dt) {
    super.update(dt);
    switch (state) {
      case PlayerState.gone:
        break;
      case PlayerState.entering:
        _on_entering(dt);
        _update(dt);
      case PlayerState.leaving:
        _on_leaving(dt);
        _update(dt);
      case PlayerState.dying:
        _on_dying(dt);
      case PlayerState.playing:
        // if (phase != GamePhase.game_on) return;
        _on_move_player(dt);
        _update(dt);
    }
  }

  void _on_entering(double dt) {
    _state_progress += dt;
    if (dev) _state_progress += dt * 3;
    if (_state_progress > 1.0) {
      move_dir.setZero();
      _state_progress = 1.0;
      state = PlayerState.playing;
      sendMessage(PlayerReady());
    } else {
      move_dir.setValues(0, -1);
      if (dev) move_dir.setValues(0, -4);
    }
  }

  void _update(double dt) {
    final moving = !move_dir.isZero();
    if (moving) {
      fire_dir.setFrom(move_dir);
      _animate_movement(dt);
    }

    _update_position(dt);
    _update_sprite();

    show_firing -= min(show_firing, dt);
  }

  void _animate_movement(double dt) {
    _anim_time += dt * 2.5;
    if (_anim_time >= 1) _anim_time -= 1;
  }

  void _update_position(double dt) {
    _temp_move.setFrom(move_dir);
    _temp_move.scale(move_speed * dt);
    position.add(_temp_move);

    priority = position.y.toInt() + 1;

    final top = -(_map.height - 15) * 16.0;
    _temp_move.setValues(0, (position.y - 128).clamp(top, 0.0));

    _temp_move.y = _temp_move.y.roundToDouble();
    game.camera.moveTo(_temp_move);

    bounds.left = position.x - 7;
    bounds.top = position.y - height * 1.25;
    bounds.width = 14;
    bounds.height = height * 1.5;

    for (final it in entities.consumables) {
      if (it.isRemoving || it.isRemoved) continue;
      if (!it.is_hit_by(position)) continue;
      model.particles.spawn_sparkles_for(it);
      soundboard.play(Sound.collect);
      it.removeFromParent();
      sendMessage(Collected(it));
      break;
    }
  }

  void _update_sprite() {
    final frame = (_anim_time * 4).toInt().clamp(0, 3);

    var offset = 0;
    if (fire_dir.y == 0) {
      if (fire_dir.x < 0) offset = 8;
      if (fire_dir.x > 0) offset = 12;
    }
    if (fire_dir.y < 0) offset = 0;
    if (fire_dir.y > 0) offset = 4;

    final weapon = active_weapon?.type.index ?? 0;
    final firing = show_firing > 0 ? 16 : 0;
    this.sprite = _sprites1632.getSprite(12 + weapon, 16 + offset + frame + firing);
  }

  void _on_leaving(double dt) {
    _state_progress -= dt;
    if (_state_progress < 0.0) {
      paint.color = transparent;
      _state_progress = 0.0;
      reset(PlayerState.gone);
    }
  }

  void _on_dying(double dt) {
    _state_progress += dt;
    if (_state_progress > 1.0) {
      _state_progress = 0.0;
      state = PlayerState.gone;
      sendMessage(PlayerDied());
    }
  }

  void _on_move_player(double dt) {
    move_dir.setZero();

    if (_keys.check(GameKey.left)) move_dir.x -= 1;
    if (_keys.check(GameKey.right)) move_dir.x += 1;
    if (_keys.check(GameKey.up)) move_dir.y -= 1;
    if (_keys.check(GameKey.down)) move_dir.y += 1;

    _try_move(dt);
  }

  void _try_move(double dt) {
    move_dir.normalize();

    _temp_move.setFrom(move_dir);
    _temp_move.scale(configuration.player_move_speed * dt);
    _check_pos.setFrom(position);
    _check_pos.add(_temp_move);

    bounds.left = _check_pos.x - 7;
    bounds.top = _check_pos.y;
    bounds.width = 14;
    bounds.height = height * 0.125;

    for (final it in entities.obstacles) {
      if (it.is_blocked_for_walking(bounds)) {
        if (move_dir.x != 0 && move_dir.y != 0) {
          final remember_y = move_dir.y;

          move_dir.y = 0;
          move_dir.x = move_dir.x.sign;
          _try_move(dt);

          if (move_dir.isZero()) {
            move_dir.y = remember_y.sign;
            move_dir.x = 0;
            _try_move(dt);
          }

          return;
        }
        move_dir.setZero();
        position.setFrom(_last_free);
        priority = position.y.toInt() + 1;
        return;
      }
    }

    _last_free.setFrom(_check_pos);
  }
}
