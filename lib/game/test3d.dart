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

// Class definition order fixed: with before implements
class Test3D extends PositionComponent
    with HasVisibility, HasPosition3D, HasUpdate2D, HasContext, HasPaint {
  double _time = 0.0;

  late ui.Image _voxelImage;

  ui.FragmentShader? _shader;
  UniformsExt<Voxel3dUniform>? _uniforms;

  ui.FragmentShader? _exhaustShader;
  UniformsExt<ExhaustUniform>? _exhaustUniforms;
  ui.Image? _exhaustOutputImage;
  late final ui.Paint _exhaustPaint = ui.Paint();

  late int _frames;

  // Remove local transforms, use position3d instead
  // final Vector3 _scale = Vector3(0.7, 0.25, 0.7);
  // final Vector3 _rotation = Vector3.zero();
  final Vector3 _initialScale =
      Vector3(0.7, 0.25, 0.7); // Keep for initialization
  final Matrix4 _modelMatrixInverse = Matrix4.identity(); // Needed for shader
  final Vector3 _lightDirection = Vector3(0.577, 0.577, -0.577)
    ..normalize(); // Keep shader light
  final Float32List _matrixData = Float32List(16); // Keep for uniform update

  // Added: Base size for 3D object representation
  final double _base3dSize = 20.0;

  Test3D() {
    // Renamed constructor
    paint.isAntiAlias = false;
    paint.filterQuality = ui.FilterQuality.none;
    _exhaustPaint.isAntiAlias = false;
    _exhaustPaint.filterQuality = ui.FilterQuality.none;
  }

  @override
  Future<void> onLoad() async {
    logInfo('Loading Test3D'); // Updated log
    try {
      _voxelImage = await game.images.load('interstellar_15.png');
    } catch (e) {
      logError('Error loading voxel image: $e');
      return;
    }
    _frames = 15; // Match interstellar_15

    // --- Initialize Position3D ---
    position3d = Position3D(
      position: Vector3(0, 0, 0),
      scale: _initialScale.clone(), // Use initial scale
      rotation: Vector3.zero(), // Start with no rotation
    );

    // Define local vertices needed for the mixin's size calculation
    const double half = 10.0; // Based on _base3dSize / 2
    const double quarter = 5.0; // Based on _base3dSize / 4
    position3d.localVertices = [
      Vector3(-half, -quarter, -half),
      Vector3(half, -quarter, -half),
      Vector3(half, quarter, -half),
      Vector3(-half, quarter, -half),
      Vector3(-half, -quarter, half),
      Vector3(half, -quarter, half),
      Vector3(half, quarter, half),
      Vector3(-half, quarter, half),
    ];
    // --- End Position3D Init ---

    try {
      final program =
          await ui.FragmentProgram.fromAsset('assets/shaders/voxel3d.frag');
      _shader = program.fragmentShader();
      _uniforms = UniformsExt<Voxel3dUniform>(_shader!, {
        for (final v in Voxel3dUniform.values) v: v.type,
      });
    } catch (e) {
      logError('Error loading voxel3d shader: $e');
    }

    try {
      final exhaustProgram =
          await ui.FragmentProgram.fromAsset('assets/shaders/exhaust.frag');
      _exhaustShader = exhaustProgram.fragmentShader();
      _exhaustUniforms = UniformsExt<ExhaustUniform>(_exhaustShader!, {
        for (final v in ExhaustUniform.values) v: v.type,
      });
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
    super.update(
        dt); // Let mixins run first (Updates2DFrom3D sets position/size)
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
      logDebug("Test3D render skipped due to priority < 0");
      return;
    }

    if (_shader == null ||
        _uniforms == null ||
        _exhaustShader == null ||
        _exhaustUniforms == null) {
      logDebug("Test3D render skipped due to shader initialization failure");
      return;
    }

    // --- Pass 1: Render Exhaust Effect to Intermediate Image ---
    // _renderExhaustPass(); // Keep exhaust logic

    // --- Pass 2: Render Voxel Model using Exhaust Output ---
    // The component's position and size are set by the Updates2DFrom3D mixin
    // The canvas origin is already translated to component.position by Flame
    // We draw the shader rect covering the component's size (updated by mixin)
    if (_exhaustOutputImage != null) {
      _update_uniforms(inputImage: _exhaustOutputImage!);
      _shader!.setImageSampler(
          0, _exhaustOutputImage!); // Use the exhaust output image
      paint.shader = _shader;
      canvas.drawRect(size.toRect(), paint);
    } else {
      // logDebug("shade size: $size");
      // Fallback or initial frame: render directly from original atlas
      _update_uniforms(inputImage: _voxelImage);
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

    // logDebug("Test3D 2D position: ${position.x}, ${position.y}"); // Log the 2D position
  }

  // Exhaust Pass Rendering - unchanged
  void _renderExhaustPass() {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    _updateExhaustUniforms();
    _exhaustShader!.setImageSampler(0, _voxelImage);
    final targetRect = ui.Rect.fromLTWH(
        0, 0, _voxelImage.width.toDouble(), _voxelImage.height.toDouble());
    _exhaustPaint.shader = _exhaustShader;
    canvas.drawRect(targetRect, _exhaustPaint);
    final picture = recorder.endRecording();
    _exhaustOutputImage?.dispose();
    _exhaustOutputImage =
        picture.toImageSync(_voxelImage.width, _voxelImage.height);
    picture.dispose();
  }

  // Update Exhaust Shader Uniforms - changed to use UniformsExt with compound types
  void _updateExhaustUniforms() {
    final uniforms = _exhaustUniforms!;
    final imageSize =
        Vector2(_voxelImage.width.toDouble(), _voxelImage.height.toDouble());
    uniforms[ExhaustUniform.resolution] = imageSize;
    uniforms[ExhaustUniform.time] = _time;
    uniforms[ExhaustUniform.targetColor] =
        Vector4(1.0, 0.2, 0.0, 1.0); // Red target
    uniforms[ExhaustUniform.colorVariance] = 0.1;
    uniforms[ExhaustUniform.exhaustLength] = 8.0;
    // Flame colors
    uniforms[ExhaustUniform.color0] = Vector3(1.0, 0.0, 0.0);
    uniforms[ExhaustUniform.color1] = Vector3(1.0, 1.0, 0.0);
    uniforms[ExhaustUniform.color2] = Vector3(1.0, 0.0, 0.0);
    uniforms[ExhaustUniform.color3] = Vector3(0.5, 0.0, 0.0);
    uniforms[ExhaustUniform.color4] = Vector3(0.5, 0.0, 0.0);
  }

  // Modified to use position3d.worldTransform for matrix calculation and UniformsExt with compound types
  void _update_uniforms({required ui.Image inputImage}) {
    // --- START: Matrix Calculation ---
    // 1. Get the world transform calculated by World3d system
    final Matrix4 finalMatrix = position3d.worldTransform;

    // 2. Calculate the INVERSE for the shader
    _modelMatrixInverse.copyInverse(finalMatrix);
    _modelMatrixInverse.copyIntoArray(_matrixData);
    // --- END: Matrix Calculation ---

    final uniforms = _uniforms!;

    // --- Set Uniforms (uses _matrixData calculated above) ---
    final frameSizeVec = Vector2(
        inputImage.width.toDouble(), inputImage.height.toDouble() / _frames);
    final atlasSizeVec =
        Vector2(inputImage.width.toDouble(), inputImage.height.toDouble());
    final srcOriginVec = Vector2.zero();
    final dstOriginVec = Vector2.zero();
    // Use component's size (updated by mixin) for dstSize
    final dstSizeVec = size;

    uniforms[Voxel3dUniform.dstOrigin] = dstOriginVec;
    uniforms[Voxel3dUniform.dstSize] = dstSizeVec;
    uniforms[Voxel3dUniform.srcOrigin] = srcOriginVec;
    uniforms[Voxel3dUniform.atlasSize] = atlasSizeVec;
    uniforms[Voxel3dUniform.frameSize] = frameSizeVec;
    uniforms[Voxel3dUniform.frames] = _frames.toDouble();
    uniforms[Voxel3dUniform.lightDirection] = _lightDirection;
    // Set the matrix uniform
    uniforms[Voxel3dUniform.modelMatrixInverse] = _modelMatrixInverse;
    uniforms[Voxel3dUniform.renderMode] = 0.0;
  }

  @override
  void onRemove() {
    _exhaustOutputImage?.dispose();
    super.onRemove();
  }
}

// Remove makeViewMatrix helper - no longer needed here
// Matrix4 makeViewMatrix(...) { ... }

// Voxel3dUniform enum updated for compound types and type storage
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

  const Voxel3dUniform(this.type);
  final Type type;
}

// ExhaustUniform enum updated for compound types and type storage
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

  const ExhaustUniform(this.type);
  final Type type;
}
