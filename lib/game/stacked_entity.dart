import 'package:flame/components.dart';
import 'package:voxone/game/shadows.dart';
import 'package:voxone/game/stacked_sprite.dart';

class StackedEntity extends PositionComponent {
  final Shadows _shadows;

  StackedEntity(String asset, int frames, this._shadows) {
    anchor = Anchor.center;
    _shadow = StackedSprite(asset, frames, shadow: true);
    _sprite = StackedSprite(asset, frames, shadow: false);
    size.addListener(() {
      _update_shadow();
      _sprite.size.setFrom(this.size);
    });
    scale.addListener(() {
      _update_shadow();
    });
    position.addListener(() {
      _update_shadow();
    });
    add(_sprite);
  }

  set shadow(bool value) => _shadow.isVisible = value;

  void _update_shadow() {
    _shadow.anchor = Anchor.center;
    _shadow.size.setFrom(this.size);
    _shadow.scale.setFrom(scale);
    _shadow.position.setFrom(position);
    _shadow.x += 25;
    _shadow.y += 50;
  }

  late final StackedSprite _sprite;
  late final StackedSprite _shadow;

  set scale_x(double value) {
    _sprite.scale_x = value;
    _shadow.scale_x = value;
  }

  set scale_y(double value) {
    _sprite.scale_y = value;
    _shadow.scale_y = value;
  }

  set scale_z(double value) {
    _sprite.scale_z = value;
    _shadow.scale_z = value;
  }

  double get rot_x => _sprite.rot_x;

  double get rot_y => _sprite.rot_y;

  double get rot_z => _sprite.rot_z;

  set rot_x(double value) {
    _sprite.rot_x = value;
    _shadow.rot_x = value;
  }

  set rot_y(double value) {
    _sprite.rot_y = value;
    _shadow.rot_y = value;
  }

  set rot_z(double value) {
    _sprite.rot_z = value;
    _shadow.rot_z = value;
  }

  @override
  void onLoad() {
    _shadows.add(_shadow);
  }
}
