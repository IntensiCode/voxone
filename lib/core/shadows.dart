import 'package:flame/components.dart';
import 'package:voxone/game/context.dart';

extension ContextExtensions on Context {
  Shadows get shadows => cache.putIfAbsent('shadows', () => model.shadows) as Shadows;
}

class Shadows extends Component with HasVisibility {}
