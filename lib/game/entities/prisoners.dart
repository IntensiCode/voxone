import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/game_messages.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/on_message.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class Prisoners extends Component with AutoDispose {
  Prisoners(this._sprites1632);

  final SpriteSheet _sprites1632;

  @override
  void onMount() {
    super.onMount();
    onMessage<PrisonerFreed>((it) => entities.add(Prisoner(it.prop.position, _sprites1632)));
  }
}

class Prisoner extends SpriteAnimationComponent {
  Prisoner(Vector2 position, this._sprites1632) : super(position: position, anchor: Anchor.bottomCenter) {
    priority = position.y.toInt() + 2;

    if (position.x >= 160) {
      _run_speed = 100;
      animation = _sprites1632.createAnimation(row: 24, stepTime: 0.1, from: 24, to: 28);
    } else {
      _run_speed = -100;
      animation = _sprites1632.createAnimation(row: 24, stepTime: 0.1, from: 28, to: 32);
    }
  }

  final SpriteSheet _sprites1632;

  double _run_speed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _run_speed * dt;
    if ((position.x - 160).abs() > 176) removeFromParent();
  }
}
