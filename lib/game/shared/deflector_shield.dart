import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/energy_shield.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/uniforms.dart';

class DeflectorShield extends PositionComponent with HasContext, HasPaint, HasTraits {
  DeflectorShield(Target target) {
    size.setAll(96);
    add(CircleHitbox(anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.1
      ..renderShape = debug);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    priority = -1;

    addTrait(EnergyShield(this, target, () => _deflect_time = 0.3));
  }

  bool auto_recharge = true;

  double _deflect_time = 0;

  late final FragmentShader _shader;

  @override
  onLoad() async {
    _shader = await loadShader('plasma_shield.frag');
    paint.shader = _shader;
    priority = 1;
    opacity = 0.5;
    angle = -0.2;
    _shader.setFloat(0, size.x);
    _shader.setFloat(1, size.y);
  }

  EnergyShield? _shield;

  @override
  void update(double dt) {
    super.update(dt);

    if (auto_recharge) {
      _shield ??= singleTrait<EnergyShield>();
      if (_shield!.energy < 1) _shield!.energy += dt / 3;
    }

    if (_deflect_time > 0) _deflect_time -= dt;

    _shader.setFloat(4, _deflect_time);
  }

  final _rect = MutRect(0, 0, 0, 0);
  Offset? _offset;

  @override
  void render(Canvas canvas) {
    if (_deflect_time <= 0) return;

    final image = pixelate(size.x.toInt(), size.y.toInt(), (canvas) {
      _rect.right = size.x;
      _rect.bottom = size.y;
      canvas.drawRect(_rect, paint);
    });

    _offset ??= Offset(-size.x / 2, -size.y / 2);
    _paint.opacity = _deflect_time > 0 ? 0.75 : 0.05;
    canvas.drawImage(image, _offset!, _paint);
    image.dispose();
  }

  final _paint = pixel_paint();
}
