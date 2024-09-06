import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:flame/components.dart';

class Flammable extends Component {
  bool on_fire = false;

  double _fire_time = 0;
  double _burn_time_overall = 0;

  void ignite() => on_fire = true;

  // TODO fire damage
  void on_hit(double fire_damage) => ignite();

  @override
  void update(double dt) {
    super.update(dt);

    if (!on_fire) return;

    _burn_time_overall += dt;

    if (_fire_time <= 0) {
      my_prop.destructible.on_hit(WeaponType.burning);

      model.particles.spawn_smoke(my_prop.position, my_prop.hit_width);
      model.particles.spawn_fire(my_prop.position, my_prop.hit_width);

      final damage = my_prop.damage_percent / 100;
      _fire_time = 0.3 - damage * 0.2;

      if (damage > 20) {
        my_prop.flammable?.ignite();
      }

      if (_burn_time_overall.toInt() == 1) {
        for (final it in entities.flammables) {
          if (it == my_prop) continue;
          if (it.position.distanceTo(my_prop.position) > 24) continue;
          it.flammable?.ignite();
        }
      }
    } else {
      _fire_time -= dt;
    }
  }
}
