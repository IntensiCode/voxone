import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/util/uniforms.dart';

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

// Uniforms for exhaust.frag
enum ExhaustUniform {
  // uResolution (vec2)
  resolutionX,
  resolutionY,
  // Time (float)
  time,
  // TargetColor (vec4)
  targetColorR,
  targetColorG,
  targetColorB,
  targetColorA,
  // ColorVariance (float)
  colorVariance,
  // ExhaustLength (float)
  exhaustLength,
  // Color0 (vec3)
  color0R,
  color0G,
  color0B,
  // Color1 (vec3)
  color1R,
  color1G,
  color1B,
  // Color2 (vec3)
  color2R,
  color2G,
  color2B,
  // Color3 (vec3)
  color3R,
  color3G,
  color3B,
  // Color4 (vec3)
  color4R,
  color4G,
  color4B,
}

class MantaComponent extends PositionComponent with HasContext, HasPaint {
  double _time = 0.0;

  late ui.Image _voxelImage; // Original atlas

  ui.FragmentShader? _shader; // Voxel shader
  Uniforms<Voxel3dUniform>? _uniforms; // Voxel uniforms

  ui.FragmentShader? _exhaustShader; // Exhaust shader
  Uniforms<ExhaustUniform>? _exhaustUniforms; // Exhaust uniforms
  ui.Image? _exhaustOutputImage; // Intermediate render target
  late final ui.Paint _exhaustPaint = ui.Paint(); // Paint for exhaust pass

  late int _frames;

  // Restore original scale
  final Vector3 _scale = Vector3(0.7, 0.25, 0.7);
  final Vector3 _rotation = Vector3.zero();
  final Matrix4 _modelMatrixInverse = Matrix4.identity();
  final Vector3 _lightDirection = Vector3(0.577, 0.577, -0.577)..normalize();
  final Float32List _matrixData = Float32List(16);

  MantaComponent() {
    paint.isAntiAlias = false;
    paint.filterQuality = ui.FilterQuality.none;
    _exhaustPaint.isAntiAlias = false;
    _exhaustPaint.filterQuality = ui.FilterQuality.none;
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
    _frames = 15; // Match interstellar_15

    try {
      final program = await ui.FragmentProgram.fromAsset('assets/shaders/voxel3d.frag');
      _shader = program.fragmentShader();
      _uniforms = Uniforms(_shader!, Voxel3dUniform.values);
    } catch (e) {
      logError('Error loading voxel3d shader: $e');
    }

    try {
      final exhaustProgram = await ui.FragmentProgram.fromAsset('assets/shaders/exhaust.frag');
      _exhaustShader = exhaustProgram.fragmentShader();
      _exhaustUniforms = Uniforms(_exhaustShader!, ExhaustUniform.values);
    } catch (e) {
      logError('Error loading exhaust shader: $e');
    }

    assert(_shader != null, 'Voxel Shader failed to load.');
    assert(_uniforms != null, 'Voxel Uniforms failed to initialize.');
    assert(_exhaustShader != null, 'Exhaust Shader failed to load.');
    assert(_exhaustUniforms != null, 'Exhaust Uniforms failed to initialize.');

    size.setAll(256);
    // position = game.size / 2;
    anchor = Anchor.topLeft;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    if (_shader == null || _uniforms == null || _exhaustShader == null || _exhaustUniforms == null) return;

    // --- Pass 1: Render Exhaust Effect to Intermediate Image ---
    _renderExhaustPass();

    // --- Pass 2: Render Voxel Model using Exhaust Output ---
    if (_exhaustOutputImage != null) {
      _update_uniforms(_shader!, useLightViewMatrix: false, inputImage: _exhaustOutputImage!);
      _shader!.setImageSampler(0, _exhaustOutputImage!); // Use the exhaust output image
      paint.shader = _shader;
      canvas.drawRect(size.toRect(), paint);
    } else {
      // Fallback or initial frame: render directly from original atlas
      _update_uniforms(_shader!, useLightViewMatrix: false, inputImage: _voxelImage);
      _shader!.setImageSampler(0, _voxelImage);
      paint.shader = _shader;
      canvas.drawRect(size.toRect(), paint);
    }
  }

  // --- Exhaust Pass Rendering ---
  void _renderExhaustPass() {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    _updateExhaustUniforms(_exhaustShader!);
    _exhaustShader!.setImageSampler(0, _voxelImage); // Use original atlas as input

    final targetRect = ui.Rect.fromLTWH(
      0,
      0,
      _voxelImage.width.toDouble(),
      _voxelImage.height.toDouble(),
    );
    _exhaustPaint.shader = _exhaustShader;
    canvas.drawRect(targetRect, _exhaustPaint);

    final picture = recorder.endRecording();
    // Dispose previous image if it exists
    _exhaustOutputImage?.dispose();
    _exhaustOutputImage = picture.toImageSync(_voxelImage.width, _voxelImage.height);
    picture.dispose();
  }

