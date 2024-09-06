import 'package:flame/components.dart';

class Delayed extends Component {
  Delayed(this.delaySeconds, this.action);

  double delaySeconds;
  final Function action;

  @override
  void update(double dt) {
    super.update(dt);
    if (delaySeconds > 0) {
      delaySeconds -= dt;
    } else {
      action();
      removeFromParent();
    }
  }
}
