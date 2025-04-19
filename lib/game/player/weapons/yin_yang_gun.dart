import 'package:flame/components.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/game/player/projectiles/yin_yang.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';

class YinYangGun extends Component with HasContext, PrimaryWeapon {
  YinYangGun(this._player);

  final Player _player;

  late final _projectiles = ComponentRecycler(() => YinYang(stage))..precreate(32);

  double _cool_down = 0;

  @override
  String get display_name => 'Yin Yang';

  @override
  Sprite get icon => extras.icon_for(ExtraId.yin_yang);

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 1.5;
      stage.add(_projectiles.acquire()..reset(_player as FakeThreeDee));
      audio.play(Sound.shot, volume_factor: 0.25);
    }
  }
}
