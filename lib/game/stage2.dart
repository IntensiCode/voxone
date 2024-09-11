import 'package:voxone/game/ground.dart';
import 'package:voxone/game/game_screen.dart';
import 'package:voxone/game/player.dart';
import 'package:voxone/game/shadows.dart';

class Stage2 extends GameScreen {
  @override
  onLoad() async {
    add(Ground());
    add(shadows = Shadows());
    add(HorizontalPlayer());

    shadows.isVisible = false;
  }
}
