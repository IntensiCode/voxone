import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/shared/difficulty.dart';

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

  @override
  void createEntity() {
    super.createEntity();
    reset_hit_points_to(switch (difficulty) {
      Difficulty.easy => 20,
      Difficulty.normal => 25,
      Difficulty.hard => 30,
    });
  }
}
