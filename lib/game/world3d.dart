import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/camera3d.dart'; // Use correct package name
import 'package:stardash/game/position_component_3d.dart'; // Use correct package name

class World3DComponent extends Component {
  late final Camera3D camera;
  late Vector2 _screenSize = Vector2(game_width, game_height); // Initialize with static size

  World3DComponent({Camera3D? camera}) {
    this.camera = camera ?? Camera3D(
      initialPosition: Vector3(0, 0, 100), // Static camera position
      initialTarget: Vector3(0, 0, 0),
    );
    _updateCameraAspectRatio(); // Use static size for aspect ratio
  }

  void _updateCameraAspectRatio() {
      // Aspect ratio is now based on static game size from common.dart
      final double aspect = game_width / game_height;
      camera.updateAspectRatio(aspect);
  }

  @override
  void update(double dt) {
    // logInfo('World3D update start');
    super.update(dt); // Let the default update handle its own logic if any.
    // logInfo('World3D update after super');
    // --- Projection Step Moved to updateTree ---
  }

  @override
  void updateTree(double dt) {
    // logInfo('World3D updateTree start');
    // First, update self and all children (updates their position3D etc.)
    super.updateTree(dt);
    // logInfo('World3D updateTree after super.updateTree');

    // --- Projection Step ---
    for (final child in children) {
      if (child is PositionComponent3D) {

        // Declare matrices INSIDE the loop for guaranteed freshness per child
        final Matrix4 scaleMatrix = Matrix4.identity()..scale(child.scale3D);
        final Matrix4 rotationMatrix = Matrix4.identity();
        final Matrix4 translationMatrix = Matrix4.identity()..translate(child.position3D);
        final Matrix4 worldModelMatrix = Matrix4.identity();

        // Build Rotation Matrix (R)
        final rotX = Matrix4.rotationX(child.rotation.x);
        final rotY = Matrix4.rotationY(child.rotation.y);
        final rotZ = Matrix4.rotationZ(child.rotation.z);
        rotationMatrix.multiply(rotZ);
        rotationMatrix.multiply(rotY);
        rotationMatrix.multiply(rotX);

        // Combine into worldModelMatrix (T * R * S)
        // Note: Matrix multiplication order is right-to-left application
        worldModelMatrix.setFrom(translationMatrix);
        worldModelMatrix.multiply(rotationMatrix);
        worldModelMatrix.multiply(scaleMatrix);

        child.projectedVertices.clear();
        double totalNdcZ = 0;
        int visibleVertexCount = 0;

        for (final localVertex in child.localVertices) {
          final worldVertex = worldModelMatrix.transform3(localVertex);
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

        // --- Remove old 2D property updates ---
        // child.size, child.position, child.anchor are now determined by how the child renders its projectedVertices

      }
    }
    // logInfo('World3D updateTree end');
  }
} 
