import 'dart:math';
import 'dart:ui' as ui;

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/has_position_3d.dart';
import 'package:stardash/game/position3d.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/update2d.dart';
import 'package:stardash/util/mutable.dart';
import 'package:stardash/util/pixelate.dart';
import 'package:stardash/util/uniforms.dart';

// Class definition order fixed: with before implements
class Player3D extends PositionComponent with HasVisibility, HasPosition3D, HasUpdate2D, HasContext {
  double _time = 0.0;

  static late final int _frames;
  static late final ui.Image _voxelImage;

  static late final ui.FragmentShader _shader;
  static late final ui.FragmentShader _exhaustShader;
  static late final UniformsExt<Voxel3dUniform> _uniforms;
  static late final UniformsExt<ExhaustUniform> _exhaustUniforms;

  static ui.Image? _shaderBuffer;

  final Matrix4 _modelMatrixInverse = Matrix4.identity(); // Needed for shader
  final Vector3 _lightDirection = Vector3(0.577, 0.577, -0.577)..normalize(); // Keep shader light

  final _renderSize = 256;

  final Vector3 _localLightDirection = Vector3.zero();

  Player3D({required Vector3 initialPosition}) {
    logInfo('Player3D: $initialPosition');

    anchor = Anchor.center;

    position3d = Position3D(position: initialPosition);
    position3d.needsFullTransform = true;

    // Define local vertices matching the shader's unit cube space
    // This is needed for correct depth calculation and potentially shader internal logic
    const double half = 10.0;
    const double height = 10.0;
    const double length = 10.0;
    position3d.localVertices = [
      Vector3(-half, -height, -length),
      Vector3(half, -height, -length),
      Vector3(half, height, -length),
      Vector3(-half, height, -length),
      Vector3(-half, -height, length),
      Vector3(half, -height, length),
      Vector3(half, height, length),
      Vector3(-half, height, length),
    ];
  }

  static Future? _await_shaders;

  @override
  Future<void> onLoad() async {
    final it = _await_shaders ??= _initShaders();
    await it;
  }

  Future<void> _initShaders() async {
    _frames = 15;
    _voxelImage = await game.images.load('interstellar_15.png');

    _shader = await loadShader('voxel3d.frag');
    _exhaustShader = await loadShader('exhaust.frag');
    _exhaustShader.setImageSampler(0, _voxelImage);

    _uniforms = UniformsExt<Voxel3dUniform>(_shader, {
      for (final e in Voxel3dUniform.values) e: e.type,
    });
    _exhaustUniforms = UniformsExt<ExhaustUniform>(_exhaustShader, {
      for (final e in ExhaustUniform.values) e: e.type,
    });

    _initVoxelUniforms();
    _initExhaustUniforms();
  }

  void _initVoxelUniforms() {
    final atlasSize = _voxelImage.size;
    final frameSize = Vector2(atlasSize.x, atlasSize.y / _frames);

    final u = _uniforms;
    u[Voxel3dUniform.dstOrigin] = Vector2.zero();
    u[Voxel3dUniform.dstSize] = Vector2.all(_renderSize.toDouble());
    u[Voxel3dUniform.srcOrigin] = Vector2.zero();
    u[Voxel3dUniform.atlasSize] = atlasSize;
    u[Voxel3dUniform.frames] = _frames.toDouble();
    u[Voxel3dUniform.frameSize] = frameSize;
  }

  void _initExhaustUniforms() {
    final u = _exhaustUniforms;
    u[ExhaustUniform.resolution] = _voxelImage.size;
    u[ExhaustUniform.targetColor] = Vector4(1.0, 0.2, 0.0, 1.0);
    u[ExhaustUniform.colorVariance] = 0.1;
    u[ExhaustUniform.exhaustLength] = 8.0;
    u[ExhaustUniform.color0] = Vector3(1.0, 0.0, 0.0);
    u[ExhaustUniform.color1] = Vector3(1.0, 1.0, 0.0);
    u[ExhaustUniform.color2] = Vector3(1.0, 0.0, 0.0);
    u[ExhaustUniform.color3] = Vector3(0.5, 0.0, 0.0);
    u[ExhaustUniform.color4] = Vector3(0.5, 0.0, 0.0);
  }

