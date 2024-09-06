import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../components/soft_keys.dart';
import '../core/common.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/functions.dart';
import '../util/game_script_functions.dart';
import '../util/keys.dart';
import '../util/nine_patch_image.dart';

class DialogKeys extends Component {
  DialogKeys({required this.handlers, this.tap_key, this.left, this.right, this.shortcuts = true});

  final Map<GameKey, Function> handlers;
  final GameKey? tap_key;
  final String? left;
  final String? right;
  final bool shortcuts;

  Keys? keys;

  @override
  void onLoad() {
    if (shortcuts) add(keys = Keys());
  }

  void handle(SoftKey it) {
    if (it == SoftKey.left) handlers[GameKey.soft1]!();
    if (it == SoftKey.right) handlers[GameKey.soft2]!();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (keys?.check_and_consume(GameKey.soft1) == true) handlers[GameKey.soft1]!();
    if (keys?.check_and_consume(GameKey.soft2) == true) handlers[GameKey.soft2]!();
    if (keys?.check_and_consume(GameKey.fire1) == true) handlers[GameKey.soft2]!();
  }
}

class BackgroundCatcher extends RectangleComponent with DragCallbacks, TapCallbacks {
  BackgroundCatcher(this.onTap) : super(size: game_size, paint: pixel_paint()..color = shadow);

  final void Function() onTap;

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTap();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    onTap();
  }
}

class GameDialog extends PositionComponent
    with AutoDispose, GameScriptFunctions, HasPaint, DragCallbacks, TapCallbacks {
  //
  GameDialog({
    required this.content,
    this.keys,
    Vector2? size,
    Color shadow = shadow,
    this.background = true,
  }) : super(position: game_size / 2, anchor: Anchor.center) {
    this.size = size ?? content.size;
    priority = 100;
  }

  final PositionComponent content;
  final DialogKeys? keys;
  final bool background;

  Component? _background;

  @override
  onLoad() async {
    super.onLoad();

    final bg = await image('button_plain.png');

    if (background) {
      parent!.add(_background = BackgroundCatcher(() => removeFromParent()));
      add(NinePatchComponent(image: bg, size: size));
    }

    add(content);

    if (keys != null) {
      add(keys!);
      if (keys?.left != null) {
        await add_button(bg, keys!.left!, 0, size.y, Anchor.topLeft, () => keys!.handle(SoftKey.left));
      }
      if (keys?.right != null) {
        await add_button(bg, keys!.right!, size.x, size.y, Anchor.topRight, () => keys!.handle(SoftKey.right));
      }
    }

    for (final it in children) {
      it.fadeInDeep();
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    _background?.removeFromParent();
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (keys?.tap_key != null) keys!.handlers[keys!.tap_key!]!();
  }
}