  // --- Update Exhaust Shader Uniforms ---
  void _updateExhaustUniforms(ui.FragmentShader shader) {
    final uniforms = _exhaustUniforms!;
    uniforms.switch_shader(shader);

    final imageSize = Vector2(_voxelImage.width.toDouble(), _voxelImage.height.toDouble());
    final exhaustLength = sin(_time) * 4.0;

    // Set resolution
    uniforms.set(ExhaustUniform.resolutionX, imageSize.x);
    uniforms.set(ExhaustUniform.resolutionY, imageSize.y);
    // Set time
    uniforms.set(ExhaustUniform.time, _time);
    // Set target color (Red)
    uniforms.set(ExhaustUniform.targetColorR, 1.0);
    uniforms.set(ExhaustUniform.targetColorG, 0.2);
    uniforms.set(ExhaustUniform.targetColorB, 0.0);
    uniforms.set(ExhaustUniform.targetColorA, 1.0);
    // Set variance
    uniforms.set(ExhaustUniform.colorVariance, 0.1);
    // Set exhaust length
    uniforms.set(ExhaustUniform.exhaustLength, 8.0);

    // Set flame colors (Red -> Orange -> Yellow -> Lighter Yellow -> White)
    uniforms.set(ExhaustUniform.color0R, 1.0);
    uniforms.set(ExhaustUniform.color0G, 0.0);
    uniforms.set(ExhaustUniform.color0B, 0.0);

    uniforms.set(ExhaustUniform.color1R, 1.0);
    uniforms.set(ExhaustUniform.color1G, 1.0);
    uniforms.set(ExhaustUniform.color1B, 0.0);

    uniforms.set(ExhaustUniform.color2R, 1.0);
    uniforms.set(ExhaustUniform.color2G, 0.0);
    uniforms.set(ExhaustUniform.color2B, 0.0);

    uniforms.set(ExhaustUniform.color3R, 0.5);
    uniforms.set(ExhaustUniform.color3G, 0.0);
    uniforms.set(ExhaustUniform.color3B, 0.0);

    uniforms.set(ExhaustUniform.color4R, 0.5);
    uniforms.set(ExhaustUniform.color4G, 0.0);
    uniforms.set(ExhaustUniform.color4B, 0.0);
  }

  // Modified to accept inputImage for size calculations
  void _update_uniforms(ui.FragmentShader shader, {required bool useLightViewMatrix, required ui.Image inputImage}) {
    // --- START: Matrix Calculation (Conditional) ---
    // 1. Calculate basic model transform (rotation * scale)
    _rotation.x = _time * 0.6;
    _rotation.y = _time * 0.5;
    _rotation.z = _time * 0.4;
    final scaleMatrix = Matrix4.identity()..scale(_scale);
    final rotX = Matrix4.rotationX(_rotation.x);
    final rotY = Matrix4.rotationY(_rotation.y);
    final rotZ = Matrix4.rotationZ(_rotation.z);
    final rotationMatrix = rotZ * rotY * rotX;
    final modelMatrix = rotationMatrix * scaleMatrix;

    // 2. Determine the final view matrix to use
    final Matrix4 finalMatrix;
    if (useLightViewMatrix) {
      // Calculate Light's View Matrix
      final lightPos = -_lightDirection.normalized() * 10.0; // Place light source far away
      final lookAt = Vector3.zero(); // Look at model origin
      final up = Vector3(0, 1, 0); // World up
      // Ensure 'up' is not parallel to 'lightPos - lookAt'
      if ((lightPos - lookAt).normalized().dot(up).abs() > 0.99) {
        // If light is looking nearly straight up/down, use world forward/right as 'up'
        up.setValues(1, 0, 0); // Or (0,0,1) depending on preference
      }
      final lightViewMatrix = makeViewMatrix(lightPos, lookAt, up);
      // Combine light view with model transform
      finalMatrix = lightViewMatrix * modelMatrix;
    } else {
      // Use Camera's View (assuming camera view matrix is identity)
      finalMatrix = modelMatrix;
    }

    // 3. Calculate the INVERSE of the final matrix for the shader
    _modelMatrixInverse.copyInverse(finalMatrix);
    _modelMatrixInverse.copyIntoArray(_matrixData);
    // --- END: Matrix Calculation ---

    final uniforms = _uniforms!;
    uniforms.switch_shader(shader);

    // --- Set Uniforms (uses _matrixData calculated above) ---
    final frameSizeVec = Vector2(inputImage.width.toDouble(), inputImage.height.toDouble() / _frames);
    final atlasSizeVec = Vector2(inputImage.width.toDouble(), inputImage.height.toDouble());
    final srcOriginVec = Vector2.zero();
    final dstOriginVec = Vector2.zero();
    final dstSizeVec = size;

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
    // Set the matrix uniform (mat0 - mat15)
    for (int i = 0; i < 16; i++) {
      uniforms.set(Voxel3dUniform.values[Voxel3dUniform.mat0.index + i], _matrixData[i].toDouble());
    }
    uniforms.set(Voxel3dUniform.renderMode, 0.0); // Assuming mode 0 for shadow render now
  }

  @override
  void onRemove() {
    _exhaustOutputImage?.dispose();
    // Shaders (_shader, _exhaustShader) are managed by FragmentProgram cache?
    super.onRemove();
  }
}
