import 'package:voxone/background/checkerboard.dart';
import 'package:voxone/game/player/horizontal_player.dart';
import 'package:voxone/game/shared/game_screen.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';

class Stage3 extends GameScreen with HasContext {
  @override
  onLoad() async {
    add(Checkerboard());
    add(shadows);
    add(HorizontalPlayer());

    shadows.isVisible = false;
  }
}
