import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/screens.dart';
import 'package:stardash/input/controls_ui.dart';
import 'package:stardash/input/keys.dart';
import 'package:stardash/ui/flow_text.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/util/bitmap_text.dart';
import 'package:stardash/util/extensions.dart';

mixin GamepadControls on ControlsUi {
  final _labels = <GamePadControl, BitmapText>{};

  final _x_base = game_center.x;
  final _y_base = game_center.y + 70;

  void set_enabled(bool value);

  @override
  void onRemove() {
    super.onRemove();
    dispose('snoop_game_pad_input');
  }

  @override
  onLoad() {
    super.onLoad();
    spriteXY('gamepad.png', _x_base, _y_base - 32, Anchor.bottomCenter);
    if (dev) add_button('Select Preset', 210, 130, shortcut: 'p', anchor: Anchor.centerRight, onTap: _select_preset);
    add_button('Configure Game Pad', 210, 160, shortcut: 'g', anchor: Anchor.centerRight, onTap: _configure_game_pad);
    // add_button('Change Actions', 210, 175, shortcut: 'a', anchor: Anchor.centerRight, onTap: _change_actions);
    _init_game_pad_labels();
    _update_game_pad_info();
  }

  void _select_preset() => pushScreen(Screen.select_game_pad);

  Map<int, GamePadControl>? _saved_mapping;
  Component? _overlay;

  void _configure_game_pad() async {
    try {
      set_enabled(false);
      _saved_mapping = Map.of(hw_mapping);
      add(_overlay = RectangleComponent(
        size: Vector2(game_width, game_height),
        paint: pixel_paint()..color = black.withAlpha(0xA0),
      ));
      await _try_configure_game_pad();
    } catch (e, st) {
      logError('cancelled - $e', st);
      dispose('snoop_game_pad_input');
    } finally {
      _overlay?.removeFromParent();
      _overlay = null;
      _saved_mapping = null;
      set_enabled(true);
    }
  }

  final _buttons = [
    (GamePadControl.a, 'Fire Primary Weapon', 'A Button'),
    (GamePadControl.b, 'Fire Secondary Weapon', 'B Button'),
    (GamePadControl.x, 'Switch Primary Weapon', 'X or L1 or R1'),
    (GamePadControl.y, 'Switch Secondary Weapon', 'Y or L1 or R1'),
    (GamePadControl.left_bumper, 'Pause / Back / Cancel', 'L1 or Start'),
    (GamePadControl.right_bumper, 'Confirm', 'R1 or Select'),
  ];

  static const _dpad_info = 'Use DPAD only. Analog sticks are not supported properly, yet.';

  final _extra_info = {
    GamePadControl.dpad_up: _dpad_info,
    GamePadControl.dpad_down: _dpad_info,
    GamePadControl.dpad_left: _dpad_info,
    GamePadControl.dpad_right: _dpad_info,
    GamePadControl.left_bumper: 'Required to navigate screens',
    GamePadControl.right_bumper: 'Required to confirm actions',
  };

  final _move_buttons = [
    (GamePadControl.dpad_up, 'Move Up', 'DPAD Up'),
    (GamePadControl.dpad_down, 'Move Down', 'DPAD Down'),
    (GamePadControl.dpad_left, 'Move Left', 'DPAD Left'),
    (GamePadControl.dpad_right, 'Move Right', 'DPAD Right'),
  ];

  Future _try_configure_game_pad() async {
    final todo = _buttons.map((it) => it.$1).toList();
    hw_mapping.removeWhere((k, v) => todo.contains(v));

    for (final it in _buttons) {
      await Future.delayed(const Duration(milliseconds: 100));
      final id = await _grab_button(it);
      logInfo('${it.$1} => $id');
      hw_mapping[id.$2] = it.$1;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final dpad_y = await _grab_button(_move_buttons[0], allow_axis: true);
    logInfo('DPAD Up => $dpad_y');
    if (dpad_y.$1 == SnoopType.axis) {
      hw_mapping[dpad_y.$2] = GamePadControl.dpad_y;
    } else {
      hw_mapping[dpad_y.$2] = GamePadControl.dpad_up;

      await Future.delayed(const Duration(milliseconds: 100));
      final other = await _grab_button(_move_buttons[1]);
      hw_mapping[other.$2] = GamePadControl.dpad_down;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final dpad_x = await _grab_button(_move_buttons[2], allow_axis: true);
    logInfo('DPAD Left => $dpad_x');
    if (dpad_x.$1 == SnoopType.axis) {
      hw_mapping[dpad_x.$2] = GamePadControl.dpad_x;
    } else {
      hw_mapping[dpad_x.$2] = GamePadControl.dpad_left;

      await Future.delayed(const Duration(milliseconds: 100));
      final other2 = await _grab_button(_move_buttons[3]);
      hw_mapping[other2.$2] = GamePadControl.dpad_right;
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  void cancel_configuration() {
    logInfo('cancel configuration');

    final saved = _saved_mapping;
    if (saved != null) hw_mapping = saved;
    _saved_mapping = null;

    if (_grab_preset?.isCompleted == false) _grab_preset?.completeError('Cancelled');
    _grab_preset = null;
    _grab_overlay?.removeFromParent();
    _grab_overlay = null;

    set_enabled(true);
  }

  Component? _grab_overlay;
  Completer? _grab_preset;

  Future<(SnoopType, int, double)> _grab_button(
    (GamePadControl which, String action, String recommendation) it, {
    bool allow_axis = false,
  }) async {
    final action = it.$2;
    final recommendation = it.$3;
    final info = _extra_info[it.$1];
    logInfo('Grabbing button: $action');

    if (_grab_preset?.isCompleted == false) _grab_preset?.completeError('Cancelled');
    _grab_preset = null;

    _grab_overlay?.removeFromParent();
    _grab_overlay = null;
    _grab_overlay = added(FlowText(
      background: atlas.sprite('button_plain.png'),
      size: Vector2(480, 240),
      text: '\n\n\n'
          'Assign button for $action\n\n\n\n'
          'Recommendation: $recommendation\n\n\n\n'
          'Press any button now to assign it\n\n\n\n'
          'Press <Escape> to cancel\n\n\n\n'
          '${info ?? ''}\n\n',
      centered_text: true,
      font: mini_font,
      font_scale: 1.5,
      position: game_center,
      anchor: Anchor.center,
    )..fadeInDeep());
    // grab_overlay?.fadeInDeep();

    final grab = _grab_preset = Completer<(SnoopType, int, double)>();
    autoDispose('snoop_game_pad_input', snoop_game_pad_input((type, it, value) {
      logInfo('snooped: $type $it $value');
      if (!allow_axis && type == SnoopType.axis) return;
      if (value.abs() != 1.0) return;
      if (_grab_preset?.isCompleted != false) return;
      _grab_preset?.complete((type, it, value));
      dispose('snoop_game_pad_input');
    }));

    final id = await grab.future;
    _grab_overlay?.fadeOutDeep(and_remove: true);
    _grab_overlay = null;
    return id;
  }

  void _init_game_pad_labels() {
    add(_labels[GamePadControl.select] = BitmapText(
      text: 'Soft Key 1 (Back / Escape)',
      position: Vector2(210, 58),
      anchor: Anchor.centerRight,
    ));
    add(_labels[GamePadControl.start] = BitmapText(
      text: 'Soft Key 2 (Enter / Confirm)',
      position: Vector2(590, 58),
      anchor: Anchor.centerLeft,
    ));

    add(_labels[GamePadControl.left_bumper] = BitmapText(
      text: 'Soft Key 1 (Back / Escape)',
      position: Vector2(210, 80),
      anchor: Anchor.centerRight,
    ));
    add(_labels[GamePadControl.right_bumper] = BitmapText(
      text: 'Soft Key 2 (Enter / Confirm)',
      position: Vector2(590, 80),
      anchor: Anchor.centerLeft,
    ));

    add(_labels[GamePadControl.dpad_y] = BitmapText(
      text: 'Up / Down',
      position: Vector2(210, 213),
      anchor: Anchor.centerRight,
    ));
    add(_labels[GamePadControl.dpad_x] = BitmapText(
      text: 'Left / Right',
      position: Vector2(210, 223),
      anchor: Anchor.centerRight,
    ));

    add(_labels[GamePadControl.y] = BitmapText(
      text: 'Switch Secondary Weapon',
      position: Vector2(590, 111),
      anchor: Anchor.centerLeft,
    ));
    add(_labels[GamePadControl.b] = BitmapText(
      text: 'Fire Secondary Weapon',
      position: Vector2(590, 137),
      anchor: Anchor.centerLeft,
    ));
    add(_labels[GamePadControl.a] = BitmapText(
      text: 'Fire Primary Weapon',
      position: Vector2(590, 164),
      anchor: Anchor.centerLeft,
    ));
    add(_labels[GamePadControl.x] = BitmapText(
      text: 'Switch Primary Weapon',
      position: Vector2(590, 190),
      anchor: Anchor.centerLeft,
    ));
  }

  final _info = <GameKey, String>{
    GameKey.a_button: 'Fire Primary Weapon',
    GameKey.b_button: 'Fire Secondary Weapon',
    GameKey.x_button: 'Switch Primary Weapon',
    GameKey.y_button: 'Switch Secondary Weapon',
    GameKey.soft1: 'Back / Escape',
    GameKey.soft2: 'Enter / Confirm',
    GameKey.select: 'Back / Escape',
    GameKey.start: 'Enter / Confirm',
    GameKey.x_axis: 'Left / Right',
    GameKey.y_axis: 'Up / Down',
  };

  void _update_game_pad_info() {
    for (final entry in _labels.entries) {
      final key = entry.key;
      final label = entry.value;
      final gk = gk_mapping[key];
      if (gk == null) {
        logInfo('No mapping for $key');
        label.text = '';
      } else {
        label.text = "${gk.label}: ${_info[gk] ?? ''}";
      }
    }
  }
}
