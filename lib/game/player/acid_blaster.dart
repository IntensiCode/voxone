import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/acid_blast.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class AcidBlaster extends Component with HasContext, PrimaryWeapon {
  AcidBlaster(this._player);

  final Player _player;

  final _projectiles = ComponentRecycler(() => AcidBlast());

  double _cool_down = 0;

  @override
  String get display_name => 'Acid Blaster';

  @override
  Sprite get icon => extras.icon_for(ExtraId.acid_blast);

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.4;
      stage.add(_projectiles.acquire()..reset(_player.position));
      audio.play(Sound.acid_blast, volume_factor: 0.1);
    }
  }
}
