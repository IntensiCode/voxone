import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/uniforms.dart';

enum HighlightMode {
  none,
  shadow,
  hit,
}

class StackedSprite extends PositionComponent with HasPaint, HasVisibility {
  StackedSprite(this._asset, this._frames, {this.highlight_mode = HighlightMode.none}) {
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  StackedSprite.image(Image image, this._frames, {this.highlight_mode = HighlightMode.none})
      : _asset = null,
        _sprite = Sprite(image) {
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  StackedSprite.sprite(this._sprite, this._frames, {this.highlight_mode = HighlightMode.none}) : _asset = null {
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  final String? _asset;
  final int _frames;

  final _rect = MutRect(0, 0, 0, 0);

  late Sprite _sprite;
  FragmentShader? _shader;
  late final Uniforms _uniforms;
  late final Paint _paint;
  late final Paint _shadow;

  final _x_rot_mat = Matrix3.identity();
  final _y_rot_mat = Matrix3.identity();
  final _z_rot_mat = Matrix3.identity();
  final _rot_mat = Matrix3.identity();

  final _ray_dir = Vector3.zero();
  final _u_dir = Vector3.zero();
  final _v_dir = Vector3.zero();

  double scale_x = 1;
  double scale_y = 1;
  double scale_z = 1;

  double rot_x = 0;
  double rot_y = 0;
  double rot_z = 0;

  HighlightMode highlight_mode;

  void change_sprite(Sprite sprite) {
    _sprite = sprite;
    _uniforms.set(_Uniform.tex_width, _sprite.image.width.toDouble());
    _uniforms.set(_Uniform.tex_height, _sprite.image.height.toDouble());
    _uniforms.set(_Uniform.frame_x, _sprite.srcPosition.x / _sprite.image.width);
    _uniforms.set(_Uniform.frame_y, _sprite.srcPosition.y / _sprite.image.height);
    _uniforms.set(_Uniform.frame_width, _sprite.srcSize.x);
    _uniforms.set(_Uniform.frame_height, _sprite.srcSize.y / _frames);

    _shader!.setImageSampler(0, _sprite.image);
  }

  void change_image(Image image) => _shader?.setImageSampler(0, image);

  void reset() {
    highlight_mode = HighlightMode.none;
    _last?.dispose();
    _last = null;
    _update_time = 0;
    _render = true;
  }

  @override
  Future onLoad() async {
    super.onLoad();

    if (_asset != null) _sprite = atlas.sprite(_asset);

    final program = await FragmentProgram.fromAsset('assets/shaders/voxel.frag');
    _shader = program.fragmentShader();
    _uniforms = Uniforms(_shader!, _Uniform.values);
    _uniforms.set(_Uniform.scr_x, 0);
    _uniforms.set(_Uniform.scr_y, 0);
    _uniforms.set(_Uniform.tex_width, _sprite.image.width.toDouble());
    _uniforms.set(_Uniform.tex_height, _sprite.image.height.toDouble());
    _uniforms.set(_Uniform.frame_x, _sprite.srcPosition.x / _sprite.image.width);
    _uniforms.set(_Uniform.frame_y, _sprite.srcPosition.y / _sprite.image.height);
    _uniforms.set(_Uniform.frame_width, _sprite.srcSize.x);
    _uniforms.set(_Uniform.frame_height, _sprite.srcSize.y / _frames);
    _uniforms.set(_Uniform.frames, _frames.toDouble());

    _shader!.setImageSampler(0, _sprite.image);

    _paint = pixel_paint();
    _paint.shader = _shader;

    _shadow = pixel_paint();
    _shadow.colorFilter = ColorFilter.mode(Color(0x80000000), BlendMode.srcIn);
  }

  static double update_interval = 0.1;
  static final _max_renders_per_frame = kDebugMode ? 3 : 6;

  double _update_time = 0;
  bool _render = true;

  static int render_count = 0;

  @override
  void update(double dt) {
    super.update(dt);

    _update_time += dt;
    if (_update_time > update_interval) {
      _render = true;
    }
  }

  bool force_render = false;

  @override
  void render(Canvas canvas) {
    if (!force_render && _last != null) {
      if (!_render || render_count > _max_renders_per_frame) {
        _update_time = update_interval - rng.nextDoubleLimit(update_interval / 4);
        canvas.drawImage(_last!, Offset.zero, paint);
        return;
      }
    }
    _render = false;
    _update_time = rng.nextDoubleLimit(update_interval / 4);

    if (!force_render) render_count++;

    // bug fix \_('')_/
    if (kIsWeb) _shader!.setImageSampler(0, _sprite.image);

    _x_rot_mat.setRotationX(rot_x);
    _y_rot_mat.setRotationY(rot_y);
    _z_rot_mat.setRotationZ(rot_z);

    _rot_mat.setIdentity();
    _rot_mat.multiply(_x_rot_mat);
    _rot_mat.multiply(_y_rot_mat);
    _rot_mat.multiply(_z_rot_mat);

    _ray_dir.x = _rot_mat.entry(2, 0);
    _ray_dir.y = _rot_mat.entry(2, 1);
    _ray_dir.z = _rot_mat.entry(2, 2);
    _u_dir.x = -_rot_mat.entry(0, 0);
    _u_dir.y = -_rot_mat.entry(0, 1);
    _u_dir.z = -_rot_mat.entry(0, 2);
    _v_dir.x = _rot_mat.entry(1, 0);
    _v_dir.y = _rot_mat.entry(1, 1);
    _v_dir.z = _rot_mat.entry(1, 2);

    _ray_dir.normalize();
    _u_dir.normalize();
    _v_dir.normalize();

    _uniforms.set(_Uniform.shadow, highlight_mode.index.toDouble());
    _uniforms.set(_Uniform.scr_width, width);
    _uniforms.set(_Uniform.scr_height, height);
    _uniforms.set(_Uniform.scale_x, scale_x);
    _uniforms.set(_Uniform.scale_y, scale_y);
    _uniforms.set(_Uniform.scale_z, scale_z);
    _uniforms.set(_Uniform.ray_x, _ray_dir.x);
    _uniforms.set(_Uniform.ray_y, _ray_dir.y);
    _uniforms.set(_Uniform.ray_z, _ray_dir.z);
    _uniforms.set(_Uniform.u_x, _u_dir.x);
    _uniforms.set(_Uniform.u_y, _u_dir.y);
    _uniforms.set(_Uniform.u_z, _u_dir.z);
    _uniforms.set(_Uniform.v_x, _v_dir.x);
    _uniforms.set(_Uniform.v_y, _v_dir.y);
    _uniforms.set(_Uniform.v_z, _v_dir.z);

    final recorder = PictureRecorder();

    final c = Canvas(recorder);
    _rect.right = width;
    _rect.bottom = height;
    c.drawRect(_rect, _paint);

    _last?.dispose();

    final picture = recorder.endRecording();
    _last = picture.toImageSync(width.toInt(), height.toInt());
    picture.dispose();

    canvas.drawImage(_last!, Offset.zero, paint);

    _src ??= Rect.fromLTWH(0, 0, width, height);
    _dst ??= MutRect(0, 0, width, height);
  }

  Image? _last;
  Rect? _src;
  MutRect? _dst;

  void renderShadow(Canvas canvas) {
    if (_last == null) return;

    paint.colorFilter = _shadow.colorFilter;
    _dst!.right = width / scale.x;
    _dst!.bottom = height / scale.y;
    canvas.drawImageRect(_last!, _src!, _dst!, paint);
    paint.colorFilter = null;
  }
}

enum _Uniform {
  scr_x,
  scr_y,
  scr_width,
  scr_height,
  tex_width,
  tex_height,
  frame_x,
  frame_y,
  frame_width,
  frame_height,
  frames,
  scale_x,
  scale_y,
  scale_z,
  ray_x,
  ray_y,
  ray_z,
  u_x,
  u_y,
  u_z,
  v_x,
  v_y,
  v_z,
  shadow,
}
