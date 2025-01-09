import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/plasma_shot.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class PlasmaGun extends Component with HasContext {
  PlasmaGun(this._player);

  final Player _player;

  final _projectiles = ComponentRecycler(() => PlasmaShot());

  double _cool_down = 0;

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.2;
      stage.add(_projectiles.acquire()..reset(_player.position));
      audio.play(Sound.shot, volume_factor: 0.5);
    }
  }
}
