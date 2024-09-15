import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/screens.dart';
import 'package:voxone/game/stage1.dart';
import 'package:voxone/game/stage2.dart';
import 'package:voxone/game/stage3.dart';
import 'package:voxone/game/visual.dart';
import 'package:voxone/title_screen.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/shortcuts.dart';
import 'package:voxone/web_play_screen.dart';

class MainController extends World
    with AutoDispose, HasAutoDisposeShortcuts, HasCollisionDetection<Sweep<ShapeHitbox>>
    implements ScreenNavigation {
  //
  final _stack = <Screen>[];

  @override
  onLoad() async {
    visual.load();
    messaging.listen<ShowScreen>((it) => showScreen(it.screen));
  }

  @override
  void onMount() {
    if (dev && !kIsWeb) {
      showScreen(Screen.stage1);
    } else if (kIsWeb) {
      add(WebPlayScreen());
    } else {
      add(TitleScreen());
    }

    if (dev) {
      onKey('<C-1>', () => showScreen(Screen.stage1));
      onKey('<C-2>', () => showScreen(Screen.stage2));
      onKey('<C-3>', () => showScreen(Screen.stage3));
      onKey('<C-d>', () {
        visual.debug = !visual.debug;
        logInfo('debug = ${visual.debug}');
      });
      onKey('<C-v>', () {
        visual.pixelate_screen = !visual.pixelate_screen;
        logInfo('pixelate_screen = ${visual.pixelate_screen}');
      });
    }

    onKey('<C-t>', () => showScreen(Screen.title));
  }

  @override
  void popScreen() {
    logVerbose('pop screen with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    _stack.removeLastOrNull();
    showScreen(_stack.lastOrNull ?? Screen.stage1);
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
      if (screen != Screen.stage1 && !skip_fade_in) {
        it.mounted.then((_) => it.fadeInDeep());
      }
    }
  }

  Component _makeScreen(Screen it) => switch (it) {
        Screen.stage1 => Stage1(),
        Screen.stage2 => Stage2(),
        Screen.stage3 => Stage3(),
        Screen.title => TitleScreen(),
      };
}
