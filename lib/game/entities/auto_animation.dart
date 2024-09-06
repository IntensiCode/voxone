import 'package:voxone/game/entities/enemy.dart';
import 'package:voxone/game/entities/enemy_behavior.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class AutoAnimation extends SpriteAnimationComponent with EnemyBehavior {
  AutoAnimation(this.sprites);

  final SpriteSheet sprites;

  final _last_seen = Vector2.zero();

  late final Enemy enemy;

  double _anim_time = 0;

  @override
  void attach(Enemy enemy) => this.enemy = enemy;

  @override
  void update(double dt) {
    super.update(dt);

    if (_last_seen == my_prop.position) return;
    _last_seen.setFrom(my_prop.position);

    _animate_movement(dt);
    _update_sprite();
  }

  void _animate_movement(double dt) {
    _anim_time += dt * 2;
    if (_anim_time >= 1) _anim_time -= 1;
  }

  void _update_sprite() {
    final frame = (_anim_time * 4).toInt().clamp(0, 3);

    final fire_dir = enemy.fire_dir;
    var offset = 4;
    if (fire_dir.y == 0) {
      if (fire_dir.x < 0) offset = 8;
      if (fire_dir.x > 0) offset = 12;
    }
    if (fire_dir.y < 0) offset = 0;
    if (fire_dir.y > 0) offset = 4;

    final weapon = enemy.active_weapon?.index ?? 0;
    final firing = enemy.show_firing > 0 ? 16 : 0;
    my_prop.sprite = sprites.getSprite(18 + weapon, 16 + offset + frame + firing);
  }
}
