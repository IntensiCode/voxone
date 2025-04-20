import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/camera3d.dart';
import 'package:stardash/game/has_lighted_faces.dart';
import 'package:stardash/game/has_position_3d.dart';
import 'package:stardash/util/extensions.dart';
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

    final zPos = _project(child.position, child.projectedOrigin);
    if (zPos == null) {
      return it.markInvisible();
    }

    final _in = child.localVertices;
    final out = child.projectedVertices;
    out.ensureSize(_in.length, () => Vector2.zero());
    for (int i = 0; i < _in.length; i++) {
      if (_project(_in[i], out[i]) == null) {
        return it.markInvisible();
      }
    }

    it.isVisible = true;
    it.priority = Camera3D.depthToPriority(zPos);
  }

  /// Projects a 3D point into 2D screen coordinates.
  double? _project(Vector3 from, Vector2 to) {
    // Transform the point to world coordinates
    _worldModelMatrix.transformed3(from, _transformedVertex);

    // Project the transformed point into NDC (Normalized Device Coordinates)
    final Vector3? ndc = camera.projectWorldToNdc(_transformedVertex);
    if (ndc == null) return null;

    // Convert NDC to screen coordinates
    to.setFrom(camera.ndcToScreen(ndc));
    return ndc.z;
  }
}
