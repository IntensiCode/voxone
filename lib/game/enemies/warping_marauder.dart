import 'package:voxone/game/enemies/enemy.dart';

class WarpingMarauder extends EnemyEntity
    with
        CreateMarauderEntity,
        WarpInOnIncoming,
        FloatOnActive,
        PlantMineOnSweeping,
        SweepOutOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {
  WarpingMarauder(super.wave);
}
