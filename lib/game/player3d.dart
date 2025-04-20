import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/has_position_3d.dart';
import 'package:stardash/game/position3d.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/update2d.dart';
import 'package:stardash/util/uniforms.dart';

// Voxel3dUniform enum remains the same
enum Voxel3dUniform {
  dstOriginX,
  dstOriginY,
  dstSizeX,
  dstSizeY,
  srcOriginX,
  srcOriginY,
  atlasSizeX,
  atlasSizeY,
  frames,
  frameX,
  frameY,
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
  lightX,
  lightY,
  lightZ,
  renderMode,
}

// ExhaustUniform enum remains the same
enum ExhaustUniform {
  resolutionX,
  resolutionY,
  time,
  targetColorR,
  targetColorG,
  targetColorB,
  targetColorA,
  colorVariance,
  exhaustLength,
  color0R,
  color0G,
  color0B,
  color1R,
  color1G,
  color1B,
  color2R,
  color2G,
  color2B,
  color3R,
  color3G,
  color3B,
  color4R,
  color4G,
  color4B,
}

// Class definition order fixed: with before implements
class Player3D extends PositionComponent
    with
        HasUpdate2D,
        HasContext,
        HasPaint // with first
    implements
        HasPosition3D {
  // implements second

  // Need to explicitly declare position3d due to implements
  @override
  late final Position3D position3d;

  double _time = 0.0;

  late ui.Image _voxelImage;

  ui.FragmentShader? _shader;
  Uniforms<Voxel3dUniform>? _uniforms;

  ui.FragmentShader? _exhaustShader;
  Uniforms<ExhaustUniform>? _exhaustUniforms;
  ui.Image? _exhaustOutputImage;
  late final ui.Paint _exhaustPaint = ui.Paint();

  late int _frames;

  // Remove local transforms, use position3d instead
  // final Vector3 _scale = Vector3(0.7, 0.25, 0.7);
  // final Vector3 _rotation = Vector3.zero();
  final Vector3 _initialScale = Vector3(0.7, 0.25, 0.7); // Keep for initialization
  final Matrix4 _modelMatrixInverse = Matrix4.identity(); // Needed for shader
  final Vector3 _lightDirection = Vector3(0.577, 0.577, -0.577)..normalize(); // Keep shader light
  final Float32List _matrixData = Float32List(16); // Keep for uniform update

  // Added: Base size for 3D object representation
  final double _base3dSize = 20.0;

  Player3D() {
    // Renamed constructor
    paint.isAntiAlias = false;
    paint.filterQuality = ui.FilterQuality.none;
    _exhaustPaint.isAntiAlias = false;
    _exhaustPaint.filterQuality = ui.FilterQuality.none;
  }

  @override
  Future<void> onLoad() async {
    logInfo('Loading Player3D'); // Updated log
    logInfo('Loading Player3D'); // Updated log
    logInfo('Loading Player3D'); // Updated log
    try {
      _voxelImage = await game.images.load('interstellar_15.png');
    } catch (e) {
      logError('Error loading voxel image: $e');
      return;
    }
    _frames = 15; // Match interstellar_15

    // --- Initialize Position3D ---
    position3d = Position3D(
      position: Vector3.zero(), // Start at world origin
      size: Vector3.all(_base3dSize), // Define a base size
      scale: _initialScale.clone(), // Use initial scale
      rotation: Vector3.zero(), // Start with no rotation
    );
    // Define local vertices needed for the mixin's size calculation
    const double half = 10.0; // Based on _base3dSize / 2
    position3d.localVertices = [
      Vector3(-half, -half, -half),
      Vector3(half, -half, -half),
      Vector3(half, half, -half),
      Vector3(-half, half, -half),
      Vector3(-half, -half, half),
      Vector3(half, -half, half),
      Vector3(half, half, half),
      Vector3(-half, half, half),
    ];
    // --- End Position3D Init ---

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

    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt); // Let mixins run first (Updates2DFrom3D sets position/size)
    _time += dt;

    // Update 3D rotation using position3d
    position3d.rotation.x = _time * 0.6;
    position3d.rotation.y = _time * 0.5;
    position3d.rotation.z = _time * 0.4;
    // Scale could also be updated here if needed: position3d.scale.setValues(...)
  }

  @override
  void render(ui.Canvas canvas) {
    // Check priority set by 3D system
    if (priority < 0) {
      logDebug("Player3D render skipped due to priority < 0");
      return;
    }

    if (_shader == null || _uniforms == null || _exhaustShader == null || _exhaustUniforms == null) {
      logDebug("Player3D render skipped due to shader initialization failure");
      return;
    }

    // --- Pass 1: Render Exhaust Effect to Intermediate Image ---
    // _renderExhaustPass(); // Keep exhaust logic

    // --- Pass 2: Render Voxel Model using Exhaust Output ---
    // The component's position and size are set by the Updates2DFrom3D mixin
    // The canvas origin is already translated to component.position by Flame
    // We draw the shader rect covering the component's size (updated by mixin)
    if (_exhaustOutputImage != null) {
      _update_uniforms(_shader!, inputImage: _exhaustOutputImage!);
      _shader!.setImageSampler(0, _exhaustOutputImage!); // Use the exhaust output image
      paint.shader = _shader;
      canvas.drawRect(size.toRect(), paint);
    } else {
      // logDebug("shade size: $size");
      // Fallback or initial frame: render directly from original atlas
      _update_uniforms(_shader!, inputImage: _voxelImage);
      _shader!.setImageSampler(0, _voxelImage);
      paint.shader = _shader;
      // size.setAll(100);
      // paint.style = ui.PaintingStyle.fill;
      // paint.color = const ui.Color(0x8000FF00); // Fallback color
      canvas.drawRect(size.toRect(), paint);
    }

    // Draw a BLUE CIRCLE:
    // canvas.drawCircle(
    //   ui.Offset(0, 0),
    //   size.x / 2,
    //   ui.Paint()
    //     ..color = const ui.Color(0x40FFFFFF)
    //     ..style = ui.PaintingStyle.fill,
    // );

    // logDebug("Player3D 2D position: ${position.x}, ${position.y}"); // Log the 2D position
  }

  // Exhaust Pass Rendering - unchanged
  void _renderExhaustPass() {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    _updateExhaustUniforms(_exhaustShader!);
    _exhaustShader!.setImageSampler(0, _voxelImage);
    final targetRect = ui.Rect.fromLTWH(0, 0, _voxelImage.width.toDouble(), _voxelImage.height.toDouble());
    _exhaustPaint.shader = _exhaustShader;
    canvas.drawRect(targetRect, _exhaustPaint);
    final picture = recorder.endRecording();
    _exhaustOutputImage?.dispose();
    _exhaustOutputImage = picture.toImageSync(_voxelImage.width, _voxelImage.height);
    picture.dispose();
  }

  // Update Exhaust Shader Uniforms - unchanged
  void _updateExhaustUniforms(ui.FragmentShader shader) {
    // ... unchanged logic ...
    final uniforms = _exhaustUniforms!;
    uniforms.switch_shader(shader);
    final imageSize = Vector2(_voxelImage.width.toDouble(), _voxelImage.height.toDouble());
    uniforms.set(ExhaustUniform.resolutionX, imageSize.x);
    uniforms.set(ExhaustUniform.resolutionY, imageSize.y);
    uniforms.set(ExhaustUniform.time, _time);
    uniforms.set(ExhaustUniform.targetColorR, 1.0); // Red target
    uniforms.set(ExhaustUniform.targetColorG, 0.2);
    uniforms.set(ExhaustUniform.targetColorB, 0.0);
    uniforms.set(ExhaustUniform.targetColorA, 1.0);
    uniforms.set(ExhaustUniform.colorVariance, 0.1);
    uniforms.set(ExhaustUniform.exhaustLength, 8.0);
    // Flame colors
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

  // Modified to use position3d.worldTransform for matrix calculation
  void _update_uniforms(ui.FragmentShader shader, {required ui.Image inputImage}) {
    // --- START: Matrix Calculation ---
    // 1. Get the world transform calculated by World3d system
    final Matrix4 finalMatrix = position3d.worldTransform;

    // 2. Calculate the INVERSE for the shader
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
    // Use component's size (updated by mixin) for dstSize
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
    // Set the matrix uniform
    for (int i = 0; i < 16; i++) {
      uniforms.set(Voxel3dUniform.values[Voxel3dUniform.mat0.index + i], _matrixData[i].toDouble());
    }
    uniforms.set(Voxel3dUniform.renderMode, 0.0);
  }

  @override
  void onRemove() {
    _exhaustOutputImage?.dispose();
    super.onRemove();
  }
}

// Remove makeViewMatrix helper - no longer needed here
// Matrix4 makeViewMatrix(...) { ... }
