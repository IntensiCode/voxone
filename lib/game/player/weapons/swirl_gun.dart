import 'package:flame/components.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/game/player/projectiles/swirl.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';

class SwirlGun extends Component with HasContext, PrimaryWeapon {
  SwirlGun(this._player);

  final Player _player;

  final _projectiles = ComponentRecycler(() => Swirl())..precreate(32);

  double _cool_down = 0;

  @override
  String get display_name => 'Swirl Gun';

  @override
  Sprite get icon => extras.icon_for(ExtraId.phosphor_swirl);

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.4;
      stage.add(_projectiles.acquire()..reset(_player as FakeThreeDee));
      if (_skip_sound == 0) {
        audio.play(Sound.swirl, volume_factor: 0.1);
        _skip_sound = 2;
      } else {
        _skip_sound--;
      }
    }
  }

  int _skip_sound = 0;
}
