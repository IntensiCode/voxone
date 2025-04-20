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

      _scaleMatrix.scale(child.scale3D);

      _rotationMatrix.rotateZ(child.rotation.z);
      _rotationMatrix.rotateY(child.rotation.y);
      _rotationMatrix.rotateX(child.rotation.x);

      _translationMatrix.translate(child.position3D);

      _worldModelMatrix.setFrom(_translationMatrix);
      _worldModelMatrix.multiply(_rotationMatrix);
      _worldModelMatrix.multiply(_scaleMatrix);

      _projectChild(child);
    }
  }

  final Vector3 _transformedVertex = Vector3.zero();

  void _projectChild(PositionComponent3D child) {
    double totalNdcZ = 0;
    int visibleVertexCount = 0;

    final _in = child.localVertices;
    final out = child.projectedVertices;
    for (int i = 0; i < _in.length; i++) {
      final localVertex = _in[i];
      _worldModelMatrix.transformed3(localVertex, _transformedVertex);

      final Vector3? ndc = camera.projectWorldToNdc(_transformedVertex);
      if (ndc == null) break;

      final screenPos = camera.ndcToScreen(ndc);
      totalNdcZ += ndc.z;
      visibleVertexCount++;

      // Allocate enough only once:
      if (out.length < i + 1) out.add(Vector2.zero());
      out[i].setFrom(screenPos);
    }

    // Priority calculation
    if (visibleVertexCount == child.localVertices.length) {
      final averageNdcZ = totalNdcZ / visibleVertexCount;
      child.priority = Camera3D.depthToPriority(averageNdcZ);
    } else {
      // (Ab)use -1 as "not visible in world":
      child.priority = -1;
    }
  }
}
