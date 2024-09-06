import 'package:flame/components.dart';

import 'components/flow_text.dart';
import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/screens.dart';
import 'game/game_state.dart';
import 'game/hiscore.dart';
import 'game/soundboard.dart';
import 'util/fonts.dart';
import 'util/functions.dart';
import 'util/game_script.dart';

class TheEndScreen extends GameScriptComponent {
  @override
  void onLoad() async {
    add(await sprite_comp('end.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('The End', center_x, 08, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/end.txt'),
      font: tiny_font,
      position: Vector2(0, 24),
      size: Vector2(256, 64 - 8),
    ));

    if (hiscore.isHiscoreRank(state.score)) {
      softkeys('Hiscore', null, (_) => showScreen(Screen.enter_hiscore));
    } else {
      clear_game_state();
      softkeys('Back', null, (_) => popScreen());
    }

    soundboard.play_music('music/theme.mp3');
  }

  clear_game_state() async {
    await state.delete();
    state.reset();
  }
}
