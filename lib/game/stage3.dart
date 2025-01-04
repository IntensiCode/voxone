import 'package:voxone/background/checkerboard.dart';
import 'package:voxone/core/shadows.dart';
import 'package:voxone/game/game_screen.dart';
import 'package:voxone/game/player/horizontal_player.dart';

class Stage3 extends GameScreen {
  @override
  onLoad() async {
    add(Checkerboard());
    add(shadows = Shadows());
    add(HorizontalPlayer());

    shadows.isVisible = false;
  }
}
