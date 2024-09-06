import 'package:voxone/core/common.dart';
import 'package:voxone/game/entities/spawn_mode.dart';
import 'package:voxone/game/entities/spawn_when_visible.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

class SpawnStacked extends Component {
  final pending = <SpawnMode>[];

  static int spawn_interval = 1000;
  static int last_spawn = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (pending.isEmpty) {
      pending.addAll(my_prop.children.whereType<SpawnMode>());
      my_prop.removeAll(pending);
      if (pending.isNotEmpty) return;
      if (dev) throw 'no spawns on $my_prop';
      logError('no spawns on $my_prop');
      removeFromParent();
    } else {
      final which = pending.where((it) => it.should_spawn(my_prop));
      if (which.isEmpty) return;

      final now = DateTime.timestamp().millisecondsSinceEpoch;
      if (now < last_spawn + spawn_interval) return;

      last_spawn = now;

      logInfo('activate ${which.first}');
      my_prop.add(which.first);
      pending.remove(which.first);
      if (pending.isEmpty) removeFromParent();
    }
  }
}
