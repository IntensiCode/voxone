import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/projectiles/ion_pulse.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class IonPulseGun extends Component with HasContext, PrimaryWeapon {
  IonPulseGun(this._player);

  final Player _player;

  final _projectiles = ComponentRecycler(() => IonPulse());

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

      5.forEach((i) {
        stage.add(_projectiles.acquire()..reset((i + 1) * 0.05, _player as FakeThreeDee));
      });

      audio.play(Sound.pulse, volume_factor: 0.5);
    }
  }
}
