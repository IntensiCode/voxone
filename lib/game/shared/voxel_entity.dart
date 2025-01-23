import 'dart:math';
import 'dart:ui';

import 'package:canister/canister.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/vox.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/uniforms.dart';
import 'package:voxone/voxel/vox_io.dart';

enum HighlightMode {
  none(null),
  shadow(ColorFilter.mode(shadow_dark, BlendMode.dstATop)),
  hit(ColorFilter.mode(white, BlendMode.srcIn)),
  ;

  final ColorFilter? colorFilter;

  const HighlightMode(this.colorFilter);
}

typedef VoxelCacheKey = (Object source, double rot_x, double rot_y, double rot_z);

final voxel_cache = CacheBuilder<VoxelCacheKey, Image>()
    .capacity(256)
    .expireAfterRead(Duration(seconds: 30))
    .expireAfterWrite(Duration(seconds: 30))
    .removalListener((key, value) {
  value.dispose();
  cache_remove_count++;
}).build();

int cache_remove_count = 0;

class VoxelEntity extends PositionComponent with HasPaint, HasVisibility, FakeThreeDee {
  /// Render new image at most every [update_interval] seconds.
  static double update_interval = 0.1;

  /// During one frame, render at most [max_renders_per_frame] new images across **all** [VoxelEntity] instances.
  static int max_renders_per_frame = kDebugMode ? 5 : 8;

  /// Render count per frame. Has to be reset from the top level game screen [renderTree] method.
  static int render_count = 0;

  /// Limit rotations to [rot_steps] steps along every axis. This limits the number of images to cache.
  static int rot_steps = 9;

  /// Pixel multiplier for pixelation. When changed, the cache has to be cleared.
  static double pixel_multiplier = 1;

  late Sprite _sprite;
  late FragmentShader _shader;
  late Uniforms<VoxelUniform> _uniforms;
  late int _frames;

  final _shadow_paint = pixel_paint()..colorFilter = ColorFilter.mode(shadow, BlendMode.srcIn);
  final _shader_paint = pixel_paint();

  bool _disposable_image = false;
  bool _dirty_shader = true;
  bool _render = true;

  double _update_time = 0;

  double scale_x = 1;
  double scale_y = 1;
  double scale_z = 1;

  double rot_x = 0;
  double rot_y = 0;
  double rot_z = 0;

  var highlight_mode = HighlightMode.none;

  /// Cache the rendered images.
  bool cache_render = true;

  /// Force rendering every frame.
  bool force_render = false;

