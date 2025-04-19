import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/enemies/asteroids.dart';
import 'package:stardash/game/shared/difficulty.dart';
import 'package:stardash/game/shared/enemy_wave.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/messages.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/game_script.dart';
import 'package:stardash/util/random.dart';

class AsteroidsWave extends GameScriptComponent with HasContext, EnemyWave {
  static const enemies_in_wave = 64;

  @override
  bool get kill_bonus => false;

  @override
  void onLoad() {
    after(delay, () => sendMessage(ShowInfoText(text: 'Crossing Asteroid Belt')));

    if (!dev) pause_script(info_time);

    final interval = switch (difficulty) {
      Difficulty.easy => 1.0,
      Difficulty.normal => 0.8,
      Difficulty.hard => 0.75,
    };
    final pos = Vector2.zero();
    enemies_in_wave.forEach((idx) {
      after(interval, () {
        pos.x = 850;
        pos.y = -100 + rng.nextDoubleLimit(300);
        asteroids.spawn(pos);
      });
    });
    after(10, () => defeated = true);
  }
}
