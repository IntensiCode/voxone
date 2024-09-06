import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import 'core/common.dart';
import 'core/screens.dart';
import 'game/game_dialog.dart';
import 'game/game_state.dart';
import 'game/soundboard.dart';
import 'help_screen.dart';
import 'util/bitmap_button.dart';
import 'util/delayed.dart';
import 'util/effects.dart';
import 'util/extensions.dart';
import 'util/game_script.dart';
import 'util/shortcuts.dart';

class TitleScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  static const x = game_width;

  static bool seen = false;
  static bool music = false;
  static bool first_time_playing = false;

  @override
  onLoad() async {
    if (help_triggered_at_first_start) {
      help_triggered_at_first_start = false;
      if (music) soundboard.fade_out_music();
      showScreen(Screen.game);
      return;
    }

    fadeIn(await spriteXY('title.png', center_x, center_y));

    final delta = seen ? 0.0 : 0.2;
    // at(delta, () async => await add(fadeIn(await _video())));
    at(delta, () async => await add(fadeIn(await _hiscore())));
    at(delta, () async => await add(fadeIn(await _audio())));
    at(delta, () async => await add(fadeIn(await _credits())));
    // at(delta, () async => await add(fadeIn(await _controls())));
    at(delta, () async => await added(await _insert_coin()).add(BlinkEffect()));

    try {
      await state.preload();
    } catch (ignored) {
      logError('error loading game state: $ignored');
    }

    try {
      first_time_playing = await first_time();
      logInfo('first time playing? $first_time_playing');
      if (first_time_playing || state.level_number_starting_at_1 == 1) {
        await state.delete();
        state.reset();
      }
    } catch (ignored) {
      logError('error loading first time playing state: $ignored');
    }
  }

  @override
  void onMount() {
    super.onMount();
    if (!seen) music = true;

    final play_jingle = !seen;
    soundboard.preload().then((_) {
      if (play_jingle) soundboard.play_one_shot_sample('commando.ogg');
    });

    if (!seen) add(Delayed(1.0, () => soundboard.play_music('music/title.ogg')));

    seen = true;
  }

  // Implementation

  void _showScreen(Screen it) {
    if (children.whereType<GameDialog>().isNotEmpty) return;

    if (it == Screen.game) {
      if (state.level_number_starting_at_1 > 1) {
        // add(GameDialog(
        //   {
        //     GameKey.soft1: () async {
        //       await state.delete();
        //       await state.reset();
        //       if (music) soundboard.fade_out_music();
        //       showScreen(Screen.game);
        //     },
        //     GameKey.soft2: () {
        //       if (music) soundboard.fade_out_music();
        //       showScreen(Screen.game);
        //     },
        //   },
        //   'Game in progress.\n\nResume game?\n\nOr start new game?',
        //   'New Game',
        //   'Resume Game',
        //   flow_text: true,
        //   shortcuts: true,
        // ));
        // return;
      } else if (false && first_time_playing) {
        help_triggered_at_first_start = true;
        showScreen(Screen.help);
        return;
      }
    }

    if (it == Screen.game) if (music) soundboard.fade_out_music();
    showScreen(it);
  }

  Future<BitmapButton> _hiscore() => button(
        text: '   Hiscore   ',
        position: Vector2(x, 80),
        anchor: Anchor.topRight,
        shortcuts: ['h'],
        onTap: (_) => _showScreen(Screen.hiscore),
      );

  Future<BitmapButton> _audio() => button(
        text: '     Audio     ',
        position: Vector2(x, 125),
        anchor: Anchor.centerRight,
        shortcuts: ['a'],
        onTap: (_) => _showScreen(Screen.audio_menu),
      );

  Future<BitmapButton> _credits() => button(
        text: '   Credits   ',
        position: Vector2(x, 160),
        anchor: Anchor.centerRight,
        shortcuts: ['c'],
        onTap: (_) => _showScreen(Screen.credits),
      );

  // Future<BitmapButton> _controls() async => await button(
  //   text: 'How To Play',
  //   position: Vector2(x, y),
  //   anchor: Anchor.topRight,
  //   shortcuts: ['p', '?'],
  //   onTap: (_) => _showScreen(Screen.help),
  // );
  //
  // Future<BitmapButton> _video() => button(
  //   text: '     Video     ',
  //   position: Vector2(x, y + 48),
  //   anchor: Anchor.centerRight,
  //   shortcuts: ['v'],
  //   onTap: (_) => _showScreen(Screen.options),
  // );

  Future<BitmapButton> _insert_coin() => button(
        text: 'Insert coin',
        fontScale: 2,
        position: Vector2(center_x, 0),
        anchor: Anchor.topCenter,
        shortcuts: ['<Space>'],
        onTap: (_) => _showScreen(Screen.game),
      );
}
