import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/ranger.dart';

class WarpingRanger extends MarauderEntity
    with
        CreateRangerEntity,
        WarpInOnIncoming,
        FloatOnActive,
        PlantMineOnSweeping,
        SweepOutOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {}
