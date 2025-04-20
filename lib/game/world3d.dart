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
      initialPosition: Vector3(0, 0, 10),
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
    // First, update self and all children
    super.updateTree(dt);
    // logInfo('World3D updateTree after super.updateTree');

    // --- Projection Step ---
    // Now that children have updated their 3D positions, project them.
    for (final child in children) {
      if (child is PositionComponent3D) {
        final Vector3? ndc = camera.projectWorldToNdc(child.position3D);

        if (ndc != null) {
          final Vector2 screenPos = camera.ndcToScreen(ndc, _screenSize);
          final double depth = ndc.z; // NDC Z for depth

          // --- Calculate Scale ---
          final point4 = Vector4(child.position3D.x, child.position3D.y, child.position3D.z, 1.0);
          // Transform to view space to get distance (w component after view matrix)
          final viewPoint = camera.viewMatrix.transform(point4);
          final viewSpaceDistance = viewPoint.w;

          const double referenceDistance = 50.0; // Distance for scale = 1.0
          double scaleFactor = (viewSpaceDistance.abs() > 0.01) ? referenceDistance / viewSpaceDistance.abs() : 10.0; // Avoid huge scale if too close
          scaleFactor = scaleFactor.clamp(0.05, 10.0); // Clamp scale

          // --- Update Child's 2D Properties ---
          // For now, use a fixed base size scaled. Could use child.size3D later.
          const double baseSize = 10.0; // Make it smaller
          child.size.setValues(baseSize * scaleFactor, baseSize * scaleFactor);
          child.position.setFrom(screenPos);
          child.priority = Camera3D.depthToPriority(depth);

        } else {
          // --- Clipped --- Set size to zero and low priority
          child.position.setValues(-1000,-1000); // Off-screen
          child.size.setValues(0, 0);
          child.priority = -1; // Render first/background (effectively hides)
        }
      }
    }
    // logInfo('World3D updateTree end');
  }
} 
