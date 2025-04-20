import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/camera3d.dart';
import 'package:stardash/game/has_lighted_faces.dart';
import 'package:stardash/game/has_position_3d.dart';
import 'package:vector_math/vector_math_64.dart';

class World3d {
  late final Camera3D camera;

  // World properties
  double ambientLightLevel = 0.2;
  final Vector3 lightDirection = Vector3(0.5, 0.75, -1.0)..normalize();

  final Matrix4 _scaleMatrix = Matrix4.identity();
  final Matrix4 _rotationMatrix = Matrix4.identity();
  final Matrix4 _translationMatrix = Matrix4.identity();
  final Matrix4 _worldModelMatrix = Matrix4.identity();

  final Vector3 _transformedVertex = Vector3.zero();

  World3d({Camera3D? camera}) {
    this.camera = camera ??
        Camera3D(
          screenSize: Vector2(game_width, game_height),
          initialPosition: Vector3(0, 0, 100),
          initialTarget: Vector3(0, 0, 0),
        );
  }

  void projectChildren(Iterable<HasPosition3D> children) {
    for (final it in children) {
      final child = it.position3d;

      // Reset matrices
      _scaleMatrix.setIdentity();
      _rotationMatrix.setIdentity();
      _translationMatrix.setIdentity();

      _scaleMatrix.scale(child.scale);

      _rotationMatrix.rotateZ(child.rotation.z);
      _rotationMatrix.rotateY(child.rotation.y);
      _rotationMatrix.rotateX(child.rotation.x);

      _translationMatrix.translate(child.position);

      _worldModelMatrix.setFrom(_translationMatrix);
      _worldModelMatrix.multiply(_rotationMatrix);
      _worldModelMatrix.multiply(_scaleMatrix);

      // Store the final world transform on the child
      child.worldTransform.setFrom(_worldModelMatrix);

      _projectChild(it);
    }
  }

  /// To be called after projectChildren.
  void lightChildren(Iterable<HasLightedFaces> children) {
    for (final it in children) {
      it.calculateLighting(lightDirection, ambientLightLevel);
    }
  }

  void _projectChild(HasPosition3D it) {
    final child = it.position3d;

    double totalNdcZ = 0;
    int visibleVertexCount = 0;
    Vector2 projectedCenter = Vector2.zero(); // Accumulate projected center

    final _in = child.localVertices;
    final out = child.projectedVertices;
    for (int i = 0; i < _in.length; i++) {
      final localVertex = _in[i];
      child.worldTransform.transformed3(localVertex, _transformedVertex);

      final Vector3? ndc = camera.projectWorldToNdc(_transformedVertex);
      if (ndc == null) {
        visibleVertexCount = 0;
        break;
      }

      final screenPos = camera.ndcToScreen(ndc);
      projectedCenter.add(screenPos); // Accumulate screen positions

      totalNdcZ += ndc.z;
      visibleVertexCount++;

      // Allocate enough only once:
      if (out.length < i + 1) out.add(Vector2.zero());
      out[i].setFrom(screenPos);
    }

    // Priority and Position calculation
    if (visibleVertexCount == child.localVertices.length) {
      // Calculate average Z for priority
      final averageNdcZ = totalNdcZ / visibleVertexCount;
      it.priority = Camera3D.depthToPriority(averageNdcZ);
    } else {
      // Mark as invisible
      it.priority = -1;
    }
  }
}
