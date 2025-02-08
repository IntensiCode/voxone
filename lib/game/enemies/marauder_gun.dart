import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/marauder_shot.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/random.dart';

class MarauderGun extends Component with HasContext {
  MarauderGun(this.source);

  final Enemy source;

  double _cool_down = rng.nextDouble();

  final _projectiles = ComponentRecycler(() => MarauderShot())..precreate(256);

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

    _cool_down += 0.4 + rng.nextDoubleLimit(0.9);

    final it = _projectiles.acquire();
    it.init_fake_3d(source as FakeThreeDee);
    it.x -= 25;
    it.y += 25 / 4;
    stage.add(it);

    audio.play(Sound.shot, volume_factor: 0.5);
  }
}
