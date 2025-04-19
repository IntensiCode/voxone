import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/core/traits.dart';
import 'package:stardash/game/shared/energy_shield.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/messages.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/mutable.dart';
import 'package:stardash/util/pixelate.dart';
import 'package:stardash/util/uniforms.dart';

class DeflectorShield extends PositionComponent with HasContext, HasPaint, HasTraits implements Integrity {
  static final _shaders = <String, FragmentShader>{};

  static Future<FragmentShader> preload() async {
    logInfo('preload deflector shield shaders');

    // FIXME this breaks the player shield when an enemy shield is active
    // _shaders['plasma_shield.frag'] = await loadShader('plasma_shield.frag');

    return _shaders['hex_shield.frag'] ??= await loadShader('hex_shield.frag');
  }

  DeflectorShield(Target target, {required Vector2 source_size, String shader_name = 'plasma_shield.frag'})
      : _shader_name = shader_name {
    size = source_size;
    anchor = Anchor.center;
    anchor_to_parent();

    // the shader does not fill the entire area. hence the 0.85:
    final shader_factor = shader_name == 'plasma_shield.frag' ? 0.875 : 0.95;
    add(CircleHitbox(radius: size.x / 2 * shader_factor, anchor: Anchor.center, isSolid: true)..anchor_to_parent());

    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    priority = -1;

    addTrait(EnergyShield(target, () => _deflect_time = 0.3, () {
      // NPE in web sometimes!?
      try {
        if (isMounted) sendMessage(Rumble(duration: 0.2, haptic: false));
      }
      catch (e, st) {
        if (dev) logError('rumble failed - ignored: $e', st);
      }
    }));
  }

  final String _shader_name;

  double auto_recharge = 0.3;

  double _deflect_time = 0;
  double _rotate_time = 0;

  double max_rotate_time = 0.25;

  late final FragmentShader _shader;

  EnergyShield? _shield;

  EnergyShield get shield => _shield ??= singleTrait<EnergyShield>();

  double get energy => max(0, shield.energy);

  @override
  bool get show_indicator => shield.show_indicator;

  @override
  double get integrity_in_percent => shield.energy.clamp(0, 1) * 100;

  void on_shield_boost({double amount = 0.05}) {
    shield.on_shield_boost();
    auto_recharge = min(0.75, auto_recharge + amount);
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

    canvas.drawImage(image, Offset.zero, paint);
    image.dispose();
  }

  final _paint = pixel_paint();
}
