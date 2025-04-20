import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui; // Ensure you have this import alias

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:stardash/game/has_lighted_faces.dart';
import 'package:stardash/game/has_position_3d.dart';
import 'package:stardash/game/position3d.dart';
import 'package:stardash/game/update2d.dart';
import 'package:stardash/util/mutable.dart';

class Cube3D extends PositionComponent with HasVisibility, HasPosition3D, HasLightedFaces, HasUpdate2D {
  static const double _rotationSpeed = pi / 8; // 90 degrees per second around Z
  static const double _pulseSpeed = pi * 4; // One full pulse cycle every 2 seconds
  static const double _minScale = 1.0;
  static const double _maxScale = 1.0;

  double _time = 0.0;

  Cube3D({required Vector3 initialPosition}) {
    anchor = Anchor.center;

    position3d = Position3D(position: initialPosition);

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
    positions = Float32List(localFaces.length * 3 * 2);
    colors = Int32List(localFaces.length * 3);

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

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;

    // position3d.rotation.x = (_time * _rotationSpeed * 1.0) % (2 * pi);
    // position3d.rotation.y = (_time * _rotationSpeed * 2.2) % (2 * pi);
    // position3d.rotation.z = (_time * _rotationSpeed * 3.4) % (2 * pi);

    var delta = (_maxScale - _minScale);
    var variance = 0.5 * (1 + sin(_time * _pulseSpeed));
    final scale = _minScale + delta * variance; // Pulse effect
    // position3d.scale.setValues(scale, scale, scale);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    assert(priority != HasPosition3D.INVISIBILITY_PRIORITY);
    assert(position3d.projectedVertices.length == 8);
    assert(localFaces.length == 12);
    assert(faceLightIntensities.length == 12);

    // logInfo('Cube3D.render: ${position3d.projectedOrigin.y}');

    // \_('')_/
    canvas.translate(size.x / 2, size.y / 2);
    _renderFaces(canvas);
    canvas.translate(-size.x / 2, -size.y / 2);
  }

  void _renderFaces(ui.Canvas canvas) {
    final projected = position3d.projectedVertices;
    if (projected.isEmpty) return;

    int vertexIndex = 0; // Tracks current position in the lists

    for (int i = 0; i < localFaces.length; i++) {
      final faceIndices = localFaces[i];
      final intensity = faceLightIntensities[i];

      final v0 = projected[faceIndices[0]];
      final v1 = projected[faceIndices[1]];
      final v2 = projected[faceIndices[2]];

      // Simple backface culling
      if ((v1.x - v0.x) * (v2.y - v0.y) - (v1.y - v0.y) * (v2.x - v0.x) < 0) {
        continue; // Skip this face
      }

      // Calculate face color
      _mutableFaceColor.setLerpKeepAlpha(_baseColor, Colors.black, 1.0 - intensity, 255);

      // Add positions (x, y for v0, v1, v2)
      final int posBaseIndex = vertexIndex * 2;
      positions[posBaseIndex] = v0.x;
      positions[posBaseIndex + 1] = v0.y;
      positions[posBaseIndex + 2] = v1.x;
      positions[posBaseIndex + 3] = v1.y;
      positions[posBaseIndex + 4] = v2.x;
      positions[posBaseIndex + 5] = v2.y;

      final int colorValue = _mutableFaceColor.toARGB32();

      // Add colors (same color for all 3 vertices of the triangle)
      final int colorBaseIndex = vertexIndex;
      colors[colorBaseIndex] = colorValue;
      colors[colorBaseIndex + 1] = colorValue;
      colors[colorBaseIndex + 2] = colorValue;

      vertexIndex += 3; // Move to the next triangle's vertices
    }

    // Only draw if we added any vertices
    if (vertexIndex > 0) {
      // Create Vertices object - Use sublists if not all faces were drawn
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        // Use sublist view to only include added vertices
        Float32List.sublistView(positions, 0, vertexIndex * 2),
        colors: Int32List.sublistView(colors, 0, vertexIndex),
        // No indices needed as positions are already ordered per triangle
      );

      // Draw all triangles in one call
      // The paint's style, blend mode etc. are still used,
      // but vertex colors override paint.color
      canvas.drawVertices(vertices, ui.BlendMode.srcOver, _facePaint);
    }
  }

  static final _baseColor = Colors.green;
  static final _facePaint = ui.Paint();
  static final _mutableFaceColor = MutableColor(0, 0, 0, 0);
}
