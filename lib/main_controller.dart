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
  void showScreen(
    Screen screen, {
    ScreenTransition transition = ScreenTransition.fade_out_then_in,
  }) {
    if (_triggered == screen) {
      logError('show $screen with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
      logError('duplicate trigger ignored: $screen', StackTrace.current);
      logError('previous trigger', _previous);
      return;
    }
    _triggered = screen;
    _previous = StackTrace.current;

    if (children.length > 1) {
      3.forEach((_) {
        logWarn('show $screen with stack=$_stack and more than one children=${children.map((it) => it.runtimeType)}');
      });
    }

    void call_again() {
      // still the same? you never know.. :]
      if (_triggered == screen) {
        _triggered = null;
        showScreen(screen, transition: transition);
      } else {
        logWarn('triggered screen changed: $screen != $_triggered');
        logWarn('show $screen with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
      }
    }

    final out = children.lastOrNull;
    if (out != null) {
      switch (transition) {
        case ScreenTransition.cross_fade:
          out.fadeOutDeep(and_remove: true);
          break;
        case ScreenTransition.fade_out_then_in:
          out.fadeOutDeep(and_remove: true);
          out.removed.then((_) => call_again());
          return;
        case ScreenTransition.switch_in_place:
          out.removeFromParent();
          break;
        case ScreenTransition.remove_then_add:
          out.removeFromParent();
          out.removed.then((_) => call_again());
          return;
      }
    }

    final it = added(_makeScreen(screen));
    switch (transition) {
      case ScreenTransition.cross_fade:
        it.mounted.then((_) => it.fadeInDeep());
        break;
      case ScreenTransition.fade_out_then_in:
        it.mounted.then((_) => it.fadeInDeep());
        break;
      case ScreenTransition.switch_in_place:
        break;
      case ScreenTransition.remove_then_add:
        break;
    }

    messaging.send(ScreenShowing(screen));
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
