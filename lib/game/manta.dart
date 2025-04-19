import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/util/uniforms.dart';

// Copied from voxel_sprite.dart for self-containment
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
  shift_x,
  shift_y,
  shift_z,
  shadow,
}

class MantaComponent extends PositionComponent with HasContext, HasPaint {
  double _time = 0.0;

  late Sprite _sprite;
  FragmentShader? _shader;
  Uniforms<VoxelUniform>? _uniforms;
  late int _frames;

  // Rotation and scale values
  double _rot_x = 0.0;
  double _rot_y = 0.0;
  double _rot_z = 0.0;
  final Vector3 _scale = Vector3(0.7, 0.25, 0.7);

  // Replicated from VoxelSprite for calculations
  final _x_rot_mat = Matrix3.identity();
  final _y_rot_mat = Matrix3.identity();
  final _z_rot_mat = Matrix3.identity();
  final _rot_mat = Matrix3.identity();
  final _ray_dir = Vector3.zero();
  final _u_dir = Vector3.zero();
  final _v_dir = Vector3.zero();

  MantaComponent() {
    // Ensure non-blurry rendering
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  @override
  Future<void> onLoad() async {
    logInfo('Loading Manta');

    _sprite = atlas.sprite('entities/ZaxxonPlayer-15.png');
    _frames = 15;

    try {
      _shader = await loadShader('shaders/voxel.frag');
      _uniforms = Uniforms(_shader!, VoxelUniform.values);
    } catch (e) {
      print('Error loading voxel shader: $e');
      // Handle error appropriately, maybe remove the component
    }

    size.setAll(128); // Match render size from Go example
    position = game.size / 2;
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Apply rotations based on time, similar to Go example
    _rot_x = _time * 0.6;
    _rot_y = _time * 0.5;
    _rot_z = _time * 0.4;
  }

  @override
  void render(Canvas canvas) {
    final uniforms = _uniforms;
    final shader = _shader;
    if (uniforms == null || shader == null) return; // Shader failed to load

    // --- Calculate rotation matrix and direction vectors (from VoxelSprite) ---
    _x_rot_mat.setRotationX(_rot_x);
    _y_rot_mat.setRotationY(_rot_y);
    _z_rot_mat.setRotationZ(_rot_z);

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
    // --- End rotation calculation ---

    // --- Set Shader Uniforms ---
    uniforms
      ..set(VoxelUniform.scr_x, 0)
      ..set(VoxelUniform.scr_y, 0)
      ..set(VoxelUniform.scr_width, size.x)
      ..set(VoxelUniform.scr_height, size.y)
      ..set(VoxelUniform.tex_width, _sprite.image.width.toDouble())
      ..set(VoxelUniform.tex_height, _sprite.image.height.toDouble())
      ..set(VoxelUniform.frame_x, _sprite.srcPosition.x / _sprite.image.width)
      ..set(VoxelUniform.frame_y, _sprite.srcPosition.y / _sprite.image.height)
      ..set(VoxelUniform.frame_width, _sprite.srcSize.x)
      ..set(VoxelUniform.frame_height, _sprite.srcSize.y / _frames)
      ..set(VoxelUniform.frames, _frames.toDouble())
      ..set(VoxelUniform.scale_x, _scale.x)
      ..set(VoxelUniform.scale_y, _scale.y)
      ..set(VoxelUniform.scale_z, _scale.z)
      ..set(VoxelUniform.ray_x, _ray_dir.x)
      ..set(VoxelUniform.ray_y, _ray_dir.y)
      ..set(VoxelUniform.ray_z, _ray_dir.z)
      ..set(VoxelUniform.u_x, _u_dir.x)
      ..set(VoxelUniform.u_y, _u_dir.y)
      ..set(VoxelUniform.u_z, _u_dir.z)
      ..set(VoxelUniform.v_x, _v_dir.x)
      ..set(VoxelUniform.v_y, _v_dir.y)
      ..set(VoxelUniform.v_z, _v_dir.z)
      ..set(VoxelUniform.shift_x, 0.0)
      ..set(VoxelUniform.shift_y, 0.0)
      ..set(VoxelUniform.shift_z, 0.0)
      ..set(VoxelUniform.shadow, 0.0); // No shadow

    shader.setImageSampler(0, _sprite.image);
    paint.shader = shader;
    // --- End Uniform Setup ---

    // Draw the component rectangle using the shader paint
    canvas.drawRect(size.toRect(), paint);
  }
}
