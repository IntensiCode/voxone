import 'package:voxone/core/common.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:flame/components.dart';

import 'level_prop_extensions.dart';

class CrackWhenHit extends Component {
  CrackWhenHit(this.cracks);

  final Sprite cracks;

  @override
  void onMount() {
    super.onMount();
    my_prop.when_hit.add(() {
      // TODO pool and change color instead of stacking :-D
      my_prop.add(SpriteComponent(sprite: cracks, paint: pixel_paint()..color = shadow));
      soundboard.play(Sound.hit_crack);
    });
  }
}
