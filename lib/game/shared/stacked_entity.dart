import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/util/stacked_sprite.dart';

class StackedEntity extends PositionComponent {
  StackedEntity.image(Image image, int frames, this._shadows) {
    anchor = Anchor.center;
    sprite = StackedSprite.image(image, frames, highlight_mode: HighlightMode.none);
    size.addListener(() => sprite.size.setFrom(this.size));
    add(sprite);
  }

  StackedEntity(String asset, int frames, this._shadows) {
    anchor = Anchor.center;
    sprite = StackedSprite(asset, frames, highlight_mode: HighlightMode.none);
    size.addListener(() => sprite.size.setFrom(this.size));
    add(sprite);
  }

  final Shadows _shadows;
  late final StackedSprite sprite;
  late final _Shadow _shadow;

  set scale_x(double value) => sprite.scale_x = value;

  set scale_y(double value) => sprite.scale_y = value;

  set scale_z(double value) => sprite.scale_z = value;

  double get rot_x => sprite.rot_x;

  double get rot_y => sprite.rot_y;

  double get rot_z => sprite.rot_z;

  set rot_x(double value) => sprite.rot_x = value;

  set rot_y(double value) => sprite.rot_y = value;

  set rot_z(double value) => sprite.rot_z = value;

  @override
  onLoad() {
    _shadow = _Shadow(this);
    _shadows.add(_shadow);
  }
}

class _Shadow extends Component with HasVisibility {
  _Shadow(this._entity);

  final StackedEntity _entity;

  @override
  void render(Canvas canvas) {
    if (_entity.parent is! PositionComponent) return;

    final pp = (_entity.parent as PositionComponent);
    canvas.save();
    canvas.translate(pp.x, pp.y);
    canvas.scaleVector(pp.scale);
    _entity.sprite.renderShadow(canvas);
    canvas.restore();
  }
}
