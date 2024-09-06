import 'package:voxone/game/entities/enemy.dart';
import 'package:voxone/game/entities/enemy_behavior.dart';
import 'package:voxone/game/game_configuration.dart';
import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class MovementClosesIn extends Component with EnemyBehavior, MovementMode {
  late Enemy enemy;

  @override
  void attach(Enemy enemy) {
    this.enemy = enemy;
    this.enemy.use_advice = false;
  }

  final _path_segment = List.generate(8, (_) => Vector2.zero());

  bool _finding = false;

  @override
  void offer_reaction() {
    bool force_find = false;

    if (my_prop.position.distanceToSquared(_path_segment.first) < 16) {
      for (var i = 1; i < _path_segment.length; i++) {
        _path_segment[i - 1].setFrom(_path_segment[i]);
      }
      _path_segment.last.setZero();
      if (_path_segment.first.isZero()) {
        force_find = true;
      }
    }

    if (_path_segment[3].isZero() && !_finding || force_find) {
      model.path_finder.find_path_to_player(my_prop, _path_segment);
      _finding = true;
    }

    if (!_path_segment[3].isZero() && _finding) {
      _finding = false;
    }
  }

  final _temp = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);

    if (_path_segment.first.isZero()) return;

    if (my_prop.position != _path_segment.first) {
      _temp.setFrom(_path_segment.first);
      _temp.sub(my_prop.position);
      _temp.normalize();
      _temp.scale(configuration.enemy_move_speed * dt);
      my_prop.position.add(_temp);
    }

    enemy.fire_dir.setFrom(player.position);
    enemy.fire_dir.sub(my_prop.position);
  }
}
