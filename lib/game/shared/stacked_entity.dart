import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/util/stacked_sprite.dart';

class StackedEntity extends PositionComponent {
  StackedEntity.sprite(Sprite sprite, int frames, this._shadows) {
    anchor = Anchor.center;
    this.sprite = StackedSprite.sprite(sprite, frames, highlight_mode: HighlightMode.none);
    size.addListener(() => this.sprite.size.setFrom(this.size));
    add(this.sprite);
  }

  StackedEntity(String asset, int frames, this._shadows) {
    anchor = Anchor.center;
    sprite = StackedSprite(asset, frames, highlight_mode: HighlightMode.none);
    size.addListener(() => sprite.size.setFrom(this.size));
    add(sprite);
  }

  final Shadows _shadows;
  late final StackedSprite sprite;
  _Shadow? _shadow;

  set scale_x(double value) => sprite.scale_x = value;

  set scale_y(double value) => sprite.scale_y = value;

  set scale_z(double value) => sprite.scale_z = value;

  double get rot_x => sprite.rot_x;

  double get rot_y => sprite.rot_y;

  double get rot_z => sprite.rot_z;

  set rot_x(double value) => sprite.rot_x = value;

  set rot_y(double value) => sprite.rot_y = value;

  set rot_z(double value) => sprite.rot_z = value;

  set fake_height(double? height) => _shadow?.fake_height = height;

  double? get fake_height => _shadow?.fake_height;

  @override
  onLoad() {
    _shadow = _Shadow(this);
    _shadows.add(_shadow!);
    removed.then((_) {
      final s = _shadow;
      if (s == null || s.isRemoved || s.isRemoving) return;
      _shadows.remove(s);
    });
  }
}

class _Shadow extends Component with HasPaint, HasVisibility {
  _Shadow(this._entity) {
    paint.color = black.withAlpha(128);
  }

  final StackedEntity _entity;

  double? fake_height;

  @override
  void render(Canvas canvas) {
    if (_entity.parent is! PositionComponent) return;
    if (fake_height == null) return;

    final pp = (_entity.parent as PositionComponent);
    canvas.save();
    canvas.translate(pp.x, pp.y);
    canvas.translate(fake_height! / 4, fake_height!);
    canvas.translate(-pp.scaledSize.x / 2, -pp.scaledSize.y / 2);
    canvas.scaleVector(pp.scale);
    _entity.sprite.renderShadow(canvas);
    canvas.restore();
  }
}
