import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/ranger.dart';

class WarpingRanger extends EnemyEntity
    with
        CreateRangerEntity,
        WarpInOnIncoming,
        FloatOnActive,
        PlantMineOnSweeping,
        SweepOutOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {
  WarpingRanger(super.wave);
}
