import 'package:flame/components.dart';
import 'package:voxone/game/shared/game_phase.dart';
import 'package:voxone/game/shared/game_state.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/stage_cache.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/keys.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/shortcuts.dart';

abstract class GameScreen extends GameScriptComponent with HasAutoDisposeShortcuts, HasVisibility, Pixelate {
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

  @override
  bool get is_active => phase == GamePhase.playing;

  @override
  void updateTree(double dt) {
    if (!isVisible) return;
    // if (phase != GamePhase.playing) return;
    super.updateTree(dt);
  }
}
