import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/game.dart'; // Required for Vector2
import 'package:vector_math/vector_math_64.dart';

class Camera3D {
  final Vector2 screenSize;

  final double fieldOfView = 60.0; // Degrees
  final double aspectRatio;
  final double nearPlane = 0.1;
  final double farPlane = 1000.0;

  final Vector3 position = Vector3.zero();
  final Vector3 target = Vector3(0, 0, -1); // Looking down negative Z
  final Vector3 up = Vector3(0, 1, 0); // Standard Y-up

  final Matrix4 viewMatrix = Matrix4.identity();
  final Matrix4 projectionMatrix = Matrix4.identity();
  final Matrix4 viewProjectionMatrix = Matrix4.identity();

  // DON'T ALLOCATE OBJECTS! USE REUSABLE OBJECTS!

  Camera3D({
    required this.screenSize,
    required Vector3? initialPosition,
    required Vector3? initialTarget,
  }) : aspectRatio = screenSize.x / screenSize.y {
    if (initialPosition != null) position.setFrom(initialPosition);
    if (initialTarget != null) target.setFrom(initialTarget);
    _updateMatrices();
  }

  void lookAt(Vector3 newTarget) {
    target.setFrom(newTarget);
    _updateMatrices();
  }

  void moveTo(Vector3 newPosition) {
    position.setFrom(newPosition);
    _updateMatrices();
  }

  void _updateMatrices() {
    // View Matrix: Transforms world space to camera space
    setViewMatrix(viewMatrix, position, target, up);

    // Projection Matrix: Transforms camera space to clip space
    setPerspectiveMatrix(
      projectionMatrix,
      radians(fieldOfView),
      aspectRatio,
      nearPlane,
      farPlane,
    );
    viewProjectionMatrix.setFrom(projectionMatrix);
    viewProjectionMatrix.multiply(viewMatrix);
  }

  final Vector4 _point4 = Vector4.zero();
  final Vector4 _clipPoint = Vector4.zero();
  final Vector3 _ndc = Vector3.zero();

  // Projects a 3D world point to normalized device coordinates (NDC) [-1, 1]
  // Returns null if the point is behind the camera's near plane (or very close)
  Vector3? projectWorldToNdc(Vector3 worldPoint) {
    _point4.setValues(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
    viewProjectionMatrix.transformed(_point4, _clipPoint);

    // Check W first
    if (_clipPoint.w.abs() < 0.0001) {
      logDebug('Camera3D: Point rejected due to near-zero W: ${_clipPoint.w}');
      return null;
    }

    // --- Modified Frustum Clipping Check (in Clip Space) ---
    final w = _clipPoint.w;
    const double xyTolerance = 2.0; // Allow x/y to be up to 2*w

    // Z check remains strict (Near/Far planes)
    if (_clipPoint.z.abs() > w) {
      // logDebug('Camera3D: Point rejected by Z frustum check. ClipZ: ${_clipPoint.z}, W: $w');
      return null;
    }

    // X/Y check allows some tolerance (Left/Right/Top/Bottom planes)
    if (_clipPoint.x.abs() > w * xyTolerance || _clipPoint.y.abs() > w * xyTolerance) {
       // logDebug('Camera3D: Point rejected by relaxed X/Y frustum check. ClipX: ${_clipPoint.x}, ClipY: ${_clipPoint.y}, W: $w');
       return null; // Point is too far outside the X/Y view
    }
    // --- End Frustum Check ---

    // Perspective division to get NDC
    _ndc.setFrom4(_clipPoint);
    _ndc.scale(1.0 / w);

    return _ndc;
  }

  // Screen coordinates for the projected point as reused object to avoid allocations
  final Vector2 _result = Vector2.zero();

  // Converts NDC [-1, 1] to screen coordinates [0, screenSize]
  Vector2 ndcToScreen(Vector3 ndc) {
    // Convert NDC Y from math standard (+Y up) to screen standard (+Y down)
    final screenX = (ndc.x + 1.0) * 0.5 * screenSize.x;
    final screenY = (1.0 - ndc.y) * 0.5 * screenSize.y; // Invert Y
    _result.setValues(screenX, screenY);
    logDebug('Camera3D: NDC to screen: $ndc -> $_result');
    return _result;
  }

  // Helper to map Z depth (typically in view space or NDC Z) to Flame priority
  // Closer objects (larger Z in view space, smaller neg Z, closer to 1 in NDC) get higher priority.
  // This needs careful tuning based on expected Z range.
  static int depthToPriority(double ndcDepth) {
    // Normalize NDC z [-1 (near), 1 (far)] to [0, 1]
    final double normalizedDepth = (ndcDepth.clamp(-1.0, 1.0) + 1.0) * 0.5;
    // Invert so near is 1, far is 0
    final double invertedDepth = 1.0 - normalizedDepth;
    // Scale to integer range (higher value = higher priority = rendered last)
    return (invertedDepth * 1000000).toInt();
  }
}

extension on Vector3 {
  void setFrom4(Vector4 other) {
    x = other.x;
    y = other.y;
    z = other.z;
  }
}
