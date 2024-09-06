import 'package:flame/components.dart';

import 'components/flow_text.dart';
import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/screens.dart';
import 'util/fonts.dart';
import 'util/functions.dart';
import 'util/game_script.dart';

class CreditsScreen extends GameScriptComponent {
  @override
  void onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('Credits', center_x, 08, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/credits.txt'),
      font: tiny_font,
      position: Vector2(0, 24),
      size: Vector2(320, 160 - 16),
    ));

    softkeys('Back', null, (_) => popScreen());
  }
}
