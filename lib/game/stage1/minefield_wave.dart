import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/enemies/marauder_mines.dart';
import 'package:stardash/game/shared/difficulty.dart';
import 'package:stardash/game/shared/enemy_wave.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/messages.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/game_script.dart';
import 'package:stardash/util/random.dart';

class MinefieldWave extends GameScriptComponent with HasContext, EnemyWave {
  static const enemies_in_wave = 128;

  @override
  bool get kill_bonus => false;

  @override
  void onLoad() {
    rotate_mines = false;

    after(delay, () => sendMessage(ShowInfoText(text: 'Minefield Ahead')));

    if (!dev) pause_script(info_time);

    final interval = switch (difficulty) {
      Difficulty.easy => 0.30,
      Difficulty.normal => 0.25,
      Difficulty.hard => 0.24,
    };
    final pos = Vector2.zero();
    enemies_in_wave.forEach((idx) {
      after(interval, () {
        pos.x = 850;
        pos.y = -150 + rng.nextDoubleLimit(500);
        mines.spawn(pos, drift: rng.nextDoublePM(15));
        if (idx % 4 == 0) {
          pos.y = -150 + rng.nextDoubleLimit(500);
          extras.spawn(pos, 50, choices: ExtraId.defaults);
        }
      });
    });
    after(5, () => defeated = true);
  }

  @override
  void onRemove() {
    super.onRemove();
    rotate_mines = true;
  }
}
