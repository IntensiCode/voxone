import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/game/shadows.dart';
import 'package:voxone/game/stacked_sprite.dart';

class StackedEntity extends PositionComponent {
  final Shadows _shadows;

  StackedEntity.image(Image image, int frames, this._shadows) {
    anchor = Anchor.center;
    _shadow = StackedSprite.image(image, frames, highlight_mode: HighlightMode.shadow);
    sprite = StackedSprite.image(image, frames, highlight_mode: HighlightMode.none);
    size.addListener(() {
      _update_shadow();
      sprite.size.setFrom(this.size);
    });
    scale.addListener(() {
      _update_shadow();
    });
    position.addListener(() {
      _update_shadow();
    });
    add(sprite);
  }

  StackedEntity(String asset, int frames, this._shadows) {
    anchor = Anchor.center;
    _shadow = StackedSprite(asset, frames, highlight_mode: HighlightMode.shadow);
    sprite = StackedSprite(asset, frames, highlight_mode: HighlightMode.none);
    size.addListener(() {
      _update_shadow();
      sprite.size.setFrom(this.size);
    });
    scale.addListener(() {
      _update_shadow();
    });
    position.addListener(() {
      _update_shadow();
    });
    add(sprite);
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

  late final StackedSprite sprite;
  late final StackedSprite _shadow;

  set scale_x(double value) {
    sprite.scale_x = value;
    _shadow.scale_x = value;
  }

  set scale_y(double value) {
    sprite.scale_y = value;
    _shadow.scale_y = value;
  }

  set scale_z(double value) {
    sprite.scale_z = value;
    _shadow.scale_z = value;
  }

  double get rot_x => sprite.rot_x;

  double get rot_y => sprite.rot_y;

  double get rot_z => sprite.rot_z;

  set rot_x(double value) {
    sprite.rot_x = value;
    _shadow.rot_x = value;
  }

  set rot_y(double value) {
    sprite.rot_y = value;
    _shadow.rot_y = value;
  }

  set rot_z(double value) {
    sprite.rot_z = value;
    _shadow.rot_z = value;
  }

  @override
  void onLoad() {
    _shadows.add(_shadow);
  }
}
