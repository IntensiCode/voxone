import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/background/ground.dart';
import 'package:stardash/game/enemies/marauder_mines.dart';
import 'package:stardash/game/player/projectiles/plasma_blob.dart';
import 'package:stardash/game/player/zaxxon_hud.dart';
import 'package:stardash/game/player/zaxxon_player.dart';
import 'package:stardash/game/shared/decals.dart';
import 'package:stardash/game/shared/deflector_shield.dart';
import 'package:stardash/game/shared/enemy_explosion.dart';
import 'package:stardash/game/shared/enemy_wave.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/game_phase.dart';
import 'package:stardash/game/shared/game_screen.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/info_overlay.dart';
import 'package:stardash/game/shared/messages.dart';
import 'package:stardash/game/shared/screens.dart';
import 'package:stardash/game/shared/shadows.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/game/stage1/enemies_stage1.dart';
import 'package:stardash/game/stage2/enemies_stage2.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/on_message.dart';

class Stage2 extends GameScreen with HasContext {
  late InfoOverlay info_overlay;

  @override
  onLoad() async {
    await add(ground);
    await add(decals);
    await add(explosions);
    await add(extras);
    await add(mines);
    await add(shadows);
    await add(info_overlay = InfoOverlay(() => timeScale));

    await PlasmaBlob.preload();
    await DeflectorShield.preload();
  }

  @override
  void onMount() {
    super.onMount();

    info_overlay.mounted.then((_) => _change_phase(phase));
    onMessage<GamePhaseUpdate>((it) => _change_phase(it.phase));
    onMessage<EnemiesDefeated>((it) => phase = GamePhase.complete);
    onMessage<PlayerDestroyed>((it) => phase = GamePhase.game_over);
    onMessage<PlayerReady>((it) => phase = GamePhase.playing);

    onKey('<A-q>', () => phase = GamePhase.complete);
  }

  @override
  void onRemove() {
    super.onRemove();
    cache.dispose();
  }

  void _change_phase(GamePhase target) {
    phase = target;

    logInfo(phase);
    switch (phase) {
      case GamePhase.show_stage:
        sendMessage(ShowInfoText(
          title: 'Stage 2',
          text: 'Across Moon Voxar',
          when_done: () => phase = GamePhase.intro,
        ));

      case GamePhase.intro:
        sendMessage(ShowInfoText(
          title: 'Not Implemented Yet',
          text: 'Work In Progress - Stay Tuned',
          stay_longer: true,
        ));

        cache['player'] = ZaxxonPlayer();
        add(shadows);
        add(player as Component);
        add(ZaxxonHud(player));
        shadows.isVisible = true;

      case GamePhase.playing:
        add(EnemiesStage2());
        break;

      case GamePhase.complete:
        _clear_hostiles();

        sendMessage(ShowInfoText(
          title: 'Stage Complete',
          text: 'Prepare for next challenge',
          stay_longer: true,
          when_done: () => phase = GamePhase.transition,
        ));

      case GamePhase.game_over:
        _clear_hostiles();

        sendMessage(ShowInfoText(
          title: 'Game Over',
          text: 'All Hope Is Lost',
          stay_longer: true,
          when_done: () => showScreen(Screen.title),
        ));

      case GamePhase.transition:
        break;
    }
  }

  void _clear_hostiles() {
    children.whereType<EnemiesStage1>().forEach((it) => it.removeFromParent());
    children.whereType<EnemyWave>().forEach((it) => it.removeFromParent());
    for (final it in children) {
      if (it is Hostile) it.fadeOutDeep();
      if (it is ZaxxonHud) it.fadeOutDeep();
    }
  }
}
