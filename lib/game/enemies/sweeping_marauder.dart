import 'package:stardash/game/enemies/enemy.dart';
import 'package:stardash/game/shared/difficulty.dart';

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

  @override
  void createEntity() {
    super.createEntity();
    reset_hit_points_to(switch (difficulty) {
      Difficulty.easy => 20,
      Difficulty.normal => 25,
      Difficulty.hard => 30,
    });
    active_time_limit = switch (difficulty) {
      Difficulty.easy => 150,
      Difficulty.normal => 120,
      Difficulty.hard => 130,
    };
  }
}
