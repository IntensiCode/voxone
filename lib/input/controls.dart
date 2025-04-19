import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/background/space.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/configuration.dart';
import 'package:stardash/game/shared/screens.dart';
import 'package:stardash/input/controls_ui.dart';
import 'package:stardash/input/game_pads_config.dart';
import 'package:stardash/input/keys.dart';
import 'package:stardash/util/bitmap_button.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/game_script.dart';

class Controls extends GameScriptComponent with ControlsUi, GamepadControls {
  late BitmapButton _invert_y;
  late BitmapButton _invert_xy;

  @override
  void set_enabled(bool value) => ui_navigation_active = value;

  @override
  void onRemove() {
    super.onRemove();
    configuration.save();
    logInfo('configuration saved');
  }

  @override
  onLoad() async {
    add(space);

    super.onLoad();

    textXY('Game Pad / Controller', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);

    textXY('Keyboard', _x_base, _y_base - 28, scale: 2, anchor: Anchor.topCenter);
    add_flow(_move, 16, _y_base, _col_width, _col_height, Anchor.topLeft);
    add_flow(_weapons, _x_base, _y_base, _col_width * 2 - 80, _col_height, Anchor.topCenter);
    add_flow(_soft_keys, game_width - 16, _y_base, _col_width, _col_height, Anchor.topRight);

    add_button('Back', 8, game_height - 8, anchor: Anchor.bottomLeft, onTap: popScreen);
    add_flow('Invert Y axis?', 240, 457 - 32, 348, 16, Anchor.topLeft);
    _invert_y = add_button('Yes', 586, 456 - 32, shortcut: 'y', anchor: Anchor.topLeft, onTap: _toggle_y);
    _update_y();
    add_flow('Movement in horizontal levels?', 240, 449, 348, 16, Anchor.topLeft);
    _invert_xy = add_button('Left / Right', 586, 448, shortcut: 'x', anchor: Anchor.topLeft, onTap: _toggle_xy);
    _update_xy();

    highlight_down();
  }

  final _x_base = game_center.x;
  final _y_base = game_center.y + 50;
  final _col_width = game_width / 4;
  final _col_height = game_height / 2 - 96;

  void _toggle_y() {
    invert_y_axis = !invert_y_axis;
    _update_y();
    _invert_y.fadeInDeep();
  }

  void _toggle_xy() {
    prefer_x_over_y = !prefer_x_over_y;
    _update_xy();
    _invert_xy.fadeInDeep();
  }

  void _update_y() => _invert_y.text = invert_y_axis ? 'Yes' : 'No';

  void _update_xy() => _invert_xy.text = prefer_x_over_y ? 'Left / Right' : 'Up / Down';

  @override
  void update(double dt) {
    super.update(dt);
    if (keys.check_and_consume(GameKey.soft1)) _cancel_or_pop();
  }

  void _cancel_or_pop() {
    if (ui_navigation_active) {
      popScreen();
    } else {
      cancel_configuration();
    }
  }
}

const _move = '''
MOVE / STRAFE
-------------------

WASD OR

HJKL OR

ARROW KEYS
''';

const _weapons = '''
WEAPONS
------------

V or M or Ctrl: Fire Primary

C or E or Shift: Switch Primary

X or N or Space: Fire Secondary

Z or Q or Alt: Switch Secondary
''';

const _soft_keys = '''
SOFT KEYS
--------------

Escape: Left Soft Key

Enter: Right Soft Key
''';
