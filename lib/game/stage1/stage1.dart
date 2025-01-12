import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/game/player/acid_blast.dart';
import 'package:voxone/game/player/plasma_blob.dart';
import 'package:voxone/game/player/zaxxon_hud.dart';
import 'package:voxone/game/player/zaxxon_player.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/enemy_explosion.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/game_phase.dart';
import 'package:voxone/game/shared/game_screen.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/info_overlay.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage1/enemies_stage1.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/on_message.dart';

class Stage1 extends GameScreen with HasContext {
  late InfoOverlay info_overlay;

  @override
  onLoad() async {
    await add(space);
    await add(decals);
    await add(extras);
    await add(mines);
    await add(info_overlay = InfoOverlay());

    await AcidBlast.preload();
    await PlasmaBlob.preload();
    await DeflectorShield.preload();
    await EnemyExplosion.preload();
  }

  void _change_phase(GamePhase phase) {
    logInfo(phase);
    switch (phase) {
      case GamePhase.show_stage:
        sendMessage(ShowInfoText(
          title: 'Stage 1',
          text: 'Approaching Planet Voxone',
          when_done: () => _change_phase(GamePhase.intro),
        ));

      case GamePhase.intro:
        cache['player'] = ZaxxonPlayer();
        add(shadows);
        add(player as Component);
        add(ZaxxonHud(player));
        shadows.isVisible = false;

      case GamePhase.playing:
        add(EnemiesStage1());

      case GamePhase.complete:
        for (final it in children) {
          if (it is Hostile) it.fadeOutDeep();
          if (it is ZaxxonHud) it.fadeOutDeep();
        }
        sendMessage(ShowInfoText(
          title: 'Stage Complete',
          text: 'Prepare for next challenge',
          stay_longer: true,
          when_done: () => showScreen(Screen.title),
        ));

      case GamePhase.game_over:
        for (final it in children) {
          if (it is Hostile) it.fadeOutDeep();
          if (it is ZaxxonHud) it.fadeOutDeep();
        }
        sendMessage(ShowInfoText(
          title: 'Game Over',
          text: 'All Hope Is Lost',
          stay_longer: true,
          when_done: () => showScreen(Screen.title),
        ));
    }
  }

  @override
  void onMount() {
    super.onMount();

    onMessage<GamePhaseUpdate>((it) => _change_phase(it.phase));
    onMessage<EnemiesDefeated>((it) => _change_phase(GamePhase.complete));
    onMessage<PlayerDestroyed>((it) => _change_phase(GamePhase.game_over));
    onMessage<PlayerReady>((it) => _change_phase(GamePhase.playing));

    info_overlay.mounted.then((_) => _change_phase(phase));
  }

  @override
  void onRemove() {
    super.onRemove();
    cache.dispose();
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (phase) {
      case GamePhase.show_stage:
        break; // waiting for ShowInfoText

      case GamePhase.intro:
        break; // waiting for PlayerReady

      case GamePhase.playing:
        break; // waiting for EnemiesDefeated

      case GamePhase.complete:
        break; // waiting for ShowInfoText

      case GamePhase.game_over:
        break; // waiting for ShowInfoText
    }
  }
}
