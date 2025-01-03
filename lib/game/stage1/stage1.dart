import 'package:dart_minilog/dart_minilog.dart';
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
import 'package:voxone/game/stage1/enemies_stage1.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/on_message.dart';

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
        at(dev ? 0.5 : 2.0, () => t1.fadeOutDeep());
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
        if (_show_time >= (dev ? 0.5 : 2.5)) {
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
