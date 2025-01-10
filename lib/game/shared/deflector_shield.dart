import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
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

class DeflectorShield extends PositionComponent with HasContext, HasPaint, HasTraits implements Integrity {
  static final _shaders = <String, FragmentShader>{};

  static preload() async {
    logInfo('preload deflector shield shaders');
    // _shaders['plasma_shield.frag'] = await loadShader('plasma_shield.frag');
    _shaders['hex_shield.frag'] = await loadShader('hex_shield.frag');
  }

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

  double auto_recharge = 0.3;

  double _deflect_time = 0;
  double _rotate_time = 0;

  double max_rotate_time = 0.25;

  late final FragmentShader _shader;

  EnergyShield? _shield;

  EnergyShield get shield => _shield ??= singleTrait<EnergyShield>();

  double get energy => shield.energy;

  @override
  double get integrity_in_percent => shield.energy.clamp(0, 1) * 100;

  void on_shield_boost() {
    shield.on_shield_boost();
    auto_recharge = min(0.75, auto_recharge + 0.05);
  }

  @override
  onLoad() async {
    _shader = _shaders[_shader_name] ?? await loadShader(_shader_name);
    _paint.shader = _shader;
    priority = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);

    shield.recharge(dt * auto_recharge);

    if (_deflect_time > 0) {
      _deflect_time -= dt;
      _rotate_time += dt;
      _rotate_time %= max_rotate_time;
    }

    _shader.setFloat(0, size.x);
    _shader.setFloat(1, size.y);
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
      _paint.opacity = _deflect_time > 0 ? 0.75 : 0.05;
      _paint.shader = _shader;
      canvas.drawRect(_rect, _paint);
    });

    _offset ??= Offset(-size.x / 2, -size.y / 2);
    canvas.drawImage(image, _offset!, paint);
    image.dispose();
  }

  final _paint = pixel_paint();
}
