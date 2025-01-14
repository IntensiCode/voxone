import 'package:voxone/background/ground.dart';
import 'package:voxone/game/player/zaxxon_player.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/game_screen.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';

class Stage2 extends GameScreen with HasContext {
  @override
  onLoad() async {
    add(ground);
    add(shadows);
    add(extras);
    add(ZaxxonPlayer());
  }
}
