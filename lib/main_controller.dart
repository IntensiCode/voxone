import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:voxone/aural/audio_menu.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/visual.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/stage1/stage1.dart';
import 'package:voxone/game/stage2.dart';
import 'package:voxone/game/stage3.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/title_screen.dart';
import 'package:voxone/ui/controls.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/on_message.dart';
import 'package:voxone/web_play_screen.dart';

class MainController extends World
    with AutoDispose, HasAutoDisposeShortcuts, HasCollisionDetection<Sweep<ShapeHitbox>>
    implements ScreenNavigation {
  //
  final _stack = <Screen>[];

  @override
  onLoad() async {
    visual.load();
    autoDispose("ShowScreen", messaging.listen<ShowScreen>((it) => showScreen(it.screen)));
  }

  @override
  void onMount() {
    if (dev && !kIsWeb) {
      showScreen(Screen.stage1);
    } else {
      add(WebPlayScreen());
    }

    onMessage<ToggleCheatMode>((_) => _toggle_cheat_mode());
    _toggle_cheat_mode();
  }

  void _toggle_cheat_mode() {
    if (dev) {
      logInfo('activate cheat keys');

      onKeys(['<A-a>', '8'], () => pushScreen(Screen.audio));
      onKeys(['<A-c>', '9'], () => pushScreen(Screen.controls));
      onKeys(['<A-t>', '0'], () => showScreen(Screen.title));

      onKey('1', () => showScreen(Screen.stage1));
      onKey('2', () => showScreen(Screen.stage2));
      onKey('3', () => showScreen(Screen.stage3));

      onKeys(['<A-d>', '='], () {
        visual.debug = !visual.debug;
        logInfo('debug = ${visual.debug}');
      });
    } else {
      disposeWhereTag((it) => it.startsWith('onKey-'));
    }
  }

  @override
  void popScreen() {
    logInfo('pop screen with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    showScreen(_stack.removeLastOrNull() ?? Screen.title);
  }

  @override
  void pushScreen(Screen it) {
    logInfo('push screen $it with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    logInfo('triggered: $_triggered');
    if (_stack.lastOrNull == it) throw 'stack already contains $it';
    // _stack.add(it);
    if (_triggered != null) _stack.add(_triggered!);
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
      if (!skip_fade_in) {
        it.mounted.then((_) => it.fadeInDeep());
      }
      messaging.send(ScreenShowing(screen));
    }
  }

  Component _makeScreen(Screen it) => switch (it) {
        Screen.audio => AudioMenu(show_back: true),
        Screen.controls => Controls(),
        Screen.stage1 => Stage1(),
        Screen.stage2 => Stage2(),
        Screen.stage3 => Stage3(),
        Screen.title => TitleScreen(),
      };
}
