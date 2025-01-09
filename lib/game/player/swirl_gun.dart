import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/swirl.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class SwirlGun extends Component with HasContext, PrimaryWeapon {
  SwirlGun(this._player);

  final Player _player;

  final _projectiles = ComponentRecycler(() => Swirl());

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
      _cool_down += 1.5;
      stage.add(_projectiles.acquire()..reset(_player.position));
      audio.play(Sound.swirl, volume_factor: 0.5);
    }
  }
}
