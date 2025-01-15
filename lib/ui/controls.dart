import 'package:flame/components.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/configuration.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/input/keys.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/ui/flow_text.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/ui/soft_keys.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/game_script.dart';

const _game_pad = '''
The dpad or left stick is used to move the player. The stick may not work, depending on the controller. The dpad should always work.

A: Fire primary weapon. X: Next primary weapons.
B: Fire secondary weapon. Y: Next secondary weapon.

Use start button to toggle pause. During pause, R1 will exit the game.

L1 and R1 are used as the soft keys. Soft keys are the buttons at the edge of the screen. Like the 'Back' button at the bottom left of this screen.
''';

const _game_pad_alt = '''
The dpad or left stick is used to move the player. The stick may not work, depending on the controller. The dpad should always work.

A: Fire primary weapon. B: Next primary weapons. L1: Next primary weapon.
X: Fire secondary weapon. Y: Next secondary weapon. R1: Next secondary weapon.

Use start button to toggle pause. During pause, select will exit the game.

Select and start are used as the soft keys. Soft keys are the buttons at the edge of the screen. Like the 'Back' button
 at the bottom left of this screen.

This mapping is active only during gameplay!
''';

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

class Controls extends GameScriptComponent with HasAutoDisposeShortcuts {
  final bool _configure_game_pad = true;

  final _keys = Keys();

  @override
  onLoad() {
    add(_keys);
    add(space);

    fontSelect(tiny_font, scale: 2);
    textXY('Game Pad / Controller', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);
    textXY('Keyboard', game_center.x, game_center.y - 28 + 50, scale: 2, anchor: Anchor.topCenter);

    _update_game_pad_info();
    add(FlowText(
      text: _move,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(game_width / 4, game_height / 2 - 96),
      position: Vector2(16, game_center.y + 50),
      anchor: Anchor.topLeft,
      background: atlas.sprite('button_plain.png'),
    ));
    add(FlowText(
      text: _weapons,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(game_width / 2 - 80, game_height / 2 - 96),
      position: Vector2(game_center.x, game_center.y + 50),
      anchor: Anchor.topCenter,
      background: atlas.sprite('button_plain.png'),
    ));
    add(FlowText(
      text: _soft_keys,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(game_width / 4, game_height / 2 - 96),
      position: Vector2(game_width - 16, game_center.y + 50),
      anchor: Anchor.topRight,
      background: atlas.sprite('button_plain.png'),
    ));

    softkeys('Back', null, (_) => popScreen());

    if (_configure_game_pad) {
      fontSelect(mini_font, scale: 1);
      textXY('< Game Pad Config >', game_center.x, 240 - 32, anchor: Anchor.bottomCenter, scale: 1);
      _game_pad_config = textXY(
        configuration.game_pad_config.name,
        game_center.x,
        240 - 16,
        anchor: Anchor.bottomCenter,
        scale: 1,
      );
    }
  }

  void _update_game_pad_info() {
    _game_pad_info?.removeFromParent();

    final which = configuration.game_pad_config == GamePadConfig.Default ? _game_pad : _game_pad_alt;
    add(_game_pad_info = FlowText(
      text: which,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(game_width - 32, game_height / 2 - 96),
      position: Vector2(16, 48),
      anchor: Anchor.topLeft,
      background: atlas.sprite('button_plain.png'),
    ));
  }

  FlowText? _game_pad_info;

  late BitmapText _game_pad_config;

  @override
  void onMount() {
    super.onMount();
    if (_configure_game_pad) {
      onKey('<Left>', () => _change_game_pad_config(-1));
      onKey('<Right>', () => _change_game_pad_config(1));
      onKey('<', () => _change_game_pad_config(-1));
      onKey('>', () => _change_game_pad_config(1));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.soft1)) popScreen();

    if (_configure_game_pad) {
      if (_keys.check_and_consume(GameKey.left)) _change_game_pad_config(-1);
      if (_keys.check_and_consume(GameKey.right)) _change_game_pad_config(1);
    }
  }

  void _change_game_pad_config(int add) {
    final values = GamePadConfig.values;
    final index = (values.indexOf(configuration.game_pad_config) + add + values.length) % values.length;
    configuration.game_pad_config = values[index];
    _game_pad_config.change_text_in_place(values[index].name);

    _update_game_pad_info();
  }
}
