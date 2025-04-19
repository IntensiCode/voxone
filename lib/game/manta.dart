import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/util/uniforms.dart';

// Uniforms matching shaders/voxel3d.frag - FLATTENED
// Total floats: 16 (mat4) + 3 (vec3) + 2 (vec2) + 1 (float) + 1 (float) + 2 (vec2) + 2 (vec2) = 27
enum Voxel3dUniform {
  // uVoxelModelMatrixInverse (mat4)
  mat0, mat1, mat2, mat3, // Row 1
  mat4, mat5, mat6, mat7, // Row 2
  mat8, mat9, mat10, mat11, // Row 3
  mat12, mat13, mat14, mat15, // Row 4
  // uLightDirection (vec3)
  lightX, lightY, lightZ,
  // uFrameSize (vec2)
  frameX, frameY,
  // uFrames (float)
  frames,
  // uRenderMode (int as float)
  renderMode,
  // uSrcOrigin (vec2)
  srcOriginX, srcOriginY,
  // uAtlasSize (vec2)
  atlasSizeX, atlasSizeY,
}

class MantaComponent extends PositionComponent with HasContext, HasPaint {
  double _time = 0.0;

  late Sprite _sprite;
  FragmentShader? _shader;
  Uniforms<Voxel3dUniform>? _uniforms;
  late int _frames;

  final Vector3 _scale = Vector3(0.7, 0.25, 0.7);
  final Vector3 _rotation = Vector3.zero();
  final Matrix4 _modelMatrix = Matrix4.identity();
  final Matrix4 _modelMatrixInverse = Matrix4.identity();
  final Vector3 _lightDirection = Vector3(0.577, 0.577, -0.577)..normalize();

  // Store matrix data locally for setting uniforms
  final Float32List _matrixData = Float32List(16);

  MantaComponent() {
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  @override
  Future<void> onLoad() async {
    logInfo('Loading Manta');
    _sprite = atlas.sprite('entities/ZaxxonPlayer-15.png');
    _frames = 15;
    try {
      _shader = await loadShader('voxel3d.frag');
      _uniforms = Uniforms(_shader!, Voxel3dUniform.values);
    } catch (e) {
      logError('Error loading voxel3d shader: $e');
      // If loading fails, _shader or _uniforms might be null.
    }

    // Assert that shader and uniforms are loaded successfully before proceeding
    assert(_shader != null, 'Shader failed to load.');
    assert(_uniforms != null, 'Uniforms failed to initialize.');

    size.setAll(128);
    position = game.size / 2;
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _rotation.x = _time * 0.6;
    _rotation.y = _time * 0.5;
    _rotation.z = _time * 0.4;
    final scaleMatrix = Matrix4.identity()..scale(_scale);
    final rotX = Matrix4.rotationX(_rotation.x);
    final rotY = Matrix4.rotationY(_rotation.y);
    final rotZ = Matrix4.rotationZ(_rotation.z);
    final rotationMatrix = rotZ * rotY * rotX;
    _modelMatrix.setFrom(rotationMatrix * scaleMatrix);
    _modelMatrixInverse.copyInverse(_modelMatrix);
    _modelMatrixInverse.copyIntoArray(_matrixData);
  }

  @override
  void render(Canvas canvas) {
    // Draw a red rectangle
    paint.color = const Color(0x8000FF00);
    canvas.drawRect(size.toRect(), paint);

    // Use null-aware operators as assertions are now in onLoad
    final uniforms = _uniforms!;
    final shader = _shader!;

    final frameSizeVec = Vector2(_sprite.srcSize.x, _sprite.srcSize.y / _frames);
    final srcOriginVec = _sprite.srcPosition;
    final atlasSizeVec = Vector2(_sprite.image.width.toDouble(), _sprite.image.height.toDouble());

    // Set Matrix uniforms (indices 0-15)
    for (int i = 0; i < 16; i++) {
      uniforms.set(Voxel3dUniform.values[i], _matrixData[i].toDouble());
    }

    // Set Vec3 uniforms (indices 16-18)
    uniforms.set(Voxel3dUniform.lightX, _lightDirection.x);
    uniforms.set(Voxel3dUniform.lightY, _lightDirection.y);
    uniforms.set(Voxel3dUniform.lightZ, _lightDirection.z);

    // Set Vec2 uniforms (indices 19-20)
    uniforms.set(Voxel3dUniform.frameX, frameSizeVec.x);
    uniforms.set(Voxel3dUniform.frameY, frameSizeVec.y);

    // Set Float uniforms (indices 21-22)
    uniforms.set(Voxel3dUniform.frames, _frames.toDouble());
    uniforms.set(Voxel3dUniform.renderMode, 0.0); // Pass int as float

    // Set Vec2 uniforms for SrcOrigin (indices 23-24)
    uniforms.set(Voxel3dUniform.srcOriginX, srcOriginVec.x);
    uniforms.set(Voxel3dUniform.srcOriginY, srcOriginVec.y);

    // Set Vec2 uniforms for AtlasSize (indices 25-26)
    uniforms.set(Voxel3dUniform.atlasSizeX, atlasSizeVec.x);
    uniforms.set(Voxel3dUniform.atlasSizeY, atlasSizeVec.y);

    shader.setImageSampler(0, _sprite.image);
    paint.shader = shader;

    canvas.drawRect(size.toRect(), paint);
  }
}
