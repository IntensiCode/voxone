import 'package:stardash/game/enemies/enemy.dart';
import 'package:stardash/game/enemies/ranger.dart';
import 'package:stardash/game/shared/difficulty.dart';

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

  @override
  void createEntity() {
    super.createEntity();
    reset_hit_points_to(switch (difficulty) {
      Difficulty.easy => 15,
      Difficulty.normal => 20,
      Difficulty.hard => 25,
    });
  }
}
