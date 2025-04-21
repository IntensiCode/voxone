import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/video_mode.dart';
import 'package:stardash/util/auto_dispose.dart';
import 'package:stardash/util/mutable.dart';
import 'package:stardash/util/pixelate.dart';
import 'package:stardash/util/uniforms.dart';

enum Uniform {
  scr_width,
  scr_height,
  time,
  rescale,
  cam_x,
  cam_y,
}

Space? _space;

/// CAREFUL: Removes from current parent!
Space get space {
  _space?.removeFromParent();
  return _space ??= Space._();
}

Space get known_space => _space ??= space;

class Space extends Component with AutoDispose, HasPaint {
  static FragmentShader? _shader;
  static Uniforms? _uniforms;
  static Paint? _paint;

  static double _time = 0;
  static bool _animate = true;

  Space._();

  @override
  Future<void> onLoad() async {
    priority = -10000;

    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    if (_shader != null) return;

    logInfo('load space shader');
    _shader = await loadShader('space.frag');

    _uniforms = Uniforms(_shader!, Uniform.values);
    _uniforms!.set(Uniform.scr_width, game_width);
    _uniforms!.set(Uniform.scr_height, game_height);

    _paint = pixel_paint();
    _paint!.shader = _shader;
  }

  @override
  void onMount() {
    super.onMount();
    autoDispose('on_video_change', on_video_change((_) => _update_space()));
    autoDispose('on_bg_anim_change', on_bg_anim_change((_) => _update_space()));
    _update_space();
  }

  void _update_space() {
    _last?.dispose();
    _last = null;

    _animate = bg_anim;

    final down_sampling = _animate
        ? switch (video) {
            VideoMode.performance => 4,
            VideoMode.balanced => 3,
            VideoMode.quality => 2,
          }
        : 1;

    logInfo('update space: anim=$bg_anim scale=$down_sampling');
    _src.right = game_width / down_sampling;
    _src.bottom = game_height / down_sampling;

    _uniforms!.set(Uniform.scr_width, game_width / down_sampling);
    _uniforms!.set(Uniform.scr_height, game_height / down_sampling);
    _uniforms!.set(Uniform.rescale, down_sampling.toDouble());

    _animate = bg_anim;
  }

  void setCameraOffset(double camX, double camY) {
    _uniforms?.set(Uniform.cam_x, camX);
    _uniforms?.set(Uniform.cam_y, camY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_last != null && !_animate) return;
    _time += dt;
    _uniforms!.set(Uniform.time, _time / 7);
  }

  Image? _last;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_last == null || _animate) {
      _last?.dispose();
      _last = pixelate(_src.width.toInt(), _src.height.toInt(), (canvas) {
        canvas.drawRect(_src, _paint!);
      });
    }
    if (_last != null) {
      canvas.drawImageRect(_last!, _src, _dst, paint);
    }
  }

  static final _src = MutRect(0, 0, game_width / 4, game_height / 4);
  static const _dst = Rect.fromLTWH(0, 0, game_width, game_height);
}
