import 'package:flame/components.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/input/keys.dart';
import 'package:voxone/ui/basic_menu.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/ui/soft_keys.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';

class VideoMenu extends GameScriptComponent {
  VideoMenu({required this.show_back});

  final bool show_back;

  final _keys = Keys();

  late final BasicMenu<VideoMode> menu;

  static VideoMode? _preselected;

  @override
  onLoad() {
    add(_keys);
    add(space);

    fontSelect(tiny_font, scale: 2);
    textXY('Video Mode', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);

    _preselected = video;

    menu = added(BasicMenu<VideoMode>(
      keys: _keys,
      button: atlas.sheetI('button_option.png', 1, 2),
      font: mini_font,
      onSelected: _selected,
      spacing: 10,
    )
      ..addEntry(VideoMode.performance, 'Performance')
      ..addEntry(VideoMode.balanced, 'Balanced')
      ..addEntry(VideoMode.quality, 'Quality'));

    menu.position.setValues(game_center.x, 64);
    menu.anchor = Anchor.topCenter;
    menu.onPreselected = (it) => _preselected = it;

    if (show_back) softkeys('Back', null, (_) => popScreen());

    menu.preselectEntry(_preselected ?? VideoMode.balanced);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (show_back && _keys.check_and_consume(GameKey.soft1)) popScreen();
  }

  void _selected(VideoMode it) {
    video = it;
    popScreen();
  }
}
