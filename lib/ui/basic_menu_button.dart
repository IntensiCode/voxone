import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:stardash/ui/basic_menu_entry.dart';
import 'package:stardash/ui/bordered.dart';
import 'package:stardash/ui/highlighted.dart';
import 'package:stardash/util/bitmap_font.dart';
import 'package:stardash/util/bitmap_text.dart';
import 'package:stardash/util/extensions.dart';

class BasicMenuButton extends PositionComponent with BasicMenuEntry, HasVisibility, TapCallbacks {
  BasicMenuButton(
    String text, {
    required super.size,
    required this.font,
    required this.onTap,
    bool selected = false,
    Anchor text_anchor = Anchor.center,
  }) {
    add(Bordered());
    add(_highlighted = Highlighted());

    final p = Vector2.copy(size);
    p.x -= 12;
    p.x *= text_anchor.x;
    p.y *= text_anchor.y;
    p.x += 6;
    add(BitmapText(
      text: text,
      position: p,
      font: font,
      anchor: text_anchor,
    ));

    this.selected = selected;
  }

  final BitmapFont font;
  final Function onTap;

  late Highlighted _highlighted;

  BitmapText? _checked;

  @override
  set selected(bool value) => _highlighted.isVisible = value;

  @override
  set checked(bool value) {
    _checked?.removeFromParent();
    final p = Vector2.copy(size);
    p.x -= 6;
    p.y = size.y / 2;
    _checked = added(BitmapText(
      text: value ? 'ON' : 'OFF',
      position: p,
      font: font,
      anchor: Anchor.centerRight,
    ));
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}
