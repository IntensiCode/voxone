import 'package:voxone/game/stage1/marauder.dart';

class WarpingMarauder extends MarauderEntity
    with
        CreateMarauderEntity,
        WarpInOnIncoming,
        FloatOnActive,
        PlantMineOnSweeping,
        SweepOutOnLeaving,
        TumbleOnExploding {}
