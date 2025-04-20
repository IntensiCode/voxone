import 'dart:math';
import 'dart:ui';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/game/position_component_3d.dart'; // Use correct package name

class Cube3D extends PositionComponent3D {
  // Define its vertices relative to position3D (center)
  // Cube spans from -10 to +10 on each axis (size 20)
  // double _time = 0.0; // No longer needed for rotation test
  final double _rotationSpeed = pi / 8; // 90 degrees per second around Z
  final double _pulseSpeed = pi; // One full pulse cycle every 2 seconds
  final double _minScale = 0.9;
  final double _maxScale = 1.1;

  Cube3D({required Vector3 initialPosition}) : super(initialPosition) {
    const double half = 10.0;
    localVertices = [
      Vector3(-half, -half, -half), // 0: bottom-left-near
      Vector3(half, -half, -half), // 1: bottom-right-near
      Vector3(half, half, -half), // 2: top-right-near
      Vector3(-half, half, -half), // 3: top-left-near
      Vector3(-half, -half, half), // 4: bottom-left-far
      Vector3(half, -half, half), // 5: bottom-right-far
      Vector3(half, half, half), // 6: top-right-far
      Vector3(-half, half, half), // 7: top-left-far
    ];
  }

  static final _paint = Paint()
    ..color = const Color(0xFFFF0000)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  // Indices defining the 12 edges of the cube
  static const List<List<int>> _edges = [
    [0, 1], [1, 2], [2, 3], [3, 0], // Near face
    [4, 5], [5, 6], [6, 7], [7, 4], // Far face
    [0, 4], [1, 5], [2, 6], [3, 7] // Connecting edges
  ];

  @override
  void render(Canvas canvas) {
    // Render wireframe by connecting projected vertices
    for (final edge in _edges) {
      final Vector2? p1 = projectedVertices[edge[0]];
      final Vector2? p2 = projectedVertices[edge[1]];

      // Only draw if both points are projected (not null/clipped)
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1.toOffset(), p2.toOffset(), _paint);
      }
    }
  }

  @override
  void update(double dt) {
    // _time += dt;

    // Simple incremental rotation - avoids using accumulated _time
    final double rotationAmount = _rotationSpeed * dt;
    rotation.z += rotationAmount;
    // Optional: Wrap rotation.z if needed, though often not necessary for matrix functions
    // rotation.z %= (2 * pi);

    // Keep scale disabled
    scale3D.setValues(1, 1, 1);

    // Log values before super.update
    logInfo('Cube3D update: dt=$dt, rotation.z=${rotation.z}, scale=1.0');

    super.update(dt);
  }
}
