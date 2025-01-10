import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/input/keys.dart';
import 'package:voxone/ui/basic_menu_entry.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/bitmap_font.dart';

import 'basic_menu_button.dart';

class BasicMenu<T> extends PositionComponent with AutoDispose {
  static final _select_keys = [GameKey.a_button, GameKey.b_button, GameKey.soft2];

  final Keys keys;
  final SpriteSheet button;
  final BitmapFont font;
  final Function(T) onSelected;
  final double spacing;

  final _entries = <(T, BasicMenuEntry)>[];

  List<T> get entries => _entries.map((it) => it.$1).toList();

  Function(T?) onPreselected = (_) {};

  BasicMenu({
    required this.keys,
    required this.button,
    required this.font,
    required this.onSelected,
    this.spacing = 10,
    this.fixed_position,
    this.fixed_size,
    this.fixed_anchor,
  }) : super(anchor: Anchor.center);

  Vector2? fixed_position;
  Vector2? fixed_size;
  Anchor? fixed_anchor;

  void _onSelected(T id) {
    onPreselected(id);
    onSelected(id);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (keys.check_and_consume(GameKey.up)) preselectPrevious();
    if (keys.check_and_consume(GameKey.down)) preselectNext();
    if (keys.any(_select_keys)) select();
  }

  @override
  onMount() {
    final button_width = button.getSpriteById(0).srcSize.x;
    final width = size.isZero() ? button_width : size.x;

    var offset = 0.0;
    for (final (_, it) in _entries) {
      if (it case BasicMenuButton it) {
        it.position.x = width / 2;
        it.position.y = offset;
        it.anchor = Anchor.topCenter;
        offset += it.size.y + spacing;
        if (!it.isMounted) add(it);
      }
    }

    if (size.isZero()) {
      size.x = button_width;
      size.y = offset;
    }

    if (fixed_position != null) position.setFrom(fixed_position!);
    if (fixed_size != null) size.setFrom(fixed_size!);
    if (fixed_anchor != null) anchor = fixed_anchor!;
  }

  BasicMenuButton addEntry(T id, String text, {Anchor anchor = Anchor.center}) {
    final it = BasicMenuButton(
      text,
      size: Vector2(192, 24),
      font: font,
      onTap: () => _onSelected(id),
      text_anchor: anchor,
    );
    _entries.add((id, it));
    return it;
  }

  void addCustom(T id, BasicMenuEntry it) => _entries.add((id, it));

  T? _preselected;

  preselectEntry(T? id) {
    for (final it in _entries) {
      it.$2.selected = it.$1 == id;
    }
    if (_preselected != id) {
      _preselected = id;
      onPreselected(id);
    }
  }

  preselectNext() {
    final idx = _entries.indexWhere((it) => it.$1 == _preselected);
    final it = (idx + 1) % _entries.length;
    preselectEntry(_entries[it].$1);
  }

  preselectPrevious() {
    final idx = _entries.indexWhere((it) => it.$1 == _preselected);
    final it = idx == -1 ? _entries.length - 1 : (idx - 1) % _entries.length;
    preselectEntry(_entries[it].$1);
  }

  select() {
    final it = _preselected;
    if (it != null) _onSelected(it);
  }
}
