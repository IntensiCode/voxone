import 'package:voxone/background/ground.dart';
import 'package:voxone/game/player/horizontal_player.dart';
import 'package:voxone/game/shared/game_screen.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';

class Stage2 extends GameScreen with HasContext {
  @override
  onLoad() async {
    add(Ground());
    add(shadows);
    add(HorizontalPlayer());

    shadows.isVisible = false;
  }
}
