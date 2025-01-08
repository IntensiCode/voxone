import 'package:voxone/game/stage1/marauder.dart';

class SweepingMarauder extends MarauderEntity
    with
        CreateMarauderEntity,
        SweepInOnIncoming,
        FloatOnActive,
        PlantMineOnSweeping,
        SweepOutOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {}
