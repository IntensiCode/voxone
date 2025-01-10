import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/random.dart';

class MinefieldWave extends GameScriptComponent with EnemyWave, HasContext {
  static const enemies_in_wave = 64;

  bool _done_spawning = false;

  Iterable<MarauderMine> get _wave => stage.children.whereType<MarauderMine>();

  @override
  void onLoad() {
    after(delay, () => sendMessage(ShowInfoText(text: 'Approaching Minefield')));

    if (!dev) pause(info_time);

    final pos = Vector2.zero();
    enemies_in_wave.forEach((idx) {
      after(0.2, () {
        pos.x = 850;
        pos.y = -150 + rng.nextDoubleLimit(500);
        mines.spawn(pos, drift: rng.nextDoublePM(25));
      });
    });
    after(1, () => _done_spawning = true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    defeated = _done_spawning && _wave.every((it) => it.isRemoved);
  }
}
