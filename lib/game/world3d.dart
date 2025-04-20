import 'dart:math'; // Import for max

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
  final Vector3 lightDirection = Vector3(0.5, -0.75, -1.0)..normalize();

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

  final Vector3 _transformedVertex = Vector3.zero();
  final Vector3 _objectCenterWorld = Vector3.zero();
  final Vector3 _objectToCamera = Vector3.zero();
  final Vector3 _cameraForward = Vector3.zero();

  void _projectChild(HasPosition3D it) {
    final child = it.position3d;

    // --- Object-Level Near Plane Culling ---
    // Get object center in world space
    _objectCenterWorld.setValues(0, 0, 0);
    child.worldTransform.transformed3(_objectCenterWorld, _objectCenterWorld);

    // Get camera forward direction (target - position)
    _cameraForward.setFrom(camera.target);
    _cameraForward.sub(camera.position);
    _cameraForward.normalize();

    // Vector from camera position to object center
    _objectToCamera.setFrom(_objectCenterWorld);
    _objectToCamera.sub(camera.position);

    // Distance along camera's forward axis (dot product)
    final double distanceToPlane = _objectToCamera.dot(_cameraForward);

    // Approximate object radius (use largest dimension for safety)
    final double maxDimension = max(child.size.x, max(child.size.y, child.size.z));
    final double objectRadius = maxDimension * child.scale.x * 0.5; // Assuming uniform scale for now

    if (distanceToPlane < camera.nearPlane + objectRadius) {
      // Object is too close or intersecting near plane, cull it entirely
      it.priority = -1;
      return; // Skip vertex projection for this object
    }
    // --- End Culling ---

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
      it.priority = Camera3D.depthToPriority(averageNdcZ);
    } else {
      // (Ab)use -1 as "not visible in world":
      it.priority = -1;
    }
  }
}
