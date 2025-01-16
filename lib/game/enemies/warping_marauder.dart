import 'package:voxone/game/enemies/marauder.dart';

class WarpingMarauder extends MarauderEntity
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
