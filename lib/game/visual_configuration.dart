import 'package:flame/components.dart';

import '../core/common.dart' as common;
import 'game_data.dart';
import 'storage.dart';

final visual = VisualConfiguration.instance;

class VisualConfiguration extends Component with HasGameData {
  static final instance = VisualConfiguration._();

  VisualConfiguration._();

  bool _pixelate = true;
  bool _pixelate_screen = true;
  bool _animate_stars = false;

  bool get pixelate => _pixelate;

  bool get pixelate_screen => _pixelate_screen;

  bool get animate_stars => _animate_stars;

  set pixelate(bool value) {
    _pixelate = value;
    save('visual', this);
  }

  set pixelate_screen(bool value) {
    _pixelate_screen = value;
    save('visual', this);
  }

  set animate_stars(bool value) {
    _animate_stars = value;
    save('visual', this);
  }

  bool get debug => common.debug;

  set debug(bool value) {
    common.debug = value;
    save('visual', this);
  }

  final frame_shadow_size = 6.0;
  final shadow_offset = 4.0;

  final brick_width = 12;
  final brick_height = 6;
  final brick_inset = 2.5; // offset from the frame walls

  final level_bricks = Vector2(15, 20);

  final game_offset = Vector2(16, 0); // offset into the screen - to show passing stars outside
  final border_size = 8.0; // frame border width
  late final game_position = game_offset + Vector2.all(border_size) + Vector2.all(2);

  late final game_frame_size = Vector2.all(200);
  late final game_pixels = Vector2(
    game_frame_size.x - border_size * 2 - brick_inset * 2,
    game_frame_size.y - border_size,
  );

  late final background_offset = Vector2.all(-border_size - brick_inset);

  final plasma_size = Vector2(64, 64);

  // Component

  @override
  onLoad() async => await load('visual', this);

  // HasGameData

  @override
  void load_state(Map<String, dynamic> data) {
    _pixelate = data['pixelate'] ?? _pixelate;
    _pixelate_screen = data['pixelate_screen'] ?? _pixelate;
    _animate_stars = data['animate_stars'] ?? _animate_stars;
    debug = data['debug'] ?? debug;
  }

  @override
  GameData save_state(Map<String, dynamic> data) => data
    ..['pixelate'] = _pixelate
    ..['pixelate_screen'] = _pixelate_screen
    ..['animate_stars'] = _animate_stars
    ..['debug'] = debug;
}
