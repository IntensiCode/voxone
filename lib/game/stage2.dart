import 'package:voxone/background/ground.dart';
import 'package:voxone/core/shadows.dart';
import 'package:voxone/game/game_screen.dart';
import 'package:voxone/game/player/horizontal_player.dart';

class Stage2 extends GameScreen {
  @override
  onLoad() async {
    add(Ground());
    add(shadows = Shadows());
    add(HorizontalPlayer());

    shadows.isVisible = false;
  }
}
