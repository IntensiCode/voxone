import 'package:flame/game.dart'; // Required for Vector2
import 'package:stardash/core/common.dart';

class Camera3D {
  Vector3 position = Vector3.zero();
  Vector3 target = Vector3(0, 0, -1); // Looking down negative Z
  Vector3 up = Vector3(0, 1, 0); // Standard Y-up

  double fieldOfView = 60.0; // Degrees
  double aspectRatio = game_width / game_height; // Default aspect ratio
  double nearPlane = 0.1;
  double farPlane = 1000.0;

  final Matrix4 _viewMatrix = Matrix4.identity();
  final Matrix4 _projectionMatrix = Matrix4.identity();
  final Matrix4 _viewProjectionMatrix = Matrix4.identity();

  Matrix4 get viewMatrix => _viewMatrix;

  Matrix4 get projectionMatrix => _projectionMatrix;

  Matrix4 get viewProjectionMatrix => _viewProjectionMatrix;

  Camera3D({
    Vector3? initialPosition,
    Vector3? initialTarget,
  }) {
    if (initialPosition != null) position.setFrom(initialPosition);
    if (initialTarget != null) target.setFrom(initialTarget);
    // aspectRatio is now initialized based on common.dart values
    _updateMatrices();
  }

  void updateAspectRatio(double newAspectRatio) {
    if ((aspectRatio - newAspectRatio).abs() > 0.001) {
      aspectRatio = newAspectRatio;
      _updateMatrices();
    }
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
    setViewMatrix(_viewMatrix, position, target, up);

    // Projection Matrix: Transforms camera space to clip space
    setPerspectiveMatrix(
      _projectionMatrix,
      radians(fieldOfView),
      aspectRatio,
      nearPlane,
      farPlane,
    );

    // Combined matrix (more efficient)
    _viewProjectionMatrix.setFrom(_projectionMatrix * _viewMatrix);
  }

  // Projects a 3D world point to normalized device coordinates (NDC) [-1, 1]
  // Returns null if the point is behind the camera's near plane (or very close)
  Vector3? projectWorldToNdc(Vector3 worldPoint) {
    final point4 = Vector4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
    final clipPoint = _viewProjectionMatrix.transform(point4);

    // Perspective division
    if (clipPoint.w.abs() < 0.0001) {
      return null; // Avoid division by zero/very small numbers
    }
    final ndc = Vector3(clipPoint.x / clipPoint.w, clipPoint.y / clipPoint.w, clipPoint.z / clipPoint.w);

    // Basic clipping check (z is enough for near plane)
    // Note: Full frustum clipping involves checking x and y against w as well.
    if (ndc.z < -1.0) {
      // Behind near plane in NDC
      return null;
    }

    // Optional: Far plane clipping (if needed)
    // if (ndc.z > 1.0) { // Beyond far plane in NDC
    //    return null;
    // }

    return ndc;
  }

  // Converts NDC [-1, 1] to screen coordinates [0, screenSize]
  Vector2 ndcToScreen(Vector3 ndc, Vector2 screenSize) {
    // Convert NDC Y from math standard (+Y up) to screen standard (+Y down)
    final screenX = (ndc.x + 1.0) * 0.5 * screenSize.x;
    final screenY = (1.0 - ndc.y) * 0.5 * screenSize.y; // Invert Y
    return Vector2(screenX, screenY);
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
