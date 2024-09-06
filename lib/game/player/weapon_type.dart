import 'package:collection/collection.dart';

// name and order for guns has to match sprite sheet

enum WeaponType {
  assault_rifle(projectile_damage: 1, pickup_ammo: 0),
  bazooka(blast_damage: 3, pickup_ammo: 1),
  flame_thrower(fire_damage: 0.2, pickup_ammo: 250),
  machine_gun(projectile_damage: 2, pickup_ammo: 50),
  smg(projectile_damage: 0.8, pickup_ammo: 250),
  shotgun(projectile_damage: 0.5, pickup_ammo: 50),
  grenades(blast_damage: 1, pickup_ammo: 3),
  explosion(blast_damage: 0.3, pickup_ammo: 0),
  smoking(projectile_damage: 0.1, fire_damage: 0.1, pickup_ammo: 0),
  burning(projectile_damage: 0.2, fire_damage: 0.2, pickup_ammo: 0),
  ;

  final double? projectile_damage;
  final double? blast_damage;
  final double? fire_damage;
  final int pickup_ammo;

  const WeaponType({
    this.projectile_damage,
    this.blast_damage,
    this.fire_damage,
    required this.pickup_ammo,
  });

  static WeaponType? by_name(String name) => values.firstWhereOrNull((it) => it.name == name);
}
