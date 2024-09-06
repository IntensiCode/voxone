import 'package:flame/components.dart';

import 'components/flow_text.dart';
import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/screens.dart';
import 'util/fonts.dart';
import 'util/functions.dart';
import 'util/game_script.dart';
import 'util/keys.dart';

bool help_triggered_at_first_start = false;

class HelpScreen extends GameScriptComponent {
  @override
  void onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('How To Play', center_x, 10, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/controls.txt'),
      font: tiny_font,
      position: Vector2(0, 25),
      size: Vector2(160, 160 - 16),
    ));

    add(FlowText(
      text: await game.assets.readFile('data/help.txt'),
      font: tiny_font,
      position: Vector2(center_x, 25),
      size: Vector2(160, 176),
    ));

    final label = help_triggered_at_first_start ? 'Start' : 'Back';
    softkeys(label, null, (_) => popScreen());

    add(keys);
  }

  final keys = Keys();

  @override
  void update(double dt) {
    super.update(dt);
    if (keys.check_and_consume(GameKey.fire1)) {
      popScreen();
    }
  }
}
