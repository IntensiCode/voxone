import 'package:voxone/core/common.dart';
import 'package:voxone/game/enemies/capital_ship.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/shared/enemy_wave.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/util/game_script.dart';

class CapitalShipWave extends GameScriptComponent with EnemyWave, HasContext {
  static const enemies_in_wave = 1;

  final _wave = List<Enemy>.empty(growable: true);

  @override
  bool get kill_bonus => false;

  @override
  void onLoad() {
    after(delay, () => sendMessage(ShowInfoText(text: 'Capital Ship Approaching')));

    if (!dev) pause_script(info_time);

    after(1.0, () {
      final it = CapitalShip(this);
      it.target_position.x = 600;
      it.target_position.y = 160;
      _wave.add(it);
      stage.add(it);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    defeated = _wave.length >= enemies_in_wave && _wave.every((it) => it.defeated);
  }
}
