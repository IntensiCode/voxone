import 'package:flame/components.dart';
import 'package:voxone/game/shared/has_context.dart';

extension HasContextExtensions on HasContext {
  Shadows get shadows => cache.putIfAbsent('shadows', () => Shadows());
}

class Shadows extends Component with HasVisibility {}
