import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/yin_yang.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class YinYangGun extends Component with HasContext, PrimaryWeapon {
  YinYangGun(this._player);

  final Player _player;

  late final _projectiles = ComponentRecycler(() => YinYang(stage));

  double _cool_down = 0;

  @override
  String get display_name => 'Yin Yang';

  @override
  Sprite get icon => extras.icon_for(ExtraId.triple_plasma);

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
