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
  DeflectorShield(Target target, {String shader_name = 'plasma_shield.frag'}) : _shader_name = shader_name {
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

  final String _shader_name;

  double? auto_recharge = 0.3;

  double _deflect_time = 0;
  double _rotate_time = 0;

  double max_rotate_time = 0.25;

  late final FragmentShader _shader;

  EnergyShield? _shield;

  EnergyShield get shield => _shield ??= singleTrait<EnergyShield>();

  @override
  onLoad() async {
    _shader = await loadShader(_shader_name);
    paint.shader = _shader;
    priority = 1;
    opacity = 0.5;
    angle = -0.2;
    _shader.setFloat(0, size.x);
    _shader.setFloat(1, size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (auto_recharge != null) {
      shield.recharge(dt * auto_recharge!);
    }

    if (_deflect_time > 0) {
      _deflect_time -= dt;
      _rotate_time += dt;
      _rotate_time %= max_rotate_time;
    }

    _shader.setFloat(4, _rotate_time);
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
