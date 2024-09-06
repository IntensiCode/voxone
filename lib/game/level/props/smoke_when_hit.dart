import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:flame/components.dart';

class SmokeWhenHit extends Component {
  bool _smoking = false;

  double _smoke_time = 0;

  @override
  void onMount() {
    super.onMount();
    my_prop.when_hit.add(() {
      if (my_prop.damage_percent > 10) {
        _smoking = true;
      }
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_smoking) return;

    if (_smoke_time <= 0) {
      my_prop.destructible.on_hit(WeaponType.smoking);

      model.particles.spawn_smoke(my_prop.position, my_prop.hit_width);

      final damage = my_prop.damage_percent / 100;
      _smoke_time = 1.0 - damage * 0.8;

      if (damage > 0.3) {
        my_prop.flammable?.ignite();
      }
    } else {
      _smoke_time -= dt;
    }
  }
}
