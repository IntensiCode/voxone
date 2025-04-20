import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/game/position3d.dart';

mixin HasPosition3D on PositionComponent {
  late final Position3D position3d;
}

// Mixin for components that have faces and respond to simple lighting
mixin HasLightedFaces on HasPosition3D {
  // Faces defined as indices into position3d.localVertices
  List<List<int>> localFaces = [];
  // Normals corresponding to each face in local space
  List<Vector3> faceNormals = [];
  // Calculated light intensity per face (0.0 to 1.0)
  List<double> faceLightIntensities = [];

  // Temporary variables for calculation to avoid reallocation
  final Matrix3 _normalMatrix = Matrix3.identity();
  final Vector3 _worldNormal = Vector3.zero();

  /// Calculates light intensity for each face based on world orientation and light direction.
  /// Requires worldTransform to be up-to-date.
  void calculateLighting(Vector3 lightDirection) {
    if (faceNormals.isEmpty) return; // Nothing to calculate

    // Ensure intensity list matches face list size
    if (faceLightIntensities.length != faceNormals.length) {
      faceLightIntensities = List.filled(faceNormals.length, 0.0);
    }

    // Extract rotation part for normal transformation
    position3d.worldTransform.copyRotation(_normalMatrix);

    for (int i = 0; i < faceNormals.length; i++) {
      final localNormal = faceNormals[i];
      _worldNormal.setFrom(localNormal); // Copy first
      _normalMatrix.transform(_worldNormal); // Then transform in place
      _worldNormal.normalize();

      // Intensity based on angle: dot product between normal and negative light direction
      final double intensity = max(0.0, _worldNormal.dot(-lightDirection));

      // Add ambient light
      const double ambient = 0.1;
      faceLightIntensities[i] = ambient + (1.0 - ambient) * intensity;
    }
  }
}

// Base class for components existing in the 3D world space managed by World3DComponent
class PositionComponent3D extends PositionComponent {
  // TODO: Remove this class if we can't find functionality for it to hold
  final Position3D position3d;

  PositionComponent3D(this.position3d);
}
