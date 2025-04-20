import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/camera3d.dart';
import 'package:stardash/game/position_component_3d.dart';

class World3d {
  late final Camera3D camera;

  final Matrix4 _scaleMatrix = Matrix4.identity();
  final Matrix4 _rotationMatrix = Matrix4.identity();
  final Matrix4 _translationMatrix = Matrix4.identity();
  final Matrix4 _worldModelMatrix = Matrix4.identity();

  World3d({Camera3D? camera}) {
    this.camera = camera ??
        Camera3D(
          screenSize: Vector2(game_width, game_height),
          initialPosition: Vector3(0, 0, 100),
          initialTarget: Vector3(0, 0, 0),
        );
  }

  void projectChildren(List<PositionComponent3D> children) {
    for (final child in children) {
      // Reset matrices
      _scaleMatrix.setIdentity();
      _rotationMatrix.setIdentity();
      _translationMatrix.setIdentity();

      // 1. Build Scale Matrix (S)
      _scaleMatrix.scale(child.scale3D);

      // 2. Build Rotation Matrix (R) directly on _rotationMatrix
      // Apply rotations in Z, Y, X order (same effective order as previous Z*Y*X multiplication)
      _rotationMatrix.rotateZ(child.rotation.z);
      _rotationMatrix.rotateY(child.rotation.y);
      _rotationMatrix.rotateX(child.rotation.x);

      // 3. Build Translation Matrix (T)
      _translationMatrix.translate(child.position3D);

      // 4. Combine into worldModelMatrix (T * R * S)
      _worldModelMatrix.setFrom(_translationMatrix);
      _worldModelMatrix.multiply(_rotationMatrix);
      _worldModelMatrix.multiply(_scaleMatrix);

      _projectChild(child);
    }
  }

  final Vector3 _project = Vector3.zero();
  
  void _projectChild(PositionComponent3D child) {
    // Ensure child.projectedVertices has same size as child.localVertices:
    while (child.projectedVertices.length < child.localVertices.length) {
      child.projectedVertices.add(Vector2.zero());
    }
    while (child.projectedVertices.length > child.localVertices.length) {
      child.projectedVertices.removeLast();
    }

    double totalNdcZ = 0;
    int visibleVertexCount = 0;

    for (final localVertex in child.localVertices) {
      final worldVertex = _worldModelMatrix.transform3(localVertex);
      final Vector3? ndc = camera.projectWorldToNdc(worldVertex);
      Vector2? screenPos;
      if (ndc != null) {
        screenPos = camera.ndcToScreen(ndc);
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
