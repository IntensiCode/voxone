import 'package:flame/game.dart'; // Required for Vector2

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

    // Combined matrix (more efficient)
    viewProjectionMatrix.setFrom(projectionMatrix * viewMatrix);
  }

  // Reusable input point for projection
  final Vector4 _point4 = Vector4.zero();

  // Reusable output NDC vector
  final Vector3 _ndc = Vector3.zero();

  // Projects a 3D world point to normalized device coordinates (NDC) [-1, 1]
  // Returns null if the point is behind the camera's near plane (or very close)
  Vector3? projectWorldToNdc(Vector3 worldPoint) {
    _point4.setValues(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
    final clipPoint = viewProjectionMatrix.transform(_point4);

    // Perspective division
    if (clipPoint.w.abs() < 0.0001) {
      return null; // Avoid division by zero/very small numbers
    }

    _ndc.setValues(
      clipPoint.x / clipPoint.w,
      clipPoint.y / clipPoint.w,
      clipPoint.z / clipPoint.w,
    );

    // Basic clipping check (z is enough for near plane)
    // Note: Full frustum clipping involves checking x and y against w as well.
    if (_ndc.z < -1.0) {
      // Behind near plane in NDC
      return null;
    }

    // Optional: Far plane clipping (if needed)
    // if (ndc.z > 1.0) { // Beyond far plane in NDC
    //    return null;
    // }

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
