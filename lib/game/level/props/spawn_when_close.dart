import 'package:voxone/game/game_context.dart';
import 'package:flame/components.dart';

import 'level_prop_extensions.dart';
import 'proximity_sensor.dart';

class SpawnWhenClose extends Component {
  @override
  void onMount() {
    super.onMount();
    removeFromParent();
    _replace_with_proximity_sensor();
  }

  void _replace_with_proximity_sensor() {
    final it = my_prop;
    entities.add(ProximitySensor(
      center: it.center,
      radius: 32,
      when_triggered: () => entities.add(it),
    ));
    it.removeFromParent();
  }
}
