import 'package:voxone/game/enemies/marauder.dart';

class SweepingMarauder extends MarauderEntity
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
