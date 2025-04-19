import 'package:flame/components.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/input/keys.dart';
import 'package:stardash/ui/flow_text.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/ui/highlighted.dart';
import 'package:stardash/util/bitmap_button.dart';
import 'package:stardash/util/game_script.dart';

mixin ControlsUi on GameScriptComponent {
  final keys = Keys();

  final _highlight_group = <BitmapButton>[];

  bool ui_navigation_active = true;

  @override
  void onLoad() {
    add(keys);
    super.onLoad();
  }

  BitmapButton add_button(
    String text,
    double x,
    double y, {
    String? shortcut,
    Anchor anchor = Anchor.topLeft,
    required void Function() onTap,
  }) {
    final button = BitmapButton(
      text: text,
      font: mini_font,
      font_scale: 1.25,
      position: Vector2(x, y),
      anchor: anchor,
      shortcuts: shortcut != null ? [shortcut] : [],
      onTap: () {
        if (ui_navigation_active) onTap();
      },
    );
    add(button);
    _highlight_group.add(button);
    button.removed.then((_) => _highlight_group.remove(button));
    return button;
  }

  void add_flow(String text, double x, double y, double w, double h, Anchor? anchor) {
    add(FlowText(
      text: text,
      font: mini_font,
      font_scale: 1.25,
      size: Vector2(w, h),
      position: Vector2(x, y),
      anchor: anchor ?? Anchor.topLeft,
    ));
  }

  void highlight_down() {
    _remove_highlight(_highlighted);
    if (_highlight_group.isEmpty) return;
    final which = _highlight_group.indexWhere((it) => _is_highlighted(it));
    final index = (which + 1) % _highlight_group.length;
    _add_highlight(_highlight_group[index]);
  }

  void highlight_up() {
    _remove_highlight(_highlighted);
    if (_highlight_group.isEmpty) return;
    final which = _highlight_group.indexWhere((it) => _is_highlighted(it));
    final index = (which - 1) % _highlight_group.length;
    _add_highlight(_highlight_group[index]);
  }

  BitmapButton? _highlighted;

  void _add_highlight(BitmapButton it) {
    _highlighted = it;
    it.add(Highlighted());
  }

  void _remove_highlight(Component? it) {
    if (it == null) return;
    if (_highlighted == it) _highlighted = null;
    final highlighted = it.children.whereType<Highlighted>().toList();
    while (highlighted.isNotEmpty) {
      highlighted.removeAt(0).removeFromParent();
    }
  }

  bool _is_highlighted(Component it) => it.children.any((it) => it is Highlighted);

  @override
  void update(double dt) {
    super.update(dt);
    if (_highlight_group.isEmpty) return;
    if (!ui_navigation_active) return;

    if (keys.check_and_consume(GameKey.up)) highlight_up();
    if (keys.check_and_consume(GameKey.down)) highlight_down();
    if (keys.check_and_consume(GameKey.left)) highlight_up();
    if (keys.check_and_consume(GameKey.right)) highlight_down();
    if (keys.any(typical_select_keys)) trigger_highlighted();
  }

  void trigger_highlighted() => _highlighted?.onTap();
}
