import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math';

// Helper function to replicate the transformation logic from World3DComponent
// Takes local vertex and object's world transform properties
Vector3 transformVertex(
    Vector3 localVertex, Vector3 position3D, Vector3 scale3D, Vector3 rotation) {
      
  // Create matrices for this specific transformation
  final Matrix4 scaleMatrix = Matrix4.identity()..scale(scale3D);
  final Matrix4 rotationMatrix = Matrix4.identity();
  final Matrix4 translationMatrix = Matrix4.identity()..translate(position3D);
  final Matrix4 worldModelMatrix = Matrix4.identity();

  // Build Rotation Matrix (R) - Z*Y*X order
  final rotX = Matrix4.rotationX(rotation.x);
  final rotY = Matrix4.rotationY(rotation.y);
  final rotZ = Matrix4.rotationZ(rotation.z);
  rotationMatrix.multiply(rotZ);
  rotationMatrix.multiply(rotY);
  rotationMatrix.multiply(rotX);

  // Combine into worldModelMatrix (T * R * S)
  worldModelMatrix.setFrom(translationMatrix);
  worldModelMatrix.multiply(rotationMatrix);
  worldModelMatrix.multiply(scaleMatrix);

  // Apply combined world transformation directly to local vertex
  return worldModelMatrix.transform3(localVertex);
}

// Helper for approximate vector comparison using Matcher
Matcher closeToVector(Vector3 expected, double tolerance) {
  return predicate<Vector3>((v) => (v - expected).length < tolerance,
      'a vector within $tolerance of $expected');
}

void main() {
  group('Matrix Transformation Tests -', () {
    test('Identity transform', () {
      final localVertex = Vector3(5.0, -2.0, 3.0);
      final position3D = Vector3.zero();
      final scale3D = Vector3.all(1.0);
      final rotation = Vector3.zero();

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      final expected = Vector3(5.0, -2.0, 3.0);

      expect(result, closeToVector(expected, 0.001));
    });

    test('Translation only', () {
      final localVertex = Vector3(1.0, 1.0, 1.0);
      final position3D = Vector3(10.0, -20.0, 30.0);
      final scale3D = Vector3.all(1.0);
      final rotation = Vector3.zero();

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      final expected = Vector3(11.0, -19.0, 31.0);

      expect(result, closeToVector(expected, 0.001));
    });

    test('Scale only', () {
      final localVertex = Vector3(2.0, 3.0, -4.0);
      final position3D = Vector3.zero();
      final scale3D = Vector3.all(2.0);
      final rotation = Vector3.zero();

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      final expected = Vector3(4.0, 6.0, -8.0);

      expect(result, closeToVector(expected, 0.001));
    });
    
    test('Non-Uniform Scale only', () {
      final localVertex = Vector3(2.0, 3.0, -4.0);
      final position3D = Vector3.zero();
      final scale3D = Vector3(2.0, 0.5, 3.0);
      final rotation = Vector3.zero();

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      final expected = Vector3(4.0, 1.5, -12.0);

       expect(result, closeToVector(expected, 0.001));
    });

    test('Rotation Z only (45 degrees)', () {
      final localVertex = Vector3(1.0, 0.0, 0.0); // Point on X axis
      final position3D = Vector3.zero();
      final scale3D = Vector3.all(1.0);
      final rotation = Vector3(0.0, 0.0, pi / 4); // 45 deg Z

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      final expected = Vector3(cos(pi / 4), sin(pi / 4), 0.0); // Rotates in XY plane

       expect(result, closeToVector(expected, 0.001));
    });
    
     test('Rotation X only (90 degrees)', () {
      final localVertex = Vector3(0.0, 1.0, 0.0); // Point on Y axis
      final position3D = Vector3.zero();
      final scale3D = Vector3.all(1.0);
      final rotation = Vector3(pi / 2, 0.0, 0.0); // 90 deg X

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      final expected = Vector3(0.0, 0.0, 1.0); // Y maps to Z

       expect(result, closeToVector(expected, 0.001));
    });

    test('Rotation Y only (90 degrees)', () {
      final localVertex = Vector3(1.0, 0.0, 0.0); // Point on X axis
      final position3D = Vector3.zero();
      final scale3D = Vector3.all(1.0);
      final rotation = Vector3(0.0, pi / 2, 0.0); // 90 deg Y

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      final expected = Vector3(0.0, 0.0, -1.0); // X maps to -Z

       expect(result, closeToVector(expected, 0.001));
    });

    test('Scale (x2) then Rotate Z (45 degrees)', () {
      final localVertex = Vector3(1.0, 0.0, 0.0);
      final position3D = Vector3.zero();
      final scale3D = Vector3.all(2.0);
      final rotation = Vector3(0.0, 0.0, pi / 4);

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      // Expected: Scale -> (2,0,0), then Rotate -> (2*cos(45), 2*sin(45), 0)
      final expected = Vector3(2 * cos(pi / 4), 2 * sin(pi / 4), 0.0);

       expect(result, closeToVector(expected, 0.001));
    });

    test('Translate then Scale (x2) then Rotate Z (45 degrees)', () {
      final localVertex = Vector3(1.0, 0.0, 0.0);
      final position3D = Vector3(10.0, 5.0, -2.0);
      final scale3D = Vector3.all(2.0);
      final rotation = Vector3(0.0, 0.0, pi / 4);

      final result = transformVertex(localVertex, position3D, scale3D, rotation);
      // Expected: Scale(1,0,0)->(2,0,0); Rot(2,0,0)->(1.414,1.414,0); Trans(1.414,1.414,0)->(11.414, 6.414, -2.0)
      final expected = Vector3(10.0 + 2 * cos(pi / 4), 5.0 + 2 * sin(pi / 4), -2.0);

      expect(result, closeToVector(expected, 0.001));
    });
  });
} 