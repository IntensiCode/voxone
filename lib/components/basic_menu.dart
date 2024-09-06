import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../util/auto_dispose.dart';
import '../util/bitmap_font.dart';
import '../util/shortcuts.dart';
import 'basic_menu_button.dart';

class BasicMenu<T> extends PositionComponent with AutoDispose, HasAutoDisposeShortcuts {
  final SpriteSheet button;
  final BitmapFont font;
  final double fontScale;
  final Function(T) onSelected;
  final bool defaultShortcuts;
  final double spacing;

  final _entries = <(T, BasicMenuButton)>[];

  List<T> get entries => _entries.map((it) => it.$1).toList();

  Function(T?) onPreselected = (_) {};

  BasicMenu({
    required this.button,
    required this.font,
    required this.onSelected,
    this.defaultShortcuts = true,
    this.fontScale = 1,
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
  onMount() {
    if (defaultShortcuts) {
      onKey('<Up>', () => preselectPrevious());
      onKey('k', () => preselectPrevious());
      onKey('<Down>', () => preselectNext());
      onKey('j', () => preselectNext());
      onKey('<Enter>', () => select());
      onKey('<Space>', () => select());
    }

    final button_width = button.getSpriteById(0).srcSize.x;
    final width = size.isZero() ? button_width : size.x;

    var offset = 0.0;
    for (final (_, it) in _entries) {
      it.position.x = width / 2;
      it.position.y = offset;
      it.anchor = Anchor.topCenter;
      offset += it.size.y + spacing;
      if (!it.isMounted) add(it);
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
      sheet: button,
      font: font,
      font_scale: fontScale,
      on_tap: () => _onSelected(id),
      text_anchor: anchor,
    );
    _entries.add((id, it));
    return it;
  }

  T? _preselected;

  preselectEntry(T? id) {
    for (final it in _entries) {
      it.$2.selected = identical(it.$1, id);
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
