import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/util/uniforms.dart';

/*
// Uniforms replacing Kage built-ins
uniform vec2 uDstOrigin;// Corresponds to imageDstOrigin()
uniform vec2 uDstSize;// Corresponds to imageDstSize()
uniform vec2 uSrcOrigin;// Corresponds to imageSrc0Origin()
uniform vec2 uAtlasSize;// Total size of the atlas texture (pixels)

// Uniforms mapping Kage 'var's
uniform float uFrames;// Number of frames/slices
uniform vec2 uFrameSize;// Size of one frame/slice in the atlas
uniform mat4 uVoxelModelMatrixInverse;
uniform vec3 uLightDirection;

uniform float uRenderMode;// USE float INSTEAD OF int FOR IMPELLER
 */

// Restore full uniform enum for voxel3d.frag - FLATTENED
// Total floats: 16(mat4) + 3(vec3) + 2(vec2) + 1(float) + 1(float) + 2(vec2) + 2(vec2) + 2(vec2) + 2(vec2) = 31
enum Voxel3dUniform {
  // uDstOrigin (vec2)
  dstOriginX,
  dstOriginY,
  // uDstSize (vec2)
  dstSizeX,
  dstSizeY,
  // uSrcOrigin (vec2)
  srcOriginX,
  srcOriginY,
  // uAtlasSize (vec2)
  atlasSizeX,
  atlasSizeY,
  // uFrames (float)
  frames,
  // uFrameSize (vec2)
  frameX,
  frameY,
  // uVoxelModelMatrixInverse (mat4)
  mat0,
  mat1,
  mat2,
  mat3,
  mat4,
  mat5,
  mat6,
  mat7,
  mat8,
  mat9,
  mat10,
  mat11,
  mat12,
  mat13,
  mat14,
  mat15,
  // uLightDirection (vec3)
  lightX,
  lightY,
  lightZ,
  // uRenderMode (int as float)
  renderMode,
}

class MantaComponent extends PositionComponent with HasContext, HasPaint {
  double _time = 0.0;

  late Image _voxelImage;
  FragmentShader? _shader;
  FragmentShader? _shadow;
  Uniforms<Voxel3dUniform>? _uniforms;
  late int _frames;

  // Restore original scale
  final Vector3 _scale = Vector3(0.7, 0.25, 0.7);
  final Vector3 _rotation = Vector3.zero();
  final Matrix4 _modelMatrix = Matrix4.identity();
  final Matrix4 _modelMatrixInverse = Matrix4.identity();
  final Vector3 _lightDirection = Vector3(0.577, 0.577, -0.577)..normalize();
  final Float32List _matrixData = Float32List(16);

  MantaComponent() {
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  @override
  Future<void> onLoad() async {
    logInfo('Loading Manta');
    try {
      _voxelImage = await game.images.load('interstellar_15.png');
      // _voxelImage = await game.images.load('manta_19.png');
    } catch (e) {
      logError('Error loading voxel image: $e');
      return;
    }
    _frames = 15;
    try {
      _shader = await loadShader('voxel3d.frag');
      _shader!.setImageSampler(0, _voxelImage);
      _shadow = await loadShader('shadow3d.frag');
      _shadow!.setImageSampler(0, _voxelImage);
      _uniforms = Uniforms(_shader!, Voxel3dUniform.values);
    } catch (e) {
      logError('Error loading voxel3d shader: $e');
    }
    assert(_shader != null, 'Shader failed to load.');
    assert(_uniforms != null, 'Uniforms failed to initialize.');
    size.setAll(256);
    // position = game.size / 2;
    anchor = Anchor.topLeft;
  }

  @override
  void update(double dt) {
    // Restore matrix update logic
    super.update(dt);
    _time += dt;
    _rotation.x = _time * 0.6;
    _rotation.y = _time * 0.5;
    _rotation.z = _time * 0.4;
    // Use scale = (1,1,1) for this test
    final scaleMatrix = Matrix4.identity()..scale(_scale);
    final rotX = Matrix4.rotationX(_rotation.x);
    final rotY = Matrix4.rotationY(_rotation.y);
    final rotZ = Matrix4.rotationZ(_rotation.z);
    final rotationMatrix = rotZ * rotY * rotX;
    _modelMatrix.setFrom(rotationMatrix * scaleMatrix);
    // Ensure inverse calculation is active
    _modelMatrixInverse.copyInverse(_modelMatrix);
    _modelMatrixInverse.copyIntoArray(_matrixData);
  }

  @override
  void render(Canvas canvas) {
    // Remove debug paint
    // paint.color = const Color(0x8000FF00);
    // canvas.drawRect(size.toRect(), paint);

    if (_shader == null || _uniforms == null) return;

    _update_uniforms(_shader!);
    _update_uniforms(_shadow!);

    paint.shader = _shadow;
    canvas.translate(128, 128);
    canvas.drawRect(size.toRect(), paint);

    paint.shader = _shader;
    canvas.translate(-128, -128);
    canvas.drawRect(size.toRect(), paint);
  }

  void _update_uniforms(FragmentShader shader) {
    final uniforms = _uniforms!;
    uniforms.switch_shader(shader);

    final frameSizeVec = Vector2(_voxelImage.width.toDouble(), _voxelImage.height.toDouble() / _frames);
    final atlasSizeVec = Vector2(_voxelImage.width.toDouble(), _voxelImage.height.toDouble());
    final srcOriginVec = Vector2.zero();
    final dstOriginVec = Vector2.zero();
    final dstSizeVec = size;

    // Restore setting ALL uniforms
    // Matrix (0-15)
    uniforms.set(Voxel3dUniform.dstOriginX, dstOriginVec.x);
    uniforms.set(Voxel3dUniform.dstOriginY, dstOriginVec.y);
    uniforms.set(Voxel3dUniform.dstSizeX, dstSizeVec.x);
    uniforms.set(Voxel3dUniform.dstSizeY, dstSizeVec.y);
    uniforms.set(Voxel3dUniform.srcOriginX, srcOriginVec.x);
    uniforms.set(Voxel3dUniform.srcOriginY, srcOriginVec.y);
    uniforms.set(Voxel3dUniform.atlasSizeX, atlasSizeVec.x);
    uniforms.set(Voxel3dUniform.atlasSizeY, atlasSizeVec.y);
    uniforms.set(Voxel3dUniform.frames, _frames.toDouble());
    uniforms.set(Voxel3dUniform.frameX, frameSizeVec.x);
    uniforms.set(Voxel3dUniform.frameY, frameSizeVec.y);
    uniforms.set(Voxel3dUniform.lightX, _lightDirection.x);
    uniforms.set(Voxel3dUniform.lightY, _lightDirection.y);
    uniforms.set(Voxel3dUniform.lightZ, _lightDirection.z);
    for (int i = 0; i < 16; i++) {
      uniforms.set(Voxel3dUniform.values[Voxel3dUniform.mat0.index + i], _matrixData[i].toDouble());
    }
    uniforms.set(Voxel3dUniform.renderMode, 0.0);
  }
}
