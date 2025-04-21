import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/camera3d.dart';
import 'package:stardash/game/has_lighted_faces.dart';
import 'package:stardash/game/has_position_3d.dart';
import 'package:stardash/game/position3d.dart';
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

    // To project origin, no model transform must be applied.
    _worldModelMatrix.setIdentity();

    // Project origin AND store its NDC depth and Clip W
    final (originNdcZ, originClipW) = _project(child.position, child.projectedOrigin);

    // A valid clipW is required for scaling, even if NDC Z is null (off-screen)
    if (originClipW == null || originClipW <= 0) {
      // logInfo('Invalid clip W => Child is not visible: $it, W: $originClipW');
      return it.markInvisible();
    }
    child.clipW = originClipW; // Store clip W

    // Store NDC Z if valid, otherwise keep default (or handle differently?)
    if (originNdcZ == null) {
      // Origin is outside NDC frustum, but W is valid.
      // Still potentially visible via vertices. Set depth based on W?
      // For now, let's mark invisible if origin isn't NDC-visible.
      // We might need more sophisticated culling later.
      // logInfo('Origin not NDC visible => Child is not visible: $it');
      return it.markInvisible();
    }
    child.ndcDepth = originNdcZ; // Store depth

    _initChildTransform(child);

    final _in = child.localVertices;
    final out = child.projectedVertices;
    out.ensureSize(_in.length, () => Vector2.zero());
    for (int i = 0; i < _in.length; i++) {
      if (_project(_in[i], out[i]).$1 == null) {
        return it.markInvisible();
      }
    }

    it.isVisible = true;
    // Use the stored depth for priority calculation
    it.priority = Camera3D.depthToPriority(child.ndcDepth);

    // Set the render transform if needed
    if (child.needsFullTransform) _initRenderTransform(child);
  }

  /// Projects a 3D point into 2D screen coordinates.
  /// Returns tuple (NDC Z coordinate?, Clip W coordinate?)
  (double?, double?) _project(Vector3 from, Vector2 to) {
    // Transform the point to world coordinates
    _worldModelMatrix.transformed3(from, _transformedVertex);

    // Project the transformed point into NDC & Clip Space
    final (ndc, clipPoint) = camera.projectWorldToNdc(_transformedVertex);

    // Get clipW if clipPoint is available
    final double? clipW = clipPoint?.w;

    // If NDC is null, projection failed for screen coordinates. No clipW we don't like either.
    if (ndc == null || clipW == null) {
      return (null, null);
    }

    // Convert NDC to screen coordinates
    to.setFrom(camera.ndcToScreen(ndc));

    // Return both NDC Z and Clip W
    return (ndc.z, clipW);
  }

  void _initChildTransform(Position3D child) {
    _scaleMatrix
      ..setIdentity()
      ..scale(child.scale);

    _rotationMatrix
      ..setIdentity()
      ..rotateZ(child.rotation.z)
      ..rotateY(child.rotation.y)
      ..rotateX(child.rotation.x);

    _translationMatrix
      ..setIdentity()
      ..translate(child.position);

    _worldModelMatrix
      ..setFrom(_translationMatrix)
      ..multiply(_rotationMatrix)
      ..multiply(_scaleMatrix);

    // As of now this is used only for lighting
    child.modelTransform.setFrom(_worldModelMatrix);
  }

  void _initRenderTransform(Position3D child) {
    final it = child.renderTransform;

    // Create model matrix with object's transformations
    it.setFrom(_worldModelMatrix);

    // Get camera's view matrix for rotation
    Matrix4 viewMatrix = Matrix4.copy(camera.viewMatrix);
    viewMatrix.setColumn(3, Vector4(0, 0, 0, 1));
    viewMatrix.setRow(3, Vector4(0, 0, 0, 1));

    // Get inverse view rotation
    Matrix4 viewRotInverse = Matrix4.identity();
    viewRotInverse.copyInverse(viewMatrix);

    // Calculate distance from camera to object
    double distance = (camera.position - child.position).length;

    // Apply scaling based on perspective FOV and distance
    // Adjust this constant based on your scene scale
    double fovScale = 100.0 / distance;
    viewRotInverse.scale(fovScale, fovScale, fovScale);

    // Apply both rotation and scale
    it.multiply(viewRotInverse);
  }

  final _rotMat = Matrix3.identity();
  final _tmpMat = Matrix4.identity();
}
