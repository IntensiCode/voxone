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

  final _wave = List<MarauderMine>.empty(growable: true);

  @override
  void onLoad() {
    at(delay, () => sendMessage(ShowInfoText(text: 'Approaching Minefield')));

    if (!dev) pause(info_time);

    enemies_in_wave.forEach((idx) {
      at(0.2, () {
        final it = mines.spawn(Vector2(850, -150 + rng.nextDoubleLimit(500)));
        it.then((it) => _wave.add(it));
      });
    });
  }

  @override
  void update(double dt) {
    defeated = _wave.length >= enemies_in_wave && _wave.every((it) => it.isRemoved);
  }
}
