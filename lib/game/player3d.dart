import 'dart:ui' as ui;

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart'; // Import for Colors
import 'package:stardash/game/has_position_3d.dart'; // Import HasPosition3D
import 'package:stardash/game/position3d.dart'; // Import Position3D
import 'package:stardash/game/shared/has_context.dart';

// --- Enums can be removed if not used by this simplified version ---
// enum Voxel3dUniform { ... }
// enum ExhaustUniform { ... }

class Player3D extends PositionComponent with HasPosition3D, HasContext, HasPaint {
  double _time = 0.0;

  // --- Remove shader/image fields ---
  // late ui.Image _voxelImage;
  // ui.FragmentShader? _shader;
  // Uniforms<Voxel3dUniform>? _uniforms;
  // ui.FragmentShader? _exhaustShader;
  // Uniforms<ExhaustUniform>? _exhaustUniforms;
  // ui.Image? _exhaustOutputImage;
  // late final ui.Paint _exhaustPaint = ui.Paint();
  // late int _frames;
  // final Float32List _matrixData = Float32List(16);
  // final Matrix4 _modelMatrixInverse = Matrix4.identity();
  // final Vector3 _lightDirection = Vector3(0.577, 0.577, -0.577)..normalize();
  // --- End removal ---

  // Store initial scale/rotation for position3d
  final Vector3 _initialScale = Vector3(0.7, 0.25, 0.7);
  final Vector3 _initialRotation = Vector3.zero();

  // Use a smaller base size for the 3D object representation
  final double _base3dSize = 20.0;

  Player3D() {
    // Remove anti-aliasing if desired for pixel look
    // paint.isAntiAlias = false;
    // paint.filterQuality = ui.FilterQuality.none;
  }

  @override
  Future<void> onLoad() async {
    logInfo('Loading Player');

    // Initialize HasPosition3D
    position3d = Position3D(
      position: Vector3.zero(), // Start at world origin
      size: Vector3.all(_base3dSize), // Define a base size for the 3D representation
      scale: _initialScale.clone(),
      rotation: _initialRotation.clone(),
    );

    // Set 2D size - this is now less important, mostly for Flame hit detection if needed
    // Could be derived from projected bounds later if necessary.
    // Setting a small fixed size for now.
    size.setAll(32); // Small placeholder 2D size
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Simple rotation for testing - Apply to position3d
    position3d.rotation.x = _time * 0.6;
    position3d.rotation.y = _time * 0.5;
    position3d.rotation.z = _time * 0.4;
  }

  // --- Simple Placeholder Render Method ---
  @override
  void render(ui.Canvas canvas) {
    // World3DComponent handles updating our 2D position based on 3D projection.
    // We just need to draw something simple at our current 2D position.

    logDebug('Rendering Player3D at position: ${position3d.position} priority: $priority');
    if (priority < 0) return; // Don't render if culled by 3D system

    // Draw a simple circle as a placeholder
    paint.color = Colors.blue; // Use a distinct color
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size.x / 2, paint); // Draw centered circle
  }

  // --- Remove shader helper methods ---
  // void _renderExhaustPass() { /* ... */ }
  // void _updateExhaustUniforms(ui.FragmentShader shader) { /* ... */ }
  // void _update_uniforms(...) { /* ... */ }

  @override
  void onRemove() {
    // Remove disposal of _exhaustOutputImage
    // _exhaustOutputImage?.dispose();
    super.onRemove();
  }
}

// --- Remove makeViewMatrix if not needed ---
// Matrix4 makeViewMatrix(...) { ... }
