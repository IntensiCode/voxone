import 'package:voxone/game/enemies/enemy.dart';

class SweepingMarauder extends EnemyEntity
    with
        CreateMarauderEntity,
        SweepInOnIncoming,
        FloatOnActive,
        PlantMineOnSweeping,
        SweepOutOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {
  SweepingMarauder(super.wave);
}
