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
import 'package:stardash/input/keys.dart';
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

  Player3D({required Vector3 initialPosition}) {
    logInfo('Player3D: $initialPosition');
    anchor = Anchor.center;
    _initPosition3d(initialPosition);
  }

  void _initPosition3d(Vector3 initialPosition) {
    // Scale to fit voxel data into render box
    position3d = Position3D(position: initialPosition, scale: Vector3.all(1.4));
    position3d.needsFullTransform = true;

    const double a = 13;
    const double b = 13;
    const double c = 13;
    position3d.localVertices = [
      Vector3(-a, -b, -c),
      Vector3(a, -b, -c),
      Vector3(a, b, -c),
      Vector3(-a, b, -c),
      Vector3(-a, -b, c),
      Vector3(a, -b, c),
      Vector3(a, b, c),
      Vector3(-a, b, c),
    ];
  }

  static Future? _await_shaders;
  late final bool _leader;

  @override
  Future<void> onLoad() async {
    _leader = _await_shaders == null;
    await (_await_shaders ??= _initShaders());
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
    super.update(dt);
    _time += dt;

    if (autoRotate) {
      position3d.rotation.x += dt * 0.6;
      position3d.rotation.y += dt * 0.5;
    }
    position3d.rotation.z += dt * 0.4;

    const speed = pi / 2;
    if (keys.check(GameKey.down)) position3d.rotation.x -= dt * speed;
    if (keys.check(GameKey.up)) position3d.rotation.x += dt * speed;
    if (keys.check(GameKey.left)) position3d.rotation.y += dt * speed;
    if (keys.check(GameKey.right)) position3d.rotation.y -= dt * speed;
    if (keys.check(GameKey.a_button)) autoRotate = !autoRotate;
  }

  bool autoRotate = true;

  late final _paint = pixel_paint();

  final _srcRect = MutRect(0, 0, 0, 0);
  final _dstRect = MutRect(0, 0, 0, 0);
  final _shaderRect = MutRect(0, 0, 0, 0);

  static ui.Image? _exhaustBuffer;
  static ui.Image? _shaderBuffer;

  var _renderSize = 128;

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    assert(isVisible);
    assert(priority != HasPosition3D.INVISIBILITY_PRIORITY);

    _renderSize = min(size.x, size.y).toInt().clamp(16, 256);
    _srcRect.setSize(_renderSize * 1.0, _renderSize * 1.0);

    if (_leader) _renderExhaust();
    _renderVoxelModel();

    _renderSize = 256;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(position3d.scaleFactor);
    canvas.translate(-_renderSize / 2, -_renderSize / 2);
    _dstRect.setSize(_renderSize * 1.0, _renderSize * 1.0);
    canvas.drawImageRect(_shaderBuffer!, _srcRect, _dstRect, _paint);

    canvas.restore();
  }

  void _renderExhaust() {
    _exhaustBuffer?.dispose();
    _exhaustBuffer = pixelate(_voxelImage.width, _voxelImage.height, (canvas) {
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
      _paint.shader = _shader;
      _shaderRect.setSizeInt(_renderSize, _renderSize);
      canvas.drawRect(_shaderRect, _paint);
      _paint.shader = null;
    });

    _shaderBuffer?.dispose();
    _shaderBuffer = img;
  }

  final _tmpMat = Matrix4.identity();

  void _updateUniforms(ui.FragmentShader shader) {
    // To fix the voxel model proportions we scale again:
    _tmpMat.setIdentity();
    _tmpMat.scale(1.0, 2.0, 1.0);
    _tmpMat.multiply(position3d.renderTransform);
    _tmpMat.setTranslationRaw(0, 0, 0);

    _uniforms[Voxel3dUniform.dstSize] = Vector2.all(_renderSize.toDouble());
    _uniforms[Voxel3dUniform.lightDirection] = position3d.lightDirection;
    _uniforms[Voxel3dUniform.modelMatrixInverse] = _tmpMat;

    _shader.setImageSampler(0, _exhaustBuffer ?? _voxelImage);
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
