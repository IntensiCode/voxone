import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/mut_rect.dart';
import 'package:voxone/util/uniforms.dart';

enum Uniform {
  scr_x,
  scr_y,
  scr_width,
  scr_height,
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
}

class StackedSprite extends PositionComponent {
  StackedSprite(this._asset, this._frames) {
    anchor = Anchor.center;
  }

  final String _asset;
  final int _frames;

  final _rect = MutRect(0, 0, 0, 0);
  final _pixel_paint = pixel_paint();

  late final Image _image;
  late final FragmentShader _shader;
  late final Uniforms _uniforms;
  late final Paint _paint;

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

  @override
  Future onLoad() async {
    super.onLoad();

    _image = await images.load(_asset);

    final program = await FragmentProgram.fromAsset('assets/shaders/voxel.frag');
    _shader = program.fragmentShader();
    _shader.setImageSampler(0, _image);

    _uniforms = Uniforms(_shader, Uniform.values);
    _uniforms.set(Uniform.scr_x, 0);
    _uniforms.set(Uniform.scr_y, 0);
    _uniforms.set(Uniform.frame_width, _image.width.toDouble());
    _uniforms.set(Uniform.frame_height, _image.height / _frames);
    _uniforms.set(Uniform.frames, _frames.toDouble());

    _paint = pixel_paint();
    _paint.shader = _shader;
  }

  @override
  void render(Canvas canvas) {
    // canvas.drawRect(Rect.fromLTWH(0, 0, width, height), pixel_paint()..style = PaintingStyle.stroke);

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

    _uniforms.set(Uniform.scr_width, width);
    _uniforms.set(Uniform.scr_height, height);
    _uniforms.set(Uniform.scale_x, scale_x);
    _uniforms.set(Uniform.scale_y, scale_y);
    _uniforms.set(Uniform.scale_z, scale_z);
    _uniforms.set(Uniform.ray_x, _ray_dir.x);
    _uniforms.set(Uniform.ray_y, _ray_dir.y);
    _uniforms.set(Uniform.ray_z, _ray_dir.z);
    _uniforms.set(Uniform.u_x, _u_dir.x);
    _uniforms.set(Uniform.u_y, _u_dir.y);
    _uniforms.set(Uniform.u_z, _u_dir.z);
    _uniforms.set(Uniform.v_x, _v_dir.x);
    _uniforms.set(Uniform.v_y, _v_dir.y);
    _uniforms.set(Uniform.v_z, _v_dir.z);

    final recorder = PictureRecorder();

    final c = Canvas(recorder);
    _rect.right = width;
    _rect.bottom = height;
    c.drawRect(_rect, _paint);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width.toInt(), height.toInt());
    canvas.drawImage(image, Offset.zero, _pixel_paint);
    image.dispose();
    picture.dispose();
  }
}
