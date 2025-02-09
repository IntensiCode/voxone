import 'package:flame/components.dart';

mixin FakeThreeDee on PositionComponent {
  /// used for projectiles' shadow circle radius
  double? fake_size;

  double _fake_height = 0;

  double get fake_height => _fake_height;

  set fake_height(double value) {
    _fake_height = value;
    priority = y.toInt() + fake_height.toInt();
  }

  void init_fake_3d(FakeThreeDee origin) {
    fake_height = origin.fake_height;
    position.setFrom(origin.position);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final target = y.toInt() + fake_height.toInt();
    if ((priority - target).abs() > 1) priority = target;
  }
}
