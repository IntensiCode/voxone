import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/game_messages.dart';
import 'package:voxone/game/player/player_state.dart';
import 'package:voxone/game/player/projectile.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/keys.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/random.dart';
import 'package:flame/components.dart';

class BaseWeapon extends Component with AutoDispose, GameContext {
  BaseWeapon(
    this.type,
    this._animation,
    this._sound, {
    required this.fire_rate,
    required this.spread,
    this.projectile_speed = 250,
  });

  final WeaponType type;
  final SpriteAnimation _animation;
  final Sound _sound;

  final double fire_rate;
  final double spread;
  final double projectile_speed;

  late final Keys _keys;
  late final _recycler = ComponentRecycler(() => Projectile(type));

  final temp_pos = Vector2.zero();
  final velocity = Vector2.zero();

  int ammo = 0;

  final weapon_behaviors = [
    FireRateOnGameKey(GameKey.fire1),
    RandomSpread(),
    PlayerRelativeSpeed(),
  ];

  final projectile_behaviors = [
    SetAngleFromVelocity(),
    RecycleOnAnimComplete(),
    MoveByVelocity(),
    RecycleOutOfBounds(),
    RecycleOnSolidHit(),
    RecycleOnTargetHit(),
  ];

  bool get active => player.active_weapon == this;

  @override
  void onMount() {
    super.onMount();
    _keys = keys;
  }

  @override
  void update(double dt) {
    if (ammo == 0 || !active) return;
    if (player.state != PlayerState.playing) return;
    super.update(dt);
    for (final it in weapon_behaviors) {
      it.update(this, dt);
    }
  }

  void on_fire(double dt, {bool sound = true, bool show_firing = true}) {
    if (ammo != -1 && --ammo == 0) sendMessage(WeaponEmpty(type));

    if (show_firing) player.show_firing = fire_rate * 2;

    temp_pos.setFrom(player.position);
    temp_pos.y -= player.height / 3;

    velocity.setFrom(player.fire_dir);
    if (velocity.isZero()) velocity.setValues(0, -1);

    for (final it in weapon_behaviors) {
      it.on_fire(this, dt);
    }

    final projectile = _recycler.acquire();
    if (projectile.behaviors.isEmpty) {
      projectile.behaviors.addAll(projectile_behaviors);
    }
    projectile.init(animation: _animation, position: temp_pos, velocity: velocity);
    entities.add(projectile);

    if (sound) soundboard.play(_sound);
  }
}

abstract class WeaponBehavior {
  void update(BaseWeapon weapon, double dt) {}

  void on_fire(BaseWeapon weapon, double dt) {}
}

class FireRateOnGameKey extends WeaponBehavior {
  FireRateOnGameKey(this.fire_key, {this.show_firing = true});

  final GameKey fire_key;
  final bool show_firing;

  double _fire_time = 0;

  @override
  void update(BaseWeapon weapon, double dt) {
    if (weapon._keys.check(fire_key)) {
      if (_fire_time <= 0) {
        _fire_time = weapon.fire_rate;
        weapon.on_fire(dt, show_firing: show_firing);
      } else {
        _fire_time -= dt;
      }
    } else {
      _fire_time -= dt;
    }
  }
}

class RandomSpread extends WeaponBehavior {
  @override
  void on_fire(BaseWeapon weapon, double dt) {
    weapon.velocity.rotate(rng.nextDoublePM(weapon.spread));
  }
}

class PlayerRelativeSpeed extends WeaponBehavior {
  PlayerRelativeSpeed({this.add_relative = true});

  bool add_relative;

  @override
  void on_fire(BaseWeapon weapon, double dt) {
    final add = (!add_relative || player.move_dir.isZero()) ? 0 : player.move_speed;
    weapon.velocity.scale(weapon.projectile_speed + add);
  }
}
