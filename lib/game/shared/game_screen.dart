import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/player/zaxxon_player.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/game_phase.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/shared/stage_cache.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/input/keys.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/ui/soft_keys.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/on_message.dart';
import 'package:voxone/util/stacked_sprite.dart';

abstract class GameScreen extends GameScriptComponent with HasAutoDisposeShortcuts, HasTimeScale, HasVisibility {
  GameScreen() {
    add(stage_keys);
    add(stage_cache);
  }

  final stage_keys = Keys();
  final stage_cache = StageCache();

  GamePhase _phase = GamePhase.show_stage;

  GamePhase get phase => _phase;

  set phase(GamePhase value) {
    if (_phase == value) return;
    _phase = value;
    sendMessage(GamePhaseUpdate(_phase));
  }

  bool _paused = false;

  @override
  void onMount() {
    super.onMount();

    onMessage<UpdateDifficulty>((_) => _update_time_scale());
    _update_time_scale();

    if (dev) {
      onKey('-', () => _change_time_scale(-0.25));
      onKey('+', () => _change_time_scale(0.25));
      onKey('<C-k>', () => stacked_cache.clear());
      onKey('<C-j>', () => logInfo('cache size: ${stacked_cache.size}'));
    }

    stage_keys.game_pad_mapping = true;

    apply_video_mode();
  }

  @override
  void onRemove() {
    super.onRemove();
    stage_keys.game_pad_mapping = false;
  }

  void _update_time_scale() {
    timeScale = switch (difficulty) {
      Difficulty.easy => 1.2,
      Difficulty.normal => 1.4,
      Difficulty.hard => 1.6,
    };
  }

  void _change_time_scale(double delta) {
    timeScale += delta;
    logInfo('Time scale: ${timeScale.toStringAsFixed(2)}');
    if (timeScale < 0.25) timeScale = 0.25;
    if (timeScale > 4.0) timeScale = 4.0;
    sendMessage(ShowInfoText(text: 'Time scale: ${timeScale.toStringAsFixed(2)}', title: 'Cheat'));
  }

  @override
  void update(double dt) {
    if (stage_cache.has('player')) {
      final player = stage_cache['player'] as ZaxxonPlayer;
      if (player.is_dead_or_dying()) {
        _update_time_scale();
        timeScale *= 0.5;
      }
    }

    super.update(dt);
    if (stage_keys.any([GameKey.start, GameKey.soft1])) {
      if (!_paused) {
        _paused = true;
        add(_pause_overlay);
      }
    }
  }

  late final _pause_overlay = _PauseOverlay(() => _paused = false);

  @override
  void updateTree(double dt) {
    if (!isVisible) return;
    if (_paused) {
      _pause_overlay.update(dt);
      stage_keys.update(dt);
      return;
    }
    super.updateTree(dt);
  }

  @override
  void renderTree(Canvas canvas) {
    cache_remove_count = 0;
    StackedSprite.render_count = 0;
    super.renderTree(canvas);
    if (dev) {
      if (cache_remove_count > 0) {
        logInfo('cache remove count: $cache_remove_count');
      }
      if (StackedSprite.render_count >= StackedSprite.max_renders_per_frame) {
        logInfo('stacked sprite render count: ${StackedSprite.render_count}');
      }
    }
  }
}

class _PauseOverlay extends GameScriptComponent with HasContext {
  _PauseOverlay(this.on_resume) {
    add(RectangleComponent(size: game_size)..paint.color = const Color(0x80000000));
    add(BitmapText(text: 'PAUSED', position: game_center, font: menu_font, anchor: Anchor.center));
    softkeys('Resume', 'Exit', (it) {
      if (it == SoftKey.left) _resume();
      if (it == SoftKey.right) _back_to_title();
    });
    priority = 1000000;
  }

  void _resume() {
    logInfo('Resuming');
    removeFromParent();
    on_resume();
  }

  void _back_to_title() {
    logInfo('Exiting to title');
    showScreen(Screen.title);
    _resume();
  }

  final Function on_resume;

  @override
  void update(double dt) {
    super.update(dt);
    if (keys.check_and_consume(GameKey.a_button)) _resume();
    if (keys.check_and_consume(GameKey.b_button)) _resume();
    if (game_pad_config == GamePadConfig.Default) {
      if (keys.check_and_consume(GameKey.select)) _back_to_title();
      if (keys.check_and_consume(GameKey.start)) _resume();
    }
    if (keys.check_and_consume(GameKey.soft1)) _resume();
    if (keys.check_and_consume(GameKey.soft2)) _back_to_title();
  }
}