  @override
  void update(double dt) {
    super.update(dt); // Let mixins run first (Updates2DFrom3D sets position/size)
    _time += dt;

    // Update 3D rotation using position3d
    // position3d.rotation.x = _time * 0.6;
    // position3d.rotation.y = _time * 0.5;
    // position3d.rotation.z = _time * 1.4;
    // position3d.rotation.z = pi;
    // Scale could also be updated here if needed: position3d.scale.setValues(...)

    position3d.scale.setValues(1.5, 1.5, 1.5);

    // logInfo('renderTransform: ${position3d.renderTransform}');
  }

  late final _paint = pixel_paint();
  late final _srcRect = Rect.fromLTWH(0, 0, _renderSize * 1.0, _renderSize * 1.0);
  late final _dstRect = MutRect(0, 0, 0, 0);

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    assert(isVisible);
    assert(priority != HasPosition3D.INVISIBILITY_PRIORITY);

    // logInfo('P3D: $position $size');

    _renderExhaust();
    _renderVoxelModel();

    // position3d.projectedVertices
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.translate(-_renderSize / 2, -_renderSize / 2);
    _dstRect.setSize(_renderSize * 1.0, _renderSize * 1.0);
    // _dstRect.left = -position.x;
    // _dstRect.top = -size.y / 4;
    canvas.drawImageRect(_shaderBuffer!, _srcRect, _dstRect, _paint);

    canvas.restore();
  }

  final _shaderRect = MutRect(0, 0, 0, 0);

  void _renderExhaust() {
    _shaderBuffer?.dispose();
    _shaderBuffer = pixelate(_voxelImage.width, _voxelImage.height, (canvas) {
      _exhaustUniforms[ExhaustUniform.time] = _time;
      _paint.shader = _exhaustShader;
      _shaderRect.setFromImage(_voxelImage);
      canvas.drawRect(_shaderRect, _paint);
      _paint.shader = null;
    });
  }

  void _renderVoxelModel() {
    final img = pixelate(_renderSize, _renderSize, (canvas) {
      _updateUniforms(_shader);
      _shader.setImageSampler(0, _shaderBuffer ?? _voxelImage);
      _paint.shader = _shader;
      _shaderRect.setSizeInt(_renderSize, _renderSize);
      canvas.drawRect(_shaderRect, _paint);
      _paint.shader = null;
    });

    _shaderBuffer?.dispose();
    _shaderBuffer = img;
  }

  void _updateUniforms(ui.FragmentShader shader) {
    final _scaleMatrix = Matrix4.identity()
      ..scale(
        position3d.scale.x,
        4,
        position3d.scale.z,
      );

    final _rotationMatrix = Matrix4.identity()
      ..rotateZ(position3d.rotation.z)
      ..rotateY(position3d.rotation.y)
      ..rotateX(position3d.rotation.x);

    final _translationMatrix = Matrix4.identity()..translate(position3d.position);

    final _worldModelMatrix = Matrix4.identity()
      ..setFrom(_translationMatrix)
      ..multiply(_scaleMatrix)
      ..multiply(_rotationMatrix);

    _modelMatrixInverse.setFrom(_worldModelMatrix);
    _modelMatrixInverse.multiply(position3d.renderTransform);

    // --- Use static light for now ---
    final u = _uniforms;
    u[Voxel3dUniform.lightDirection] = _lightDirection; // Static light
    u[Voxel3dUniform.modelMatrixInverse] = _modelMatrixInverse;
  }

  @override
  void onRemove() {
    _shaderBuffer?.dispose();
    super.onRemove();
  }
}

enum Voxel3dUniform {
  dstOrigin(Vector2), // Vector2
  dstSize(Vector2), // Vector2
  srcOrigin(Vector2), // Vector2
  atlasSize(Vector2), // Vector2
  frames(double), // double
  frameSize(Vector2), // Vector2
  modelMatrixInverse(Matrix4), // Matrix4
  lightDirection(Vector3), // Vector3
  renderMode(double); // double

  final Type type;

  const Voxel3dUniform(this.type);
}

enum ExhaustUniform {
  resolution(Vector2), // Vector2
  time(double), // double
  targetColor(Vector4), // Vector4
  colorVariance(double), // double
  exhaustLength(double), // double
  color0(Vector3), // Vector3 (RGB)
  color1(Vector3), // Vector3 (RGB)
  color2(Vector3), // Vector3 (RGB)
  color3(Vector3), // Vector3 (RGB)
  color4(Vector3); // Vector3 (RGB)

  final Type type;

  const ExhaustUniform(this.type);
}
