final configuration = GameConfiguration.instance;

class GameConfiguration {
  static final instance = GameConfiguration._();

  GameConfiguration._();

  final double player_move_speed = 75;
  final double player_run_speed = 125;
  final double enemy_move_speed = 60;

  late int projectile_hits_per_grenade = 10;
  late int grenade_hits_per_bazooka = 3;

  final assault_rifle_fire_rate = 0.2;
  final assault_rifle_spread = 0.0;
  final bazooka_fire_rate = 1.0;
  final bazooka_spread = 0.0;
  final flame_thrower_fire_rate = 0.03;
  final flame_thrower_spread = 0.4;
  final machine_gun_fire_rate = 0.3;
  final machine_gun_spread = 0.075;
  final shotgun_fire_rate = 0.5;
  final shotgun_spread = 0.25;
  final smg_fire_rate = 0.1;
  final smg_spread = 0.175;

  final grenades_fire_rate = 0.3;
  final grenades_spread = 0.0;
}
