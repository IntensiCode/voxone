import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/plasma_shot.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';

class TriplePlasmaGun extends Component with HasContext {
  TriplePlasmaGun(this._player);

  final Player _player;

  double _cool_down = 0;

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.35;

      stage.add(PlasmaShot()
        ..change_direction(pi / 32)
        ..position.setFrom(_player.position)
        ..x += 25
        ..y -= 25 / 4);

      stage.add(PlasmaShot()
        ..change_direction(-pi / 32)
        ..position.setFrom(_player.position)
        ..x += 25
        ..y -= 25 / 4);

      stage.add(PlasmaShot()
        ..position.setFrom(_player.position)
        ..x += 25
        ..y -= 25 / 4);

      audio.play(Sound.shot, volume_factor: 0.5);
    }
  }
}
