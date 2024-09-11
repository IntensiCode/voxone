import 'package:voxone/game/checkerboard.dart';
import 'package:voxone/game/game_screen.dart';
import 'package:voxone/game/player.dart';
import 'package:voxone/game/shadows.dart';

class Stage3 extends GameScreen {
  @override
  onLoad() async {
    add(Checkerboard());
    add(shadows = Shadows());
    add(HorizontalPlayer());

    shadows.isVisible = false;
  }
}
