import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/ion_pulse.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';

class IonPulseGun extends Component with HasContext {
  IonPulseGun(this._player);

  final Player _player;

  double _cool_down = 0;

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.8;

      5.forEach((i) {
        stage.add(IonPulse()
          ..delay = (i+1) * 0.05
          ..position.setFrom(_player.position)
          ..x += 25
          ..y -= 25 / 4);
      });

      audio.play(Sound.shot, volume_factor: 0.5);
    }
  }
}
