import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_phase.dart';
import 'package:voxone/game/game_screen.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/game/player.dart';
import 'package:voxone/game/shadows.dart';
import 'package:voxone/game/space.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/on_message.dart';

class Stage1 extends GameScreen {
  double _show_time = 0;

  @override
  onLoad() async {
    add(Space());
    _change_phase(phase);
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
        final player = HorizontalPlayer();
        add(player);
        add(HorizontalExhaust(player));
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
  @override
  void update(double dt) {}
}
