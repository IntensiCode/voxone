import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:stardash/game/position_component_3d.dart'; // Use correct package name

class Cube3D extends PositionComponent3D {
  final double _rotationSpeed = pi / 8; // 90 degrees per second around Z
  final double _pulseSpeed = pi; // One full pulse cycle every 2 seconds
  final double _minScale = 0.9;
  final double _maxScale = 1.1;

  double _time = 0.0;

  Cube3D({required Vector3 initialPosition}) : super(initialPosition) {
    // Cube spans from -10 to +10 on each axis (size 20)
    const double half = 10.0;

    // Define its vertices relative to position3D (center)
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
    if (priority < 0) return;

    // Render wireframe by connecting projected vertices
    for (final edge in _edges) {
      final p1 = projectedVertices[edge[0]];
      final p2 = projectedVertices[edge[1]];
      canvas.drawLine(p1.toOffset(), p2.toOffset(), _paint);
    }
  }

  @override
  void update(double dt) {
    _time += dt;

    rotation.z = (_time * _rotationSpeed) % (2 * pi);

    var delta = (_maxScale - _minScale);
    var variance = 0.5 * (1 + sin(_time * _pulseSpeed));
    final scale = _minScale + delta * variance; // Pulse effect
    scale3D.setValues(scale, scale, scale);

    super.update(dt);
  }
}
