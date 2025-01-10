import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/game_phase.dart';
import 'package:voxone/game/shared/game_state.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/shared/stage_cache.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/ui/soft_keys.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/keys.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/shortcuts.dart';
import 'package:voxone/util/stacked_sprite.dart';

abstract class GameScreen extends GameScriptComponent with HasAutoDisposeShortcuts, HasVisibility {
  GameScreen() {
    add(stage_keys);
    add(stage_cache);
  }

  final stage_keys = Keys();
  final stage_cache = StageCache();

  final state = GameState.instance;

  GamePhase _phase = GamePhase.show_stage;

  GamePhase get phase => _phase;

  set phase(GamePhase value) {
    if (_phase == value) return;
    _phase = value;
    sendMessage(GamePhaseUpdate(_phase));
  }

  bool _paused = false;

  @override
  bool get is_active => phase == GamePhase.playing;

  @override
  void update(double dt) {
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
      return;
    }
    super.updateTree(dt);
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
    if (keys.check_and_consume(GameKey.soft1)) _resume();
    if (keys.check_and_consume(GameKey.soft2)) _back_to_title();
  }
}
