import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:voxone/aural/audio_menu.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/credits.dart';
import 'package:voxone/game/enemies/marauder_captain.dart';
import 'package:voxone/game/shared/configuration.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/stage1/stage1.dart';
import 'package:voxone/game/stage2/stage2.dart';
import 'package:voxone/game/stage3.dart';
import 'package:voxone/input/controls.dart';
import 'package:voxone/input/select_game_pad.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/title_screen.dart';
import 'package:voxone/ui/flow_text.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/bitmap_button.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/nine_patch_image.dart';
import 'package:voxone/video_menu.dart';
import 'package:voxone/web_play_screen.dart';

class MainController extends World
    with AutoDispose, HasAutoDisposeShortcuts, HasCollisionDetection<Sweep<ShapeHitbox>>, TapCallbacks
    implements ScreenNavigation {
  //
  @override
  bool get is_active => children.singleOrNull?.runtimeType != SelectGamePad;

  final _stack = <Screen>[];

  @override
  onLoad() async {
    super.onLoad();
    await configuration.load();
    autoDispose("ShowScreen", messaging.listen<ShowScreen>((it) => showScreen(it.screen)));
  }

  @override
  void onMount() {
    super.onMount();

    if (dev) {
      showScreen(Screen.title);
    } else {
      add(WebPlayScreen());
    }

    if (dev) {
      onKeys(['<A-d>', '='], (_) {
        debug = !debug;
        sendMessage(ShowInfoText(title: 'Cheat', text: 'Hitbox Debug Mode: $debug'));
      });

      onKeys(['<A-a>', '8'], (_) => pushScreen(Screen.audio));
      onKeys(['<A-c>', '9'], (_) => pushScreen(Screen.controls));
      onKeys(['<A-t>', '0'], (_) => showScreen(Screen.title));
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
        Screen.audio => AudioMenu(),
        Screen.controls => Controls(),
        Screen.credits => Credits(),
        Screen.select_game_pad => SelectGamePad(),
        Screen.stage1 => Stage1(),
        Screen.stage2 => Stage2(),
        Screen.stage3 => Stage3(),
        Screen.title => TitleScreen(),
        Screen.video => VideoMenu(),
      };

  @override
  void onTapUp(TapUpEvent event) {
    if (!dev) return;

    game.world.children.whereType<Inspector>().forEach((it) => it.removeFromParent());

    for (final it in descendants(reversed: true).whereType<PositionComponent>()) {
      if (it is Hitbox) continue;
      if (it is Inspector) continue;
      if (it is FlowText && it.parent is Inspector) continue;
      if (it is NinePatchComponent && it.parent?.parent is Inspector) continue;
      if (it.containsPoint(event.localPosition)) {
        final t = !it.debugMode;
        for (final d in it.descendants(includeSelf: true)) {
          d.debugMode = t;
        }
        if (it is Snapshot) it.clearSnapshot();
        if (it.debugMode) game.world.add(Inspector(it)..position.setFrom(event.localPosition));
        return;
      }
    }
  }
}

class Inspector extends PositionComponent {
  Inspector(this.target) {
    add(to_parent = BitmapButton(
      bg_nine_patch: atlas.sprite('button_plain.png'),
      text: 'Go to Parent',
      position: Vector2(0, -32),
      font: mini_font,
      font_scale: 1,
      onTap: () {
        final tp = target.parent;
        if (tp != null) target = tp;
      },
    )..priority = 10);

    add(info = FlowText(
      background: atlas.sprite('button_plain.png'),
      text: target.toString(),
      font: mini_font,
      font_scale: 1,
      size: Vector2(240, 128),
    ));
  }

  Component target;

  late BitmapButton to_parent;
  late FlowText info;

  @override
  update(double dt) {
    super.update(dt);

    to_parent.isVisible = target.parent != null;

    final lines = <String>[];
    lines.add(target.runtimeType.toString());
    lines.add('\n');
    lines.add('Parent: ${target.parent?.runtimeType}');
    if (target case PositionComponent it) {
      lines.add('Position: ${it.x.round()} x ${it.y.round()}');
      lines.add('Size: ${it.x.round()} x ${it.y.round()}');
    }
    if (target case FakeThreeDee it) {
      lines.add('Fake Height: ${it.fake_height}');
    }
    if (target case DeflectorShield it) {
      lines.add('Recharge: ${it.auto_recharge}');
      lines.add('Energy: ${it.energy}');
      lines.add('Boost: ${it.shield.shield_boost}');
    }
    if (target case MarauderCaptain it) {
      lines.add('Indicator: ${it.indicator}');
    }
    lines.add('Priority: ${target.priority}');

    final text = lines.join('\n');
    if (info.text == text) return;

    info.removeFromParent();
    add(info = FlowText(
      background: atlas.sprite('button_plain.png'),
      text: text,
      font: mini_font,
      font_scale: 1,
      size: Vector2(240, 256),
    ));
  }
}
