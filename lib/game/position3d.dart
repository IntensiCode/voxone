import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:stardash/util/mutable.dart';
import 'package:vector_math/vector_math_64.dart';

class Position3D {
  final Vector3 position;
  final Vector3 scale; // = Vector3.all(1.0);
  final Vector3 rotation; // = Vector3.zero(); // Euler angles (X, Y, Z)

  // Local transform relative to parent (if any) or world origin
  final Matrix4 transform = Matrix4.identity();

  // Transform passed to component's rendering (may include camera view)
  final Matrix4 renderTransform = Matrix4.identity();

  // Flag indicating if renderTransform should include camera view
  bool needsFullTransform = false;

  // Depth of the projected origin in Normalized Device Coordinates [-1, 1] (calculated by World3d)
  double ndcDepth = 0.0;

  // W component of the projected origin in Clip Space (calculated by World3d)
  double clipW = 1.0;

  // Vertices defined relative to this position
  List<Vector3> localVertices = [];

  // Projected screen coord of origin
  final Vector2 projectedOrigin = Vector2.zero();

  // Projected 2D screen coordinates corresponding world vertices
  List<Vector2> projectedVertices = [];

  Position3D({
    required this.position,
    Vector3? scale,
    Vector3? rotation,
  })  : scale = scale ?? Vector3.all(1.0),
        rotation = rotation ?? Vector3.zero();

  final _o1 = MutableOffset(0, 0);
  final _o2 = MutableOffset(0, 0);
  final _pair = MutablePair<Offset, Offset>(Offset.zero, Offset.zero);

  MutablePair<Offset, Offset>? projectedEdge(int a, int b) {
    if (a >= projectedVertices.length) {
      logDebug('projectedEdge: a out of range: $a > ${projectedVertices.length}');
      return null;
    }
    if (b >= projectedVertices.length) {
      logDebug('projectedEdge: b out of range: $b > ${projectedVertices.length}');
      return null;
    }
    final p1 = projectedVertices[a];
    final p2 = projectedVertices[b];
    _o1.setFrom(p1);
    _o2.setFrom(p2);
    _pair.setFrom(_o1, _o2);
    return _pair;
  }
}