  VoxelEntity() {
    anchor = Anchor.center;
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  VoxelShadow create_linked_shadow() {
    final it = VoxelShadow(this);
    removed.then((_) {
      if (it.isRemoved || it.isRemoving) return;
      it.removeFromParent();
    });
    return it;
  }

  Future set_vox_source(String name, {List<int>? blurred_argb32}) async {
    final voxels = await vox(name);
    set_voxels_source(voxels, blurred_argb32: blurred_argb32);
  }

  /// Create stacked sprite image from the given [voxels]. Expensive operation.
  void set_voxels_source(Voxels voxels, {List<int>? blurred_argb32}) {
    final sprite = Sprite(vox_to_image(voxels, blurred_argb32: blurred_argb32));
    set_sprite_source(sprite, voxels.height, disposable_image: true);
  }

  /// Create stacked sprite image from the given [image]. Uses the entire image.
  /// Use the [sprite] constructor when using a texture atlas.
  ///
  /// Requires the voxel height/layers as [frames].
  /// The image is expected to contain all frames stacked vertically (sprite sheet with single column).
  void set_image_source(Image image, int frames, {bool disposable_image = false}) =>
      set_sprite_source(Sprite(image), frames, disposable_image: disposable_image);

  /// Create stacked sprite image from the given [sprite]. Especially useful for atlas sprites.
  ///
  /// Requires the voxel height/layers as [frames].
  /// The sprite is expected to contain all frames stacked vertically (sprite sheet with single column).
  void set_sprite_source(Sprite sprite, int frames, {bool disposable_image = false}) {
    if (_disposable_image) _sprite.image.dispose();
    _disposable_image = disposable_image;
    _sprite = sprite;
    _frames = frames;

    _dirty_shader = true;

    reset_sprite_data(reset_mode: false);
  }

  void reset_sprite_data({bool reset_mode = true}) {
    if (reset_mode) highlight_mode = HighlightMode.none;

    if (_dispose_last) _last?.dispose();
    _dispose_last = false;
    _last = null;

    _update_time = 0;
    _render = true;
  }

  /// Change to a new image. Keeping the same number of frames (voxel height/layers).
  void change_image_source(Image image, {bool disposable_image = false}) =>
      change_sprite_source(Sprite(image), disposable_image: disposable_image);

  /// Change to a new sprite. Keeping the same number of frames (voxel height/layers).
  void change_sprite_source(Sprite sprite, {bool disposable_image = false}) =>
      set_sprite_source(sprite, _frames, disposable_image: disposable_image);

  /// Free image resources and the shader. Cannot be (re)used anymore after calling this.
  void dispose_sprite() {
    logInfo('disposing voxel sprite $this - disposable image? $_disposable_image');

    if (_disposable_image) _sprite.image.dispose();
    _disposable_image = false;

    if (_dispose_last) _last?.dispose();
    _dispose_last = false;
    _last = null;

    _shader.dispose();
  }

  void render_shadow(Canvas canvas, VoxelEntity source) {
    try {
      if (isRemoving || isRemoved || !isVisible) return;
      if (_last == null) return; // bail out if no actual image has been rendered, yet
      canvas.drawImageRect(_last!, _src, _dst, _shadow_paint);
    } catch (e) {
      if (dev) logError('shadow error for ${source.runtimeType} - ignored: $e');
    }
  }

  @override
  Future onLoad() async {
    logInfo('loading voxel shader');
    _shader = await loadShader('voxel.frag');
    _uniforms = Uniforms(_shader, VoxelUniform.values);
    // try {
    //   _update_shader();
    // } catch (it, st) {
    //   logError('call set_source before adding/loading $this - $it', st);
    // }
  }

  /// Progress the render update timer.
  @override
  void update(double dt) {
    _update_time += dt;
    if (_update_time > update_interval) _render = true;

    // _update_time will be reset only after a successful render. See below in [render].
    // This can be delayed because of [max_renders_per_frame].
    // Therefore, not resetting _update_time here.

    render_count = 0;
  }

  // madness lies below...

  @override
  void render(Canvas canvas) {
    final rs = 2 * pi / rot_steps;
    final rx = force_render ? rot_x : (rot_x / rs).round() * rs;
    final ry = force_render ? rot_y : (rot_y / rs).round() * rs;
    final rz = force_render ? rot_z : (rot_z / rs).round() * rs;
    final key = (_sprite, rx, ry, rz);
    final cached = voxel_cache[key];

    final width = size.x;
    final height = size.y;

    _dst.right = width;
    _dst.bottom = height;

    // if the required image is cached, use it and bail out early:
    if (cached != null) {
      if (_dispose_last) _last?.dispose();
      _dispose_last = false;
      _last = cached;

      _src.right = cached.width.toDouble();
      _src.bottom = cached.height.toDouble();
      paint.colorFilter = highlight_mode.colorFilter;
      canvas.drawImageRect(cached, _src, _dst, paint);
      return;
    }

    // unless force_render is set, try to use the last image:
    if (!force_render && _last != null) {
      // if no new render is requests, or the limit is reached, use the last image:
      // (this can now be the wrong rotation, but it's better than nothing.)
      if (!_render || render_count > max_renders_per_frame) {
        _update_time = update_interval - rng.nextDoubleLimit(update_interval / 4);
        try {
          _src.right = _last!.width.toDouble();
          _src.bottom = _last!.height.toDouble();
          paint.colorFilter = highlight_mode.colorFilter;
          canvas.drawImageRect(_last!, _src, _dst, paint);
          return;
        } catch (e) {
          if (dev) logError('last image disposed - ignored: $e');
        }
      }
    }

    _render = false;
    _update_time = rng.nextDoubleLimit(update_interval / 4);

    if (!force_render) render_count++; // force does not count against the render limit

    _x_rot_mat.setRotationX(rx);
    _y_rot_mat.setRotationY(ry);
    _z_rot_mat.setRotationZ(rz);

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

    if (_dirty_shader) _update_shader();

    // TODO still required? bug fix \_('')_/
    if (!_dirty_shader && kIsWeb) _shader.setImageSampler(0, _sprite.image);

    _dirty_shader = false;

    _uniforms
      ..set(VoxelUniform.shadow, 0)
      ..set(VoxelUniform.scr_width, width * pixel_multiplier)
      ..set(VoxelUniform.scr_height, height * pixel_multiplier)
      ..set(VoxelUniform.scale_x, scale_x)
      ..set(VoxelUniform.scale_y, scale_y)
      ..set(VoxelUniform.scale_z, scale_z)
      ..set(VoxelUniform.ray_x, _ray_dir.x)
      ..set(VoxelUniform.ray_y, _ray_dir.y)
      ..set(VoxelUniform.ray_z, _ray_dir.z)
      ..set(VoxelUniform.u_x, _u_dir.x)
      ..set(VoxelUniform.u_y, _u_dir.y)
      ..set(VoxelUniform.u_z, _u_dir.z)
      ..set(VoxelUniform.v_x, _v_dir.x)
      ..set(VoxelUniform.v_y, _v_dir.y)
      ..set(VoxelUniform.v_z, _v_dir.z);

    // TODO can we reuse this safely somehow?
    // for HighlightMode != none, the previous image has to be disposed:
    if (_dispose_last) _last?.dispose();

    _src.right = width * pixel_multiplier;
    _src.bottom = height * pixel_multiplier;
    _last = pixelate(_src.right.toInt(), _src.bottom.toInt(), (canvas) {
      canvas.drawRect(_src, _shader_paint);
    });
    paint.colorFilter = highlight_mode.colorFilter;
    canvas.drawImageRect(_last!, _src, _dst, paint);

    try {
      if (cache_render) {
        _dispose_last = false;
        voxel_cache[key] = _last!;
      } else {
        _dispose_last = true;
      }
    } catch (e) {
      // this can be caused by removal triggered by adding one image to much. sometimes images are already disposed.
      // some bug somewhere else.. :]
      if (dev) logError('cache error - ignored: $e');
    }
  }

  Image? _last;
  bool _dispose_last = false;

  final _x_rot_mat = Matrix3.identity();
  final _y_rot_mat = Matrix3.identity();
  final _z_rot_mat = Matrix3.identity();
  final _rot_mat = Matrix3.identity();

  final _ray_dir = Vector3.zero();
  final _u_dir = Vector3.zero();
  final _v_dir = Vector3.zero();

  final _src = MutRect.zero();
  final _dst = MutRect.zero();

  void _update_shader() {
    _uniforms
      ..set(VoxelUniform.scr_x, 0)
      ..set(VoxelUniform.scr_y, 0)
      ..set(VoxelUniform.tex_width, _sprite.image.width.toDouble())
      ..set(VoxelUniform.tex_height, _sprite.image.height.toDouble())
      ..set(VoxelUniform.frame_x, _sprite.srcPosition.x / _sprite.image.width)
      ..set(VoxelUniform.frame_y, _sprite.srcPosition.y / _sprite.image.height)
      ..set(VoxelUniform.frame_width, _sprite.srcSize.x)
      ..set(VoxelUniform.frame_height, _sprite.srcSize.y / _frames)
      ..set(VoxelUniform.frames, _frames.toDouble());

    _shader.setImageSampler(0, _sprite.image);

    _shader_paint.shader = _shader;
  }
}

class VoxelShadow extends Component with HasPaint, HasVisibility {
  VoxelShadow(this._source) {
    paint.color = black.withAlpha(128);
  }

  final VoxelEntity _source;

  @override
  void render(Canvas canvas) {
    if (_source.isRemoving || _source.isRemoved || !_source.isVisible) return;

    final fake_height = _source.fake_height;
    if (fake_height == 0) return;

    final pp = _source;
    canvas.save();
    canvas.translate(pp.x, pp.y);
    canvas.translate(fake_height / 4, fake_height);
    canvas.translate(-pp.scaledSize.x / 2, -pp.scaledSize.y / 2);
    canvas.scaleVector(pp.scale);
    _source.render_shadow(canvas, _source);
    canvas.restore();
  }
}

enum VoxelUniform {
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
