import 'dart:math';
import 'package:flutter/material.dart';

import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/has_lighted_faces.dart';
import 'package:stardash/game/has_position_3d.dart';
import 'package:stardash/game/position3d.dart';

class Cube3D extends PositionComponent with HasPosition3D, HasLightedFaces {
  final double _rotationSpeed = pi / 8; // 90 degrees per second around Z
  final double _pulseSpeed = pi; // One full pulse cycle every 2 seconds
  final double _minScale = 0.9;
  final double _maxScale = 1.1;

  double _time = 0.0;

  Cube3D({required Vector3 initialPosition}) {
    position3d = Position3D(position: initialPosition, size: Vector3.all(20));

    // Cube spans from -10 to +10 on each axis (size 20)
    const double half = 10.0;

    // Define its vertices relative to position3D (center)
    final lv = position3d.localVertices = [
      Vector3(-half, -half, -half), // 0: bottom-left-near
      Vector3(half, -half, -half), // 1: bottom-right-near
      Vector3(half, half, -half), // 2: top-right-near
      Vector3(-half, half, -half), // 3: top-left-near
      Vector3(-half, -half, half), // 4: bottom-left-far
      Vector3(half, -half, half), // 5: bottom-right-far
      Vector3(half, half, half), // 6: top-right-far
      Vector3(-half, half, half), // 7: top-left-far
    ];

    // Initialize HasLightedFaces part
    // Define faces as pairs of triangles (indices into localVertices)
    localFaces = [
      // Near face (Z = -half)
      [0, 1, 2], [0, 2, 3],
      // Far face (Z = half)
      [4, 7, 6], [4, 6, 5],
      // Left face (X = -half)
      [4, 0, 3], [4, 3, 7],
      // Right face (X = half)
      [1, 5, 6], [1, 6, 2],
      // Top face (Y = half)
      [3, 2, 6], [3, 6, 7],
      // Bottom face (Y = -half)
      [4, 5, 1], [4, 1, 0],
    ];

    // Calculate face normals (using localVertices from position3d)
    faceNormals = List.generate(localFaces.length, (_) => Vector3.zero());
    for (int i = 0; i < localFaces.length; i++) {
      final face = localFaces[i];
      final v0 = lv[face[0]];
      final v1 = lv[face[1]];
      final v2 = lv[face[2]];
      final normal = (v1 - v0).cross(v2 - v0);
      normal.normalize();
      faceNormals[i] = normal;
    }

    // Initialize light intensities (will be calculated by calculateLighting method)
    faceLightIntensities = List.filled(localFaces.length, 0.0);
  }

  static final _baseColor = Colors.red;
  static final _facePaint = pixel_paint()..style = PaintingStyle.fill;

  @override
  void render(Canvas canvas) {
    if (priority < 0) return;

    assert(position3d.projectedVertices.length == 8);
    assert(localFaces.length == 12);
    assert(faceLightIntensities.length == 12);

    _renderFaces(canvas);
  }

  void _renderFaces(Canvas canvas) {
    final path = Path();
    final projected = position3d.projectedVertices;
    for (int i = 0; i < localFaces.length; i++) {
      final faceIndices = localFaces[i];
      final intensity = faceLightIntensities[i];

      // Get projected vertices for the triangle
      final v0 = projected[faceIndices[0]];
      final v1 = projected[faceIndices[1]];
      final v2 = projected[faceIndices[2]];

      // Simple backface culling: Check winding order
      if ((v1.x - v0.x) * (v2.y - v0.y) - (v1.y - v0.y) * (v2.x - v0.x) < 0) {
        continue;
      }

      // Set paint color based on light intensity
      // TODO lerp allocates! do our own lerp!
      // TODO create a MutableColor in mutable.dart
      final Color faceColor =
          Color.lerp(_baseColor, Colors.black, 1.0 - intensity)!;
      _facePaint.color = faceColor;

      // Draw the triangle
      path.reset();
      path.moveTo(v0.x, v0.y);
      path.lineTo(v1.x, v1.y);
      path.lineTo(v2.x, v2.y);
      path.close();
      canvas.drawPath(path, _facePaint);
    }
  }

  @override
  void update(double dt) {
    _time += dt;

    position3d.rotation.z = (_time * _rotationSpeed) % (2 * pi);

    var delta = (_maxScale - _minScale);
    var variance = 0.5 * (1 + sin(_time * _pulseSpeed));
    final scale = 1.0; // _minScale + delta * variance; // Pulse effect
    position3d.scale.setValues(scale, scale, scale);

    super.update(dt);
  }
}
