import 'package:flame/components.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/input/keys.dart';
import 'package:voxone/ui/flow_text.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/ui/soft_keys.dart';
import 'package:voxone/util/game_script.dart';

const _game_pad = '''
The dpad or left stick is used to move the player. The stick may not work, depending on the controller. The dpad should always work.

A: Fire primary weapon. X: Next primary weapons.
B: Fire secondary weapon. Y: Next secondary weapon.

Use start button to toggle pause. During pause, L1 will exit the game.

L1 and R1 are used as the soft keys. Soft keys are the buttons at the edge of the screen. Like the 'Back' button at the bottom left of this screen.
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

class Controls extends GameScriptComponent {
  final _keys = Keys();

  @override
  onLoad() {
    add(_keys);
    add(space);

    fontSelect(tiny_font, scale: 2);
    textXY('Game Pad / Controller', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);
    textXY('Keyboard', game_center.x, game_center.y - 28, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: _game_pad,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(game_width - 32, game_height / 2 - 96),
      position: Vector2(16, 48),
      anchor: Anchor.topLeft,
      background: atlas.sprite('button_plain.png'),
    ));
    add(FlowText(
      text: _move,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(game_width / 4, game_height / 2 - 96),
      position: Vector2(16, game_center.y),
      anchor: Anchor.topLeft,
      background: atlas.sprite('button_plain.png'),
    ));
    add(FlowText(
      text: _weapons,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(game_width / 2 - 80, game_height / 2 - 96),
      position: Vector2(game_center.x, game_center.y),
      anchor: Anchor.topCenter,
      background: atlas.sprite('button_plain.png'),
    ));
    add(FlowText(
      text: _soft_keys,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(game_width / 4, game_height / 2 - 96),
      position: Vector2(game_width - 16, game_center.y),
      anchor: Anchor.topRight,
      background: atlas.sprite('button_plain.png'),
    ));

    softkeys('Back', null, (_) => popScreen());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.soft1)) popScreen();
  }
}
