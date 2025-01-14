import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/background/ground.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/common.dart';
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
import 'package:voxone/game/stage1/appearing_moon.dart';
import 'package:voxone/game/stage1/enemies_stage1.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/input/game_keys.dart';
import 'package:voxone/util/effects.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/on_message.dart';

class Stage1 extends GameScreen with HasContext {
  late InfoOverlay info_overlay;
  late AppearingMoon _moon;
  bool _transition_ready = false;

  @override
  onLoad() async {
    await add(space);
    await add(decals);
    await add(explosions);
    await add(extras);
    await add(mines);
    await add(info_overlay = InfoOverlay());

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

  @override
  void update(double dt) {
    super.update(dt);
    if (phase != GamePhase.transition || !_transition_ready) return;

    if (stage_keys.any([GameKey.a_button, GameKey.b_button, GameKey.start, GameKey.soft2])) {
      _transition_ready = false;
      _moon.finish_zoom = true;
      add(ground..fadeInDeep(seconds: 2));

      clearScript();
      after(2.0, () => showScreen(Screen.stage2, transition: ScreenTransition.switch_in_place));
    }
  }

  void _change_phase(GamePhase target) {
    phase = target;

    logInfo(phase);
    switch (phase) {
      case GamePhase.show_stage:
        sendMessage(ShowInfoText(
          title: 'Stage 1',
          text: 'Approaching Planet Voxone',
          when_done: () => phase = GamePhase.intro,
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
        info_overlay.removeFromParent();

        clearScript();
        after(0.0, () => _moon = added(AppearingMoon()));
        after(AppearingMoon.grow_time, () {
          textXY(
            'Press any button to continue',
            game_width / 2,
            game_height - 32,
            anchor: Anchor.bottomCenter,
          ).add(BlinkEffect());
          _transition_ready = true;
        });
        executeScript();
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
