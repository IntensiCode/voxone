import 'package:flame/components.dart'; // For Vector3, Matrix4
import 'package:stardash/core/common.dart'; // For game_width/height
import 'package:stardash/game/camera3d.dart';
import 'package:stardash/game/position_component_3d.dart';

class World3d {
  late final Camera3D camera;
  late Vector2 _screenSize = Vector2(game_width, game_height);

  final Matrix4 _scaleMatrix = Matrix4.identity();
  final Matrix4 _rotationMatrix = Matrix4.identity();
  final Matrix4 _translationMatrix = Matrix4.identity();
  final Matrix4 _worldModelMatrix = Matrix4.identity();

  World3d({Camera3D? camera}) {
    this.camera = camera ??
        Camera3D(
          initialPosition: Vector3(0, 0, 100),
          initialTarget: Vector3(0, 0, 0),
        );

    _updateCameraAspectRatio();
  }

  void _updateCameraAspectRatio() {
    final double aspect = game_width / game_height;
    camera.updateAspectRatio(aspect);
  }

  // Method to perform the projection logic for a list of 3D children
  void projectChildren(List<PositionComponent3D> children) {
    for (final child in children) {
      // Reset matrices
      _scaleMatrix.setIdentity();
      _rotationMatrix.setIdentity();
      _translationMatrix.setIdentity();

      // 1. Build Scale Matrix (S)
      _scaleMatrix.scale(child.scale3D);

      // 2. Build Rotation Matrix (R)
      final rotX = Matrix4.rotationX(child.rotation.x);
      final rotY = Matrix4.rotationY(child.rotation.y);
      final rotZ = Matrix4.rotationZ(child.rotation.z);
      _rotationMatrix.multiply(rotZ);
      _rotationMatrix.multiply(rotY);
      _rotationMatrix.multiply(rotX);

      // 3. Build Translation Matrix (T)
      _translationMatrix.translate(child.position3D);

      // 4. Combine into worldModelMatrix (T * R * S)
      _worldModelMatrix.setFrom(_translationMatrix);
      _worldModelMatrix.multiply(_rotationMatrix);
      _worldModelMatrix.multiply(_scaleMatrix);

      child.projectedVertices.clear();
      double totalNdcZ = 0;
      int visibleVertexCount = 0;

      for (final localVertex in child.localVertices) {
        final worldVertex = _worldModelMatrix.transform3(localVertex);
        final Vector3? ndc = camera.projectWorldToNdc(worldVertex);
        Vector2? screenPos;
        if (ndc != null) {
          screenPos = camera.ndcToScreen(ndc, _screenSize);
          totalNdcZ += ndc.z;
          visibleVertexCount++;
        }
        child.projectedVertices.add(screenPos);
      }

      // Priority calculation
      if (visibleVertexCount > 0) {
        final averageNdcZ = totalNdcZ / visibleVertexCount;
        child.priority = Camera3D.depthToPriority(averageNdcZ);
      } else {
        child.priority = -1;
      }
    }
  }
}
