import 'package:voxone/game/entities/enemy.dart';
import 'package:voxone/game/entities/enemy_behavior.dart';
import 'package:voxone/game/entities/spawn_mode.dart';
import 'package:voxone/game/level/level_object.dart';
import 'package:voxone/game/level/props/explosive.dart';
import 'package:voxone/game/level/props/flammable.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:flame/components.dart';

import 'consumable.dart';
import 'destructible.dart';

extension ComponentExtensions on Component {
  LevelProp get my_prop => parent as LevelProp;

  Map<String, dynamic> get my_properties => my_prop.properties;

  bool get is_consumable => children.any((it) => it is Consumable);

  bool get is_destructible => children.any((it) => it is Destructible);

  bool get is_explosive => children.any((it) => it is Explosive);

  bool get is_flammable => children.any((it) => it is Flammable);

  bool get is_enemy => children.any((it) => it is Enemy);
}

extension LevelObjectExtensions on LevelObject {
  bool get starts_burning => properties['burns'] == true;

  double get damage_percent => destructible.damage_percent;

  Destructible get destructible => children.whereType<Destructible>().single;

  Flammable? get flammable => children.whereType<Flammable>().singleOrNull;

  Enemy? get enemy => children.whereType<Enemy>().singleOrNull;

  Iterable<EnemyBehavior> get enemy_behaviors => children.whereType<EnemyBehavior>();

  Iterable<SpawnMode> get spawn_modes => children.whereType<SpawnMode>();

  Iterable<MovementMode> get movement_modes => children.whereType<MovementMode>();
}
