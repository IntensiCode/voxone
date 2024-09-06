import 'core/common.dart';
import 'core/screens.dart';
import 'game/game_state.dart';
import 'game/hiscore.dart';
import 'util/fonts.dart';
import 'util/functions.dart';
import 'util/game_script.dart';
import 'util/shortcuts.dart';

class EnterHiscoreScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  @override
  onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font);
    textXY('You made it into the', center_x, default_line_height * 2);
    textXY('HISCORE', center_x, default_line_height * 3, scale: 2);

    textXY('Score', center_x, default_line_height * 5);
    textXY('${state.score}', center_x, default_line_height * 6, scale: 2);

    textXY('Round', center_x, default_line_height * 8);
    textXY('${state.level_number_starting_at_1}', center_x, default_line_height * 9, scale: 2);

    textXY('Enter your name:', center_x, default_line_height * 12);

    var input = textXY('_', center_x, default_line_height * 13, scale: 2);

    textXY('Press enter to confirm', center_x, default_line_height * 16);

    shortcuts.snoop = (it) {
      if (it.length == 1) {
        name += it;
      } else if (it == '<Space>' && name.isNotEmpty) {
        name += ' ';
      } else if (it == '<Backspace>' && name.isNotEmpty) {
        name = name.substring(0, name.length - 1);
      } else if (it == '<Enter>' && name.isNotEmpty) {
        shortcuts.snoop = (_) {};
        hiscore.insert(state.score, state.level_number_starting_at_1, name);
        showScreen(Screen.hiscore);
        clear_game_state();
      }
      if (name.length > 10) name = name.substring(0, 10);

      input.removeFromParent();
      input = textXY('${name}_', center_x, default_line_height * 13, scale: 2);
    };
  }

  Future clear_game_state() async {
    await state.delete();
    state.reset();
  }

  String name = '';
}
