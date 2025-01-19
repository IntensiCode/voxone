import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/enemies/homing_bomb.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/random.dart';

class HomingLauncher extends Component with HasContext {
  HomingLauncher(this.source);

  final Enemy source;

  final _base_time = switch (difficulty) {
    Difficulty.easy => 3.0,
    Difficulty.normal => 2.5,
    Difficulty.hard => 2.0,
  };

  late double _cool_down = _base_time + rng.nextDouble();

  final _projectiles = ComponentRecycler(() => HomingBomb());

  @override
  onLoad() {
    HomingBomb.sheet = atlas.sheetI('nuke_core.png', 8, 1);

    logInfo('base time: $_base_time');
  }

  @override
  void update(double dt) {
    if (source.state == EnemyState.exploding) removeFromParent();
    if (source.state == EnemyState.defeated) removeFromParent();
    if (source.state == EnemyState.left) removeFromParent();
    if (source.state != EnemyState.active) return;

    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    _cool_down += _base_time + 2.4 + rng.nextDoubleLimit(0.9);

    final it = _projectiles.acquire()..reset(source as FakeThreeDee);
    it.x -= 25;
    it.y += 25 / 4;
    stage.add(it);

    audio.play(Sound.acid_blast, volume_factor: 0.5);
  }
}
