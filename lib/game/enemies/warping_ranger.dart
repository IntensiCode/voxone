import 'package:voxone/game/enemies/marauder.dart';
import 'package:voxone/game/enemies/ranger.dart';

class WarpingRanger extends MarauderEntity
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
