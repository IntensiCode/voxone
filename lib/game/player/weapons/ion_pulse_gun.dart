import 'package:flame/components.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/game/player/projectiles/ion_pulse.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';

class IonPulseGun extends Component with HasContext, PrimaryWeapon {
  IonPulseGun(this._player);

  final Player _player;

  final _projectiles = ComponentRecycler(() => IonPulse())..precreate(64);

  double _cool_down = 0;

  @override
  String get display_name => 'Ion Pulse';

  @override
  Sprite get icon => extras.icon_for(ExtraId.ion_pulse);

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.8;

      for (var i = 0; i < 5; i++) {
        stage.add(_projectiles.acquire()..reset((i + 1) * 0.05, _player as FakeThreeDee));
      }

      audio.play(Sound.pulse, volume_factor: 0.5);
    }
  }
}
