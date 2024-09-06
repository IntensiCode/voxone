import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'audio_menu_screen.dart';
import 'core/common.dart';
import 'core/screens.dart';
import 'credits_screen.dart';
import 'enter_hiscore_screen.dart';
import 'game/game_screen.dart';
import 'game/visual_configuration.dart';
import 'help_screen.dart';
import 'hiscore_screen.dart';
import 'options_screen.dart';
import 'splash_screen.dart';
import 'the_end_screen.dart';
import 'title_screen.dart';
import 'util/auto_dispose.dart';
import 'util/extensions.dart';
import 'util/messaging.dart';
import 'util/shortcuts.dart';
import 'web_play_screen.dart';

class MainController extends World with AutoDispose, HasAutoDisposeShortcuts implements ScreenNavigation {
  final _stack = <Screen>[];

  @override
  onLoad() async => messaging.listen<ShowScreen>((it) => showScreen(it.screen));

  @override
  void onMount() {
    if (dev && !kIsWeb) {
      showScreen(Screen.game);
    } else if (kIsWeb) {
      add(WebPlayScreen());
    } else {
      add(SplashScreen());
    }
    onKey('<A-a>', () => showScreen(Screen.audio_menu));
    onKey('<A-c>', () => showScreen(Screen.credits));
    onKey('<A-e>', () => showScreen(Screen.the_end));
    onKey('<A-h>', () => showScreen(Screen.hiscore));
    onKey('<A-s>', () => showScreen(Screen.splash, skip_fade_in: true));
    onKey('<A-l>', () => showScreen(Screen.splash, skip_fade_in: true));
    onKey('<A-t>', () => showScreen(Screen.title));
  }

  @override
  void popScreen() {
    logVerbose('pop screen with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    _stack.removeLastOrNull();
    showScreen(_stack.lastOrNull ?? Screen.title);
  }

  @override
  void pushScreen(Screen it) {
    logVerbose('push screen $it with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    if (_stack.lastOrNull == it) throw 'stack already contains $it';
    _stack.add(it);
    showScreen(it);
  }

  Screen? _triggered;
  StackTrace? _previous;

  @override
  void showScreen(Screen screen, {bool skip_fade_out = false, bool skip_fade_in = false}) {
    if (_triggered == screen) {
      logError('duplicate trigger ignored: $screen', StackTrace.current);
      logError('previous trigger', _previous);
      return;
    }
    _triggered = screen;
    _previous = StackTrace.current;

    if (skip_fade_out) logInfo('show $screen');
    logVerbose('screen stack: $_stack');
    logVerbose('children: ${children.map((it) => it.runtimeType)}');

    if (!skip_fade_out && children.isNotEmpty) {
      children.last.fadeOutDeep(and_remove: true);
      children.last.removed.then((_) {
        if (_triggered == screen) {
          _triggered = null;
        } else if (_triggered != screen) {
          return;
        }
        logInfo('show $screen');
        showScreen(screen, skip_fade_out: skip_fade_out, skip_fade_in: skip_fade_in);
      });
    } else {
      final it = added(_makeScreen(screen));
      if (screen != Screen.game && !skip_fade_in) {
        it.mounted.then((_) => it.fadeInDeep());
      }
    }
  }

  Component _makeScreen(Screen it) => switch (it) {
        Screen.audio_menu => AudioMenuScreen(),
        Screen.credits => CreditsScreen(),
        Screen.enter_hiscore => EnterHiscoreScreen(),
        Screen.game => GameScreen(),
        Screen.help => HelpScreen(),
        Screen.hiscore => HiscoreScreen(),
        Screen.options => OptionsScreen(),
        Screen.splash => SplashScreen(),
        Screen.the_end => TheEndScreen(),
        Screen.title => TitleScreen(),
      };

  @override
  void renderTree(Canvas canvas) {
    // visual.pixelate_screen = true;
    if (visual.pixelate_screen) {
      final recorder = PictureRecorder();
      super.renderTree(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(game_width ~/ 1, game_height ~/ 1);
      canvas.drawImage(image, Offset.zero, pixel_paint());
      image.dispose();
      picture.dispose();
    } else {
      super.renderTree(canvas);
    }
  }
}
